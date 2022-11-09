// SPDX-License-Identifier: GPL-2.0-or-later
/*
 *
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
#include <linux/fmc.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/jhash.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/vmalloc.h>
#include <linux/fpga/fpga-mgr.h>
#include <vmebus.h>

#include "svec.h"
#include "svec-compat.h"
#include "hw/xloader_regs.h"

static void svec_csr_write(u8 value, void *base, u32 offset)
{
	offset -= offset % 4;
	iowrite32be(value, base + offset);
}

/**
 * Load FPGA code
 * @svec: SVEC device
 * @name: FPGA bitstream file name
 *
 * Return: 0 on success, otherwise a negative error number
 */
static int svec_fw_load(struct svec_dev *svec_dev, const char *name)
{
	int err;

	dev_dbg(&svec_dev->dev, "Writing firmware '%s'\n", name);
	err = svec_fpga_exit(svec_dev);
	if (err) {
		dev_err(&svec_dev->dev,
			"Cannot remove FPGA device instances. Try to remove them manually and to reload this device instance\n");
		return err;
	}


	mutex_lock(&svec_dev->mtx);
	err = compat_svec_fw_load(svec_dev, name);
	mutex_unlock(&svec_dev->mtx);

	return err;
}

static ssize_t svec_fpga_firmware_store(struct device *dev,
				 struct device_attribute *attr,
				 const char *buf,
				 size_t count)
{
	struct svec_dev *svec_dev = to_svec_dev(dev);
	int err;

	err = svec_fw_load(svec_dev, buf);
	if (err)
		dev_err(&svec_dev->dev,
			"FPGA Configuration failure %d\n", err);

	/*
	 * Reprogramming the FPGA means replacing the VME slave. In other words
	 * the SVEC device that we used to re-flash the FPGA disappeard and so
	 * this driver instance must disapear as well.
	 */
	dev_warn(&svec_dev->dev, "VME Slave removed\n");
	dev_warn(&svec_dev->dev, "Remove this device driver instance\n");

	if (device_remove_file_self(&svec_dev->dev, attr)) {
		vme_unregister_device(to_vme_dev(svec_dev->dev.parent));
	}
	else {
		dev_err(&svec_dev->dev,
			"Can't remove device driver instance.\n");
	}

	return err ? err : count;
}

static DEVICE_ATTR_WO(svec_fpga_firmware);

static struct attribute *svec_sys_dev_attrs[] = {
	&dev_attr_svec_fpga_firmware.attr,
	NULL
};

ATTRIBUTE_GROUPS(svec_sys_dev);

static void seq_printf_meta(struct seq_file *s, const char *indent,
			    struct svec_meta_id *meta)
{
	seq_printf(s, "%sMetadata:\n", indent);
	seq_printf(s, "%s  - Vendor: 0x%08x\n", indent, meta->vendor);
	seq_printf(s, "%s  - Device: 0x%08x\n", indent, meta->device);
	seq_printf(s, "%s  - Version: 0x%08x\n", indent, meta->version);
	seq_printf(s, "%s  - BOM: 0x%08x\n", indent, meta->bom);
	seq_printf(s, "%s  - SourceID: 0x%08x%08x%08x%08x\n",
		   indent,
		   meta->src[0],
		   meta->src[1],
		   meta->src[2],
		   meta->src[3]);
	seq_printf(s, "%s  - CapabilityMask: 0x%08x\n", indent, meta->cap);
	seq_printf(s, "%s  - VendorUUID: 0x%08x%08x%08x%08x\n",
		   indent,
		   meta->uuid[0],
		   meta->uuid[1],
		   meta->uuid[2],
		   meta->uuid[3]);
}

static int svec_dbg_meta(struct seq_file *s, void *offset)
{
	struct svec_dev *svec_dev = s->private;

	seq_printf_meta(s, "", &svec_dev->meta);
	if (!svec_dev->svec_fpga || !svec_dev->svec_fpga->app_pdev)
		goto out;

	seq_puts(s, "Application:\n");
	seq_printf_meta(s, "  ", &svec_dev->svec_fpga->meta_app);
out:
	return 0;
}

static int svec_dbg_meta_open(struct inode *inode, struct file *file)
{
	struct svec_dev *svec = inode->i_private;

	return single_open(file, svec_dbg_meta, svec);
}

static const struct file_operations svec_dbg_meta_ops = {
	.owner = THIS_MODULE,
	.open  = svec_dbg_meta_open,
	.read = seq_read,
	.llseek = seq_lseek,
	.release = single_release,
};

static int svec_dbg_init(struct svec_dev *svec_dev)
{
	struct device *dev = &svec_dev->dev;

	svec_dev->dbg_dir = debugfs_create_dir(dev_name(dev), NULL);
	if (IS_ERR_OR_NULL(svec_dev->dbg_dir)) {
		dev_err(dev, "Cannot create debugfs directory (%ld)\n",
			PTR_ERR(svec_dev->dbg_dir));
		return PTR_ERR(svec_dev->dbg_dir);
	}

	svec_dev->dbg_meta = debugfs_create_file(SVEC_DBG_META_NAME, 0200,
						 svec_dev->dbg_dir,
						 svec_dev,
						 &svec_dbg_meta_ops);
	if (IS_ERR_OR_NULL(svec_dev->dbg_meta)) {
		dev_err(dev, "Cannot create debugfs file \"%s\" (%ld)\n",
			SVEC_DBG_META_NAME, PTR_ERR(svec_dev->dbg_meta));
		return PTR_ERR(svec_dev->dbg_meta);
	}

	return 0;
}

static void svec_dbg_exit(struct svec_dev *svec_dev)
{
	debugfs_remove_recursive(svec_dev->dbg_dir);
}


/**
 * Writes a "magic" unlock sequence, activating the System FPGA bootloader
 * regardless of what is going on in the Application FPGA. This clears
 * the Application FPGA as well by resetting the FPGA chip.
 * @svec a valid SVEC device instance
 * Return: 0 on success, otherwise a negative errno number
 */
static int svec_fpga_reset(struct fpga_manager *mgr)
{
	struct svec_dev *svec = mgr->priv;
	struct vme_dev *vdev = to_vme_dev(svec->dev.parent);
	void *loader_addr = vdev->map_cr.kernel_va + SVEC_BASE_LOADER;
	int i;

	for (i = 0; i < 8; i++) {
		iowrite32be(boot_unlock_sequence[i],
			loader_addr + XLDR_REG_BTRIGR);
		mdelay(1);
	}

	return 0;
}


/**
 * Checks if the SVEC is in bootloader mode. If true, it implies that
 * the Appliocation FPGA has no bitstream loaded.
 * @svec a valid SVEC device instance
 * Return: 1 if it is active (unlocked), 0 if it is not active (locked),
 * otherwise a negative errno number
 */
static int svec_fpga_loader_is_active(struct fpga_manager *mgr)
{
	struct svec_dev *svec = mgr->priv;
	struct vme_dev *vdev = to_vme_dev(svec->dev.parent);
	void *loader_addr = vdev->map_cr.kernel_va + SVEC_BASE_LOADER;
	char buf[5];
	uint32_t idc, csr;

	csr = ioread32be(loader_addr + XLDR_REG_CSR);
	idc = ioread32be(loader_addr + XLDR_REG_IDR);

	idc = htonl(idc);

	memset(buf, 0, 5);
	strncpy(buf, (char *)&idc, 4);
	dev_dbg(&mgr->dev, "SVEC Loader: {ID: \"%s\"(0x%08x), Version: %d (0x%08x)}",
			buf, idc, XLDR_CSR_VERSION_R(csr), csr);

	return (strncmp(buf, "SVEC", 4) == 0);
}


/**
 * It is usable only when there is a valid CR/CSR space mapped
 * @mgr FPGA manager instance
 * @word the bytes to write
 * @size the number of valid bytes in the word
 * @is_last 1 if this is the last word of a bitstream
 * Return 0 on success, otherwise a negative errno number.
 *   EAGAIN the loader FIFO was temporary full, retry
 *   EINVAL invalid size
 */
static int svec_fpga_write_word(struct fpga_manager *mgr,
				const uint32_t word, ssize_t size,
				unsigned int is_last)
{
	struct svec_dev *svec = mgr->priv;
	struct vme_dev *vdev = to_vme_dev(svec->dev.parent);
	void *loader_addr = vdev->map_cr.kernel_va + SVEC_BASE_LOADER;
	uint32_t xldr_fifo_r0;	/* Bitstream data input control register */
	uint32_t xldr_fifo_r1;	/* Bitstream data input register */
	int rv, try = 10000;

	if (size <= 0 || size >= 5)
		return -EINVAL;

	xldr_fifo_r0 = ((size - 1) & 0x3) | (is_last ? XLDR_FIFO_R0_XLAST : 0);
	xldr_fifo_r1 = htonl(word);
	do {
		rv = ioread32be(loader_addr + XLDR_REG_FIFO_CSR);
	} while (rv & XLDR_FIFO_CSR_FULL && --try >= 0);

	if (rv & XLDR_FIFO_CSR_FULL)
		return -EBUSY; /* bootloader busy */

	iowrite32be(xldr_fifo_r0, loader_addr + XLDR_REG_FIFO_R0);
	iowrite32be(xldr_fifo_r1, loader_addr + XLDR_REG_FIFO_R1);

	return 0;
}


/**
 * Start programming procedure
 * It is usable only when there is a valid CR/CSR space mapped
 * @mgr FPGA manager instance
 * Return 0 on success, otherwise a negative errno number.
 */
static int svec_fpga_write_start(struct fpga_manager *mgr)
{
	struct svec_dev *svec = mgr->priv;
	struct vme_dev *vdev = to_vme_dev(svec->dev.parent);
	void *loader_addr = vdev->map_cr.kernel_va + SVEC_BASE_LOADER;
	int err, succ;

	/* reset the FPGA */
	err = svec_fpga_reset(mgr);
	if (err) {
		dev_err(&mgr->dev, "FPGA reset failed\n");
		goto err_reset;
	}
	/* check if the FPGA loader is active */
	succ = svec_fpga_loader_is_active(mgr);
	if (!succ) {
		dev_err(&mgr->dev, "FPGA loader unavailable\n");
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
 * Stop programming procedure.
 * It is usable only when there is a valid CR/CSR space mapped
 * @mgr FPGA manager instance
 * Return 0 on success, otherwise a negative errno number
 */
static int svec_fpga_write_stop(struct fpga_manager *mgr,
				struct fpga_image_info *info)
{
	struct svec_dev *svec = mgr->priv;
	struct vme_dev *vdev = to_vme_dev(svec->dev.parent);
	void *loader_addr = vdev->map_cr.kernel_va + SVEC_BASE_LOADER;
	u64 timeout;
	int rval = 0, err;

	err = svec_fpga_write_word(mgr,
				   svec->bitstream_last_word,
				   svec->bitstream_last_word_size,
				   1);
	if (err == -EINVAL)
		err = 0;
	if (err)
		goto out;

	/* Reset the bitstream programming words */
	svec->bitstream_last_word = -1;
	svec->bitstream_last_word_size = -1;

	/* Two seconds later */
	timeout = get_jiffies_64();
	if (info->config_complete_timeout_us)
		timeout += usecs_to_jiffies(info->config_complete_timeout_us);
	else
		timeout += usecs_to_jiffies(100);
	while (time_before64(get_jiffies_64(), timeout)) {
		rval = ioread32be(loader_addr + XLDR_REG_CSR);
		if (rval & XLDR_CSR_DONE)
			break;
		usleep_range(900, 1100);

	}

	if (!(rval & XLDR_CSR_DONE)) {
		dev_err(&mgr->dev, "error: FPGA program timeout.\n");
		err = -EIO;
	}

	if (rval & XLDR_CSR_ERROR) {
		dev_err(&mgr->dev, "Bitstream loaded, status ERROR\n");
		err = -EINVAL;
	}
out:
	/* give the VME bus control to App FPGA */
	iowrite32be(XLDR_CSR_EXIT, loader_addr + XLDR_REG_CSR);

	/* give the VME core a little while to settle up */
	usleep_range(10000, 20000);

	return err;
}


/**
 * It writes the given buffer into the FPGA
 * @mgr FPGA manager instance
 * @buf data buffer to write
 * @size buffer size
 * Return the number of written bytes on success (greater or equal to zero),
 * otherwise a negative errno number
 */
static size_t svec_fpga_write_buf(struct fpga_manager *mgr,
				  const void *buf, size_t size)
{
	struct svec_dev *svec = mgr->priv;
	const uint32_t *data = buf;
	int i, err = 0;

	i = 0;
	while (i < size) {
		err = svec_fpga_write_word(mgr,
					   svec->bitstream_last_word,
					   svec->bitstream_last_word_size,
					   0);
		if (err && !(err == -EINVAL && i == 0)) {
			dev_err(&mgr->dev, "failed at word %d/%ld (%d)\n", i, size, err);
			goto out;
		}

		/*
		 * EINVAL is "fine" here because the first time we give a
		 * wrong size in order to have a working hack
		 */

		svec->bitstream_last_word = data[i >> 2];
		svec->bitstream_last_word_size = (size - i > 4 ? 4 : size - i);
		i += svec->bitstream_last_word_size;
	}

	err = 0;
out:
	return err;
}


static enum fpga_mgr_states svec_fpga_state(struct fpga_manager *mgr)
{
	return mgr->state;
}


static int svec_fpga_write_init(struct fpga_manager *mgr,
				struct fpga_image_info *info,
				const char *buf, size_t count)
{
	struct svec_dev *svec = mgr->priv;

	/* Reset the bitstream programming words */
	svec->bitstream_last_word = -1;
	svec->bitstream_last_word_size = -1;

	return svec_fpga_write_start(mgr);
}


static int svec_fpga_write(struct fpga_manager *mgr, const char *buf,
			   size_t count)
{
	return svec_fpga_write_buf(mgr, buf, count);
}


static int svec_fpga_write_complete(struct fpga_manager *mgr,
				    struct fpga_image_info *info)
{
	return svec_fpga_write_stop(mgr, info);
}


static void svec_fpga_remove(struct fpga_manager *mgr)
{
	/* do nothing */
}


static const struct fpga_manager_ops svec_fpga_ops = {
	.initial_header_size = 0,
	.state = svec_fpga_state,
	.write_init = svec_fpga_write_init,
	.write = svec_fpga_write,
	.write_complete = svec_fpga_write_complete,
	.fpga_remove = svec_fpga_remove,
};

#define SVEC_USER_CSR_INT_LEVEL 0x7FF5B
#define SVEC_USER_CSR_INT_VECTOR 0x7FF5F

static int svec_vme_init(struct svec_dev *svec)
{
	struct vme_dev *vdev = to_vme_dev(svec->dev.parent);
	int err;

	err = vme_disable_device(vdev);
	if (err)
		return err;
	/* Configure the SVEC VME interface */
	svec_csr_write(vdev->irq_vector, vdev->map_cr.kernel_va,
		       SVEC_USER_CSR_INT_VECTOR);
	svec_csr_write(vdev->irq_level, vdev->map_cr.kernel_va,
		       SVEC_USER_CSR_INT_LEVEL);

	return vme_enable_device(vdev);
}

static int svec_vme_exit(struct svec_dev *svec)
{
	struct vme_dev *vdev = to_vme_dev(svec->dev.parent);
	int err;

	err = vme_disable_device(vdev);
	if (err)
		return err;
	svec_csr_write(0x0, vdev->map_cr.kernel_va,
		       SVEC_USER_CSR_INT_VECTOR);
	return vme_enable_device(vdev);
}

static void svec_dev_release(struct device *dev)
{

}

static int svec_dev_uevent(struct device *dev, struct kobj_uevent_env *env)
{
	return 0;
}

static const struct device_type svec_type = {
	.name = "svec",
	.groups = svec_sys_dev_groups,
	.release = svec_dev_release,
	.uevent = svec_dev_uevent,
};

/**
 * It initialize a new SVEC instance
 * @pdev correspondend Linux device instance
 * @ndev (Deprecated) device number
 *
 * Return: 0 on success, otherwise a negative number correspondent to an errno
 */
static int svec_probe(struct device *dev, unsigned int ndev)
{
	struct vme_dev *vdev = to_vme_dev(dev);
	struct svec_dev *svec;
	int err;

	if (WARN(dev == NULL, "Invalid VME Device\n"))
		return -1;

	svec = kzalloc(sizeof(struct svec_dev), GFP_KERNEL);
	if (!svec) {
		err = -ENOMEM;
		goto err;
	}

	dev_set_drvdata(dev, svec);
	spin_lock_init(&svec->lock);
	mutex_init(&svec->mtx);
	svec->dev.parent = &vdev->dev;
	svec->dev.type = &svec_type;
	svec->dev.driver = vdev->dev.driver;
	err = dev_set_name(&svec->dev, "svec-%s",
			   dev_name(svec->dev.parent));
	if (err)
		goto err_name;
	err = device_register(&svec->dev);
	if (err) {
		dev_err(dev, "Failed to register '%s'\n",
			dev_name(&svec->dev));
		goto err_dev;
	}

	svec_vme_init(svec);

	svec->fpga_status = FPGA_MGR_STATE_UNKNOWN;
	svec->mgr = fpga_mgr_create(&svec->dev, dev_name(&svec->dev),
				    &svec_fpga_ops, svec);
	if (!svec->mgr) {
		err = -EPERM;
		goto err_fpga_new;
	}

	err = fpga_mgr_register(svec->mgr);
	if (err)
		goto err_fpga_reg;

	svec_dbg_init(svec);

	err = svec_fpga_init(svec, SVEC_FUNC_NR);
	if (err)
		dev_warn(&vdev->dev,
			 "FPGA incorrectly programmed or empty (%d)\n", err);

	return 0;

err_fpga_reg:
	fpga_mgr_free(svec->mgr);
err_fpga_new:
	device_unregister(&svec->dev);
err_dev:
err_name:
	dev_set_drvdata(dev, NULL);
	kfree(svec);
err:
	return err;
}

/**
 * It removes a SVEC device instance
 * @vdev Linux device pointer
 * @ndev DEPRECATED Device instance
 * Return: 0 on success, otherwise a negative errno number
 */
static int svec_remove(struct device *dev, unsigned int ndev)
{
	struct svec_dev *svec = dev_get_drvdata(dev);

	svec_fpga_exit(svec);
	svec_dbg_exit(svec);
	fpga_mgr_unregister(svec->mgr);
	fpga_mgr_free(svec->mgr);
	svec_vme_exit(svec);
	device_unregister(&svec->dev);
	kfree(svec);

	dev_set_drvdata(dev, NULL);

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
		.owner = THIS_MODULE,
		.name = "svec-fmc-carrier",
	},
	.id_table = svec_id_table,
};


static int __init svec_init(void)
{
	return vme_register_driver(&svec_driver, 0);
}

static void __exit svec_exit(void)
{
	vme_unregister_driver(&svec_driver);
}

module_init(svec_init);
module_exit(svec_exit);

MODULE_AUTHOR("Federico Vaga <federico.vaga@cern.ch>");
MODULE_LICENSE("GPL v2");
MODULE_VERSION(VERSION);
MODULE_DESCRIPTION("Driver for the 'Simple VME FMC Carrier' a.k.a. SVEC");

MODULE_SOFTDEP("pre: htvic i2c_mux i2c-ocores spi-ocores");

ADDITIONAL_VERSIONS;
