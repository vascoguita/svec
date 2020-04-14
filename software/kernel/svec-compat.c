// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Copyright (C) 2019 CERN (www.cern.ch)
 * Author: Federico Vaga <federico.vaga@cern.ch>
 */
#include <linux/kallsyms.h>
#include <linux/module.h>
#include <linux/fpga/fpga-mgr.h>
#include <linux/version.h>
#include "svec-compat.h"


#if KERNEL_VERSION(4, 10, 0) > LINUX_VERSION_CODE && !defined(CONFIG_FPGA_MGR_BACKPORT)
struct fpga_manager *__fpga_mgr_get(struct device *dev)
{
	struct fpga_manager *mgr;
	int ret = -ENODEV;

	mgr = to_fpga_manager(dev);
	if (!mgr)
		goto err_dev;

	/* Get exclusive use of fpga manager */
	if (!mutex_trylock(&mgr->ref_mutex)) {
		ret = -EBUSY;
		goto err_dev;
	}

	if (!try_module_get(dev->parent->driver->owner))
		goto err_ll_mod;

	return mgr;

err_ll_mod:
	mutex_unlock(&mgr->ref_mutex);
err_dev:
	put_device(dev);
	return ERR_PTR(ret);
}

static int fpga_mgr_dev_match(struct device *dev, const void *data)
{
	return dev->parent == data;
}

/**
 * fpga_mgr_get - get an exclusive reference to a fpga mgr
 * @dev:parent device that fpga mgr was registered with
 *
 * Given a device, get an exclusive reference to a fpga mgr.
 *
 * Return: fpga manager struct or IS_ERR() condition containing error code.
 */
struct fpga_manager *fpga_mgr_get(struct device *dev)
{
	struct class *fpga_mgr_class = (struct class *) kallsyms_lookup_name("fpga_mgr_class");
	struct device *mgr_dev;

	mgr_dev = class_find_device(fpga_mgr_class, NULL, dev,
				    fpga_mgr_dev_match);
	if (!mgr_dev)
		return ERR_PTR(-ENODEV);

	return __fpga_mgr_get(mgr_dev);
}
#endif


static int __compat_svec_fw_load(struct fpga_manager *mgr, const char *name)
{
#if KERNEL_VERSION(4, 16, 0) > LINUX_VERSION_CODE && !defined(CONFIG_FPGA_MGR_BACKPORT)
#if KERNEL_VERSION(4, 10, 0) > LINUX_VERSION_CODE
	return fpga_mgr_firmware_load(mgr, 0, name);
#else
	struct fpga_image_info image;

	memset(&image, 0, sizeof(image));
	return fpga_mgr_firmware_load(mgr, &image, name);
#endif
#else
	struct fpga_image_info image;

	memset(&image, 0, sizeof(image));
	image.firmware_name = (char *)name;
	image.dev = mgr->dev.parent;

	return fpga_mgr_load(mgr, &image);
#endif
}

int compat_svec_fw_load(struct svec_dev *svec_dev, const char *name)
{
	struct fpga_manager *mgr;
	int err;

	mgr = fpga_mgr_get(&svec_dev->dev);
	if (IS_ERR(mgr))
		return -ENODEV;

	err = fpga_mgr_lock(mgr);
	if (err)
		goto out;
	err = __compat_svec_fw_load(mgr, name);
	fpga_mgr_unlock(mgr);
out:
	fpga_mgr_put(mgr);

	return err;
}
