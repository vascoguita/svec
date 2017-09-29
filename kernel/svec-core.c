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

#include <linux/device.h>
#include <linux/module.h>
#include <linux/slab.h>

#include <vmebus.h>


/**
 * struct svec_dev - SVEC instance
 * @vdev VME device instance
 */
struct svec_dev {
	struct device dev;
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
	int err;

	svec = kzalloc(sizeof(struct svec_dev), GFP_KERNEL);
	if (!svec) {
		dev_err(dev, "Cannot allocate memory for svec card struct\n");
		return -ENOMEM;
	}
	dev_set_name(&svec->dev, "svec.%d", vdev->slot);
	svec->dev.parent = &vdev->dev;
	dev_set_drvdata(&vdev->dev, svec);

	err = device_register(&svec->dev);
	if (err)
		goto err_dev_reg;

	return 0;

err_dev_reg:
	kfree(svec);
	return err;
}


static int svec_remove(struct device *pdev, unsigned int ndev)
{
	struct svec_dev *svec = dev_get_drvdata(pdev);

	device_unregister(&svec->dev);
	kfree(svec);

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
	return vme_register_driver(&svec_driver, 0);
}

static void __exit svec_exit(void)
{
	vme_unregister_driver(&svec_driver);
}

module_init(svec_init);
module_exit(svec_exit);

MODULE_AUTHOR("Federico Vaga <federico.vaga@cern.ch>");
MODULE_AUTHOR("Juan David Gonzalez Cobas <dcobas@cern.ch>");
MODULE_LICENSE("GPLv2");
MODULE_VERSION(GIT_VERSION);
MODULE_DESCRIPTION("svec driver");

ADDITIONAL_VERSIONS;
