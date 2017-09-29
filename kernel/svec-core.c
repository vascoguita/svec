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

#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/slab.h>

#include <vmebus.h>


#define SVEC_MINOR_MAX (64)
static DECLARE_BITMAP(svec_minors, SVEC_MINOR_MAX);
static dev_t basedev;
static struct cdev svec_cdev;
static struct class *svec_class;


/**
 * struct svec_dev - SVEC instance
 * @vdev VME device instance
 */
struct svec_dev {
	struct device dev;
};

static inline struct svec_dev *to_svec_dev(struct device *ptr)
{
	return container_of(ptr, struct svec_dev, dev);
}

static inline int svec_minor_get(void)
{
	int minor;

	minor = find_first_zero_bit(svec_minors, SVEC_MINOR_MAX);
	set_bit(minor, svec_minors);

	return minor;
}

static inline void svec_minor_put(unsigned int minor)
{
	clear_bit(minor, svec_minors);
}

/**
 * It sets the private data and check that only one user at
 * time access this file
 */
static int svec_open(struct inode *inode, struct file *file)
{
	pr_info("%s:%d\n", __func__, __LINE__);
	return 0;
}


/**
 * It actually flash the bitstream on the FGPA
 */
static int svec_close(struct inode *inode, struct file *f)
{
	pr_info("%s:%d\n", __func__, __LINE__);
	return 0;
}


/**
 * It creates a local copy of the user buffer
 */
static ssize_t svec_write(struct file *f, const char __user *buf,
			  size_t count, loff_t *offp)
{
	pr_info("%s:%d\n", __func__, __LINE__);
	if (!count)
		return -EINVAL;

	return count;
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


static void svec_release(struct device *dev)
{
	struct svec_dev *svec = to_svec_dev(dev);

	svec_minor_put(MINOR(dev->devt));
	kfree(svec);
}


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
	int err;

	svec = kzalloc(sizeof(struct svec_dev), GFP_KERNEL);
	if (!svec) {
		return -ENOMEM;
		goto err;
	}
	dev_set_name(&svec->dev, "svec.%d", vdev->slot);
	svec->dev.class = svec_class;
	svec->dev.devt = basedev + svec_minor_get();
	svec->dev.parent = &vdev->dev;
	svec->dev.release = svec_release;
	dev_set_drvdata(&vdev->dev, svec);

	err = device_register(&svec->dev);
	if (err)
		goto err_dev_reg;

	return 0;

err_dev_reg:
	svec_minor_put(MINOR(svec->dev.devt));
	kfree(svec);
err:
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
	cdev_init(&svec_cdev, &svec_fops);
	svec_cdev.owner = THIS_MODULE;
	err = cdev_add(&svec_cdev, basedev, SVEC_MINOR_MAX);
	if (err)
		goto err_cdev_add;
	err = vme_register_driver(&svec_driver, 0);
	if (err)
		goto err_drv_reg;

	return 0;

err_drv_reg:
	cdev_del(&svec_cdev);
err_cdev_add:
	unregister_chrdev_region(basedev, SVEC_MINOR_MAX);
err_chrdev_alloc:
	class_destroy(svec_class);
err_cls:
	return err;
}

static void __exit svec_exit(void)
{
	vme_unregister_driver(&svec_driver);
	cdev_del(&svec_cdev);
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
