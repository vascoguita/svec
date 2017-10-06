/*
* Copyright (C) 2017 CERN (www.cern.ch)
* Author: Federico Vaga <federico.vaga@cern.ch>
*
* Based on the SVEC version of:
* Author: Juan David Gonzalez Cobas <dcobas@cern.ch>
* Author: Luis Fernando Ruiz Gago <lfruiz@cern.ch>
* Author: Tomasz Wlostowski <tomasz.wlostowski@cern.ch>
*
* Released according to the GNU GPL, version 2 or any later version
*
* Driver for SVEC (Simple VME FMC carrier) board.
*/

#include <linux/bitmap.h>
#include <linux/cdev.h>
#include <linux/delay.h>
#include <linux/device.h>
#include <linux/firmware.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/jhash.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/vmalloc.h>

#include <vmebus.h>

#include "hw/xloader_regs.h"


#define SVEC_MINOR_MAX (64)
#define SVEC_BASE_LOADER	0x70000


static DECLARE_BITMAP(svec_minors, SVEC_MINOR_MAX);
static dev_t basedev;
static struct class *svec_class;

/**
 * Mapping template for CR/CSR space
 */
static const struct vme_mapping map_tmpl_cr = {
	.vme_addru = 0,
	.vme_addrl = 0,
	.am = VME_CR_CSR,
	.data_width = VME_D32,
	.sizeu = 0,
	.sizel = 0x80000,
};


/**
 * Byte sequence to unlock and clear the Application FPGA
 */
static const uint32_t boot_unlock_sequence[8] = {
	0xde, 0xad, 0xbe, 0xef, 0xca, 0xfe, 0xba, 0xbe
};


#define SVEC_FLAG_BITS (8)
#define SVEC_FLAG_LOCK BIT(0)


/**
 * struct svec_dev - SVEC instance
 * It describes a SVEC device instance.
 * @cdev Char device descriptor
 * @dev Linux device instance descriptor
 * @mtx mutex to protect the FPGA programmation
 * @flags collection of bit flags
 * @map_cr CR/CSR space mapping
 * @bitstream_buf_tmp temporary buffer for the copy_from_user
 * @bitstream_buf_tmp_size temporary buffer size
 * @bitstream_last_word last data to write into the FPGA
 * @bistream_last_word_size last data size to write in the FPGA. This is a dirty
 *                          and ugly hack in order to properly handle a dirty
 *                          and ugly interface. The SVEC bootloader does not
 *                          accept emtpy transfers and neither to declare the
 *                          transmission over without sending data.
 * @prog_err FPGA programming error
 *
 * The user must lock the mutex `mtx` when using the following variables in
 * this data structure: map_cr, bitstream_buf_tmp, bitstream_buf_tmp_size,
 * bitstream_last_word, bitstream_last_word_size, prog_err.
 * When the mutex `mtx` is unlocked, then these variables should not be used.
 *
 * The user must lock the spinlock `lock` when using the following variables in
 * this data structure: flags.
 */
struct svec_dev {
	struct cdev cdev;
	struct device dev;
	struct mutex mtx;
	struct spinlock lock;

	/* START lock area */
	DECLARE_BITMAP(flags, SVEC_FLAG_BITS);
	/* END lock area*/

	/* START mtx area */
	struct vme_mapping map_cr;

	void *bitstream_buf_tmp;
	size_t bitstream_buf_tmp_size;
	uint32_t bitstream_last_word;
	uint32_t bitstream_last_word_size;
	int prog_err;
	/* END mtx area */
};


/**
 * It gets a SVEC device instance
 * @ptr pointer to a Linux device instance
 * Return: the SVEC device instance correponding to the given Linux device
 */
static inline struct svec_dev *to_svec_dev(struct device *ptr)
{
	return container_of(ptr, struct svec_dev, dev);
}


/**
 * It gets a minor number
 * Return: the first minor number available
 */
static inline int svec_minor_get(void)
{
	int minor;

	minor = find_first_zero_bit(svec_minors, SVEC_MINOR_MAX);
	set_bit(minor, svec_minors);

	return minor;
}

/**
 * It releases a minor number
 * @minor minor number to release
 */
static inline void svec_minor_put(unsigned int minor)
{
	clear_bit(minor, svec_minors);
}


/**
 * Writes a "magic" unlock sequence, activating the System FPGA bootloader
 * regardless of what is going on in the Application FPGA. This clears
 * the Application FPGA as well by resetting the FPGA chip.
 * @svec a valid SVEC device instance
 * Return: 0 on success, otherwise a negative errno number
 */
static int svec_fpga_reset(struct svec_dev *svec)
{
	int i;

	for (i = 0; i < 8; i++)
		iowrite32be(boot_unlock_sequence[i],
			    svec->map_cr.kernel_va + SVEC_BASE_LOADER + XLDR_REG_BTRIGR);

	return 0;
}


/**
 * Checks if the SVEC is in bootloader mode. If true, it implies that
 * the Appliocation FPGA has no bitstream loaded.
 * @svec a valid SVEC device instance
 * Return: 1 if it is active (unlocked), 0 if it is not active (locked),
 * otherwise a negative errno number
 */
static int svec_fpga_loader_is_active(struct svec_dev *svec)
{
	char buf[5];
	uint32_t idc;


	idc = ioread32be(svec->map_cr.kernel_va + SVEC_BASE_LOADER + XLDR_REG_IDR);
	idc = htonl(idc);

	memset(buf, 0, 5);
	strncpy(buf, (char *)&idc, 4);

	return (strncmp(buf, "SVEC", 4) == 0);
}


/**
 * It is usable only when there is a valid CR/CSR space mapped
 * @svec svec device instance
 * @word the bytes to write
 * @size the number of valid bytes in the word
 * @is_last 1 if this is the last word of a bitstream
 * Return 0 on success, otherwise a negative errno number.
 *   EAGAIN the loader FIFO was temporary full, retry
 *   EINVAL invalid size
 */
static int svec_fpga_write_word(struct svec_dev *svec,
				const uint32_t word, ssize_t size,
				unsigned int is_last)
{
	void *loader_addr = svec->map_cr.kernel_va + SVEC_BASE_LOADER;
	uint32_t xldr_fifo_r0;	/* Bitstream data input control register */
	uint32_t xldr_fifo_r1;	/* Bitstream data input register */
	int rv, try = 100;
	static int cnt = 0;

	if (size <= 0 || size >= 5) {
		return -EINVAL;
	}

	xldr_fifo_r0 = ((size - 1) & 0x3) | (is_last ? XLDR_FIFO_R0_XLAST : 0);
	xldr_fifo_r1 = htonl(word);
	do {
		rv = ioread32be(loader_addr + XLDR_REG_FIFO_CSR);
	} while (rv & XLDR_FIFO_CSR_FULL && --try >= 0);

	if(rv & XLDR_FIFO_CSR_FULL)
		return -EBUSY; /* bootloader busy */

	iowrite32be(xldr_fifo_r0, loader_addr + XLDR_REG_FIFO_R0);
	iowrite32be(xldr_fifo_r1, loader_addr + XLDR_REG_FIFO_R1);

	cnt++;

	return 0;
}


/**
 * It starts the programming procedure
 * It is usable only when there is a valid CR/CSR space mapped
 * @svec svec device instance
 */
static int svec_fpga_write_start(struct svec_dev *svec)
{
	void *loader_addr = svec->map_cr.kernel_va + SVEC_BASE_LOADER;
	int err, succ;

	/* reset the FPGA */
	err = svec_fpga_reset(svec);
	if (err) {
		dev_err(&svec->dev, "FPGA reset failed\n");
		goto err_reset;
	}
	/* check if the FPGA loader is active */
	succ = svec_fpga_loader_is_active(svec);
	if (!succ) {
		dev_err(&svec->dev, "FPGA loader unavailable\n");
		err = -ENXIO;
		goto err_active;
	}

	/* Reset the Xilinx Passive Serial boot interface */
	iowrite32be(XLDR_CSR_SWRST,
		    loader_addr + XLDR_REG_CSR);
	/* Start configuration process by providing BigEndian data */
	iowrite32be(XLDR_CSR_START | XLDR_CSR_MSBF,
		    loader_addr + XLDR_REG_CSR);

err_active:
err_reset:
	return err;
}


/**
 * It starts the programming procedure.
 * It is usable only when there is a valid CR/CSR space mapped
 * @svec svec device instance
 * Return 0 on success, otherwise a negative errno number
 */
static int svec_fpga_write_stop(struct svec_dev *svec)
{
	void *loader_addr = svec->map_cr.kernel_va + SVEC_BASE_LOADER;
	u64 timeout;
	int rval = 0;

	/* Write the last bytes (HACK) */
	if(svec->prog_err == 0) {
		svec->prog_err = svec_fpga_write_word(svec,
						      svec->bitstream_last_word,
						      svec->bitstream_last_word_size,
						      1);
		if(svec->prog_err == -EINVAL)
			svec->prog_err = 0;
	}

	/* Reset the bitstream programming words */
	svec->bitstream_last_word = -1;
	svec->bitstream_last_word_size = -1;

	/* Two seconds later */
	timeout = get_jiffies_64() + 2 * HZ;
	while (time_before64(get_jiffies_64(), timeout)) {
		rval = ioread32be(loader_addr + XLDR_REG_CSR);
		if (rval & XLDR_CSR_DONE)
			break;
		msleep(1);
	}

	if (!(rval & XLDR_CSR_DONE)) {
		dev_err(&svec->dev, "error: FPGA program timeout.\n");
		return -EIO;
	}

	if (rval & XLDR_CSR_ERROR) {
		dev_err(&svec->dev, "Bitstream loaded, status ERROR\n");
		return -EINVAL;
	}

	/* give the VME bus control to App FPGA */
	iowrite32be(XLDR_CSR_EXIT, loader_addr + XLDR_REG_CSR);
	if (svec->prog_err)
		dev_err(&svec->dev, "FPGA programming failed (%d)\n", svec->prog_err);

	/* give the VME core a little while to settle up */
	msleep(10);

	return svec->prog_err;
}


/**
 * It writes the given buffer into the FPGA
 * @svec svec device instance
 * @buf data buffer to write
 * @size buffer size
 * Return the number of written bytes on success (greater or equal to zero),
 * otherwise a negative errno number
 */
static size_t svec_fpga_write_buf(struct svec_dev *svec,
				  const void *buf, size_t size)
{
	const uint32_t *data = buf;
	int i, err = 0;

	i = 0;
	while (i < size) {
		err = svec_fpga_write_word(svec,
					   svec->bitstream_last_word,
					   svec->bitstream_last_word_size,
					   0);
		if (err && !(err == -EINVAL && i == 0))
			goto out;

		/*
		 * EINVAL is "fine" here because the first time we give a
		 * wrong size in order to have a working hack
		 */

		svec->bitstream_last_word = data[i >> 2];
		svec->bitstream_last_word_size = (size - i > 4 ? 4 : size - i);
		i += svec->bitstream_last_word_size;
	}

out:
	return err ? err : size;
}


/**
 * It prepares the FPGA to receive a new bitstream.
 * @inode file system node
 * @file char device file open instance
 *
 * By just opening this device you mya reset the FPGA
 * (unless other errors prevent the user from programming).
 * Only one user at time can access the programming procedure.
 * Return: 0 on success, otherwise a negative errno number
 */
static int svec_open(struct inode *inode, struct file *file)
{
	struct svec_dev *svec = container_of(inode->i_cdev,
					     struct svec_dev,
					     cdev);
	int err, succ;

	if (test_bit(SVEC_FLAG_LOCK, svec->flags)) {
		dev_info(&svec->dev, "Application FPGA programming blocked\n");
		return -EPERM;
	}

	succ = mutex_trylock(&svec->mtx);
	if (!succ)
		return -EBUSY;

	err = try_module_get(file->f_op->owner);
	if (err == 0)
		goto err_mod_get;

	file->private_data = svec;

	svec->prog_err = 0;
	/* Reset the bitstream programming words */
	svec->bitstream_last_word = -1;
	svec->bitstream_last_word_size = -1;
	/* Allocate 1MiB */
	svec->bitstream_buf_tmp_size = 1024* 1024;
	svec->bitstream_buf_tmp = kmalloc(svec->bitstream_buf_tmp_size,
					  GFP_KERNEL);
	if (!svec->bitstream_buf_tmp) {
		err = -ENOMEM;
		goto out_buf;
	}
	err = vme_find_mapping(&svec->map_cr, 1);
	if (err)
		goto err_map;

	err = svec_fpga_write_start(svec);
	if (err)
		goto err_start;

	return 0;

err_start:
	vme_release_mapping(&svec->map_cr, 1);
err_map:
	kfree(svec->bitstream_buf_tmp);
out_buf:
	module_put(file->f_op->owner);
err_mod_get:
	mutex_unlock(&svec->mtx);
	return err;
}


/**
 * It finishes the FPGA programming procedure and let the Application FPGA run
 * In order to have a consistent system, after programming the driver will
 * destroy the instance that asked for FPGA reprogramming
 * @inode file system node
 * @file char device file open instance
 */
static int svec_close(struct inode *inode, struct file *file)
{
	struct svec_dev *svec = file->private_data;
	int err = 0;

	err = svec_fpga_write_stop(svec);
	vme_release_mapping(&svec->map_cr, 1);
	kfree(svec->bitstream_buf_tmp);

	spin_lock(&svec->lock);
	set_bit(SVEC_FLAG_LOCK, svec->flags);
	spin_unlock(&svec->lock);

	module_put(file->f_op->owner);
	mutex_unlock(&svec->mtx);


	dev_info(&svec->dev,
		 "a new application FPGA has been programmed\n");

	/* There are no more user check if we can safely remove the device  */

	/* TODO do some checks */

	/* I'm not 100% sure of this*/
	device_unregister(svec->dev.parent);
	dev_info(&svec->dev,
		 "a new application FPGA has been programmed\n");
	dev_info(&svec->dev,
		 "self-destroying this Linux device driver instance\n");

	return err;
}


/**
 * It creates a local copy of the user buffer and it start
 * to program the FPGA with it
 * @file char device file open instance
 * @buf user space buffer
 * @count user space buffer size
 * @offp offset where to copy the buffer (ignored here)
 * Return: number of byte actually copied
 */
static ssize_t svec_write(struct file *file, const char __user *buf,
			  size_t count, loff_t *offp)
{
	struct svec_dev *svec = file->private_data;
	int err;

	if (!count)
		return -EINVAL;
	if (count > svec->bitstream_buf_tmp_size)
		count = svec->bitstream_buf_tmp_size;

	err = copy_from_user(svec->bitstream_buf_tmp, buf, count);
	if (err)
		return err;

	err = svec_fpga_write_buf(svec, svec->bitstream_buf_tmp, count);
	svec->prog_err = err < 0 ? err : 0;
	return err ? err : count;
}


/**
 * Char device operation to provide bitstream
 */
static const struct file_operations svec_fops = {
	.owner = THIS_MODULE,
	.open = svec_open,
	.release = svec_close,
	.write  = svec_write,
};


/**
 * It releases device resources (`device->release()`)
 * @dev Linux device instance
 */
static void svec_release(struct device *dev)
{
	struct svec_dev *svec = to_svec_dev(dev);
	int minor = MINOR(dev->devt);

	cdev_del(&svec->cdev);
	kfree(svec);
	svec_minor_put(minor);
}

static ssize_t svec_afpga_lock_show(struct device *dev,
				    struct device_attribute *attr,
				    char *buf)
{
	struct svec_dev *svec = to_svec_dev(dev);

	return snprintf(buf, PAGE_SIZE, "%s\n",
			test_bit(SVEC_FLAG_LOCK, svec->flags) ?
			"locked" : "unlocked");
}

static ssize_t svec_afpga_lock_store(struct device *dev,
				     struct device_attribute *attr,
				     const char *buf, size_t count)
{
	struct svec_dev *svec = to_svec_dev(dev);

	if (strncmp(buf, "unlock" , min(6, count)) != 0)
		return -EINVAL;

	spin_lock(&svec->lock);
	clear_bit(SVEC_FLAG_LOCK, svec->flags);
	spin_unlock(&svec->lock);

	return count;
}
static DEVICE_ATTR(lock, 0644, svec_afpga_lock_show, svec_afpga_lock_store);

static struct attribute *svec_dev_attrs[] = {
	&dev_attr_lock.attr,
	NULL,
};
static const struct attribute_group svec_dev_group = {
	.name = "AFPGA",
	.attrs = svec_dev_attrs,
};

static const struct attribute_group *svec_dev_groups[] = {
	&svec_dev_group,
	NULL,
};

/**
 * It initialize a new SVEC instance
 * @pdev correspondend Linux device instance
 * @ndev (Deprecated) device number
 * Return: 0 on success, otherwise a negative number correspondent to an errno
 */
static int svec_probe(struct device *dev, unsigned int ndev)
{
	struct vme_dev *vdev = to_vme_dev(dev);
	struct svec_dev *svec;
	int err, minor;

	minor = svec_minor_get();
	if (minor >= SVEC_MINOR_MAX)
		return -EINVAL;

	svec = kzalloc(sizeof(struct svec_dev), GFP_KERNEL);
	if (!svec) {
		return -ENOMEM;
		goto err;
	}
	dev_set_name(&svec->dev, "svec.%d", vdev->slot);
	svec->dev.class = svec_class;
	svec->dev.devt = basedev + minor;
	svec->dev.parent = &vdev->dev;
	svec->dev.release = svec_release;
	svec->dev.groups = svec_dev_groups;
	dev_set_drvdata(&svec->dev, svec);
	dev_set_drvdata(&vdev->dev, svec);

	svec->map_cr = map_tmpl_cr;
	svec->map_cr.vme_addrl = svec->map_cr.sizel * vdev->slot;

	spin_lock_init(&svec->lock);
	mutex_init(&svec->mtx);

	spin_lock(&svec->lock);
	set_bit(SVEC_FLAG_LOCK, svec->flags);
	spin_unlock(&svec->lock);

	cdev_init(&svec->cdev, &svec_fops);
	svec->cdev.owner = THIS_MODULE;
	err = cdev_add(&svec->cdev, svec->dev.devt, 1);
	if (err)
		goto err_cdev;


	err = device_register(&svec->dev);
	if (err)
		goto err_dev_reg;

	return 0;

err_dev_reg:
	cdev_del(&svec->cdev);
err_cdev:
	kfree(svec);
err:
	svec_minor_put(MINOR(svec->dev.devt));
	dev_err(dev, "Failed to register SVEC device\n");
	return err;
}


static int svec_remove(struct device *pdev, unsigned int ndev)
{
	struct svec_dev *svec = dev_get_drvdata(pdev);

	device_unregister(&svec->dev);

	return 0;
}


/**
 * List of supported SVEC instances.
 * Note that the CR space is part of the FPGA, so different FPGAs may have
 * different IDs but they can be SVEC compatible. For example, and FMC-TDC
 * bitstream for SVEC it is compatible even if it is a bitstream that drivers
 * the FMC mezzanines as well.
 * For the time being this case is not considered.
 */
static const struct vme_device_id svec_id_table[] = {
	{"fmc-svec-a24", 0x00080030, 0x00000198, 0x00000001},
	{"fmc-svec-a32", 0x00080030, 0x00000198, 0x00000001},
	{"\0", 0, 0, 0},
};


static struct vme_driver svec_driver = {
	.probe = svec_probe,
	.remove = svec_remove,
	.driver = {
		.name = KBUILD_MODNAME,
	},
	.id_table = svec_id_table,
};


static int __init svec_init(void)
{
	int err = 0;

	svec_class = class_create(THIS_MODULE, "svec");
	if (IS_ERR_OR_NULL(svec_class)) {
		err = PTR_ERR(svec_class);
		goto err_cls;
	}

	/* Allocate a char device region for devices, CPUs and slots */
	err = alloc_chrdev_region(&basedev, 0, SVEC_MINOR_MAX, "svec");
	if (err)
		goto err_chrdev_alloc;
	err = vme_register_driver(&svec_driver, 0);
	if (err)
		goto err_drv_reg;

	return 0;

err_drv_reg:
	unregister_chrdev_region(basedev, SVEC_MINOR_MAX);
err_chrdev_alloc:
	class_destroy(svec_class);
err_cls:
	return err;
}

static void __exit svec_exit(void)
{
	vme_unregister_driver(&svec_driver);
	unregister_chrdev_region(basedev, SVEC_MINOR_MAX);
	class_destroy(svec_class);
}

module_init(svec_init);
module_exit(svec_exit);

MODULE_AUTHOR("Federico Vaga <federico.vaga@cern.ch>");
MODULE_AUTHOR("Juan David Gonzalez Cobas <dcobas@cern.ch>");
MODULE_LICENSE("GPL v2");
MODULE_VERSION(GIT_VERSION);
MODULE_DESCRIPTION("svec driver");

ADDITIONAL_VERSIONS;
