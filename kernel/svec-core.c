/*
 * SPDX-License-Identifier: GPLv2
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

#include "hw/xloader_regs.h"


#define SVEC_BASE_LOADER	0x70000


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


/**
 * struct svec_dev - SVEC instance
 * It describes a SVEC device instance.
 * @map_cr CR/CSR space mapping
 * @bitstream_last_word last data to write into the FPGA
 * @bistream_last_word_size last data size to write in the FPGA. This is a dirty
 *                          and ugly hack in order to properly handle a dirty
 *                          and ugly interface. The SVEC bootloader does not
 *                          accept emtpy transfers and neither to declare the
 *                          transmission over without sending data.
 * @fpgA_status state of the Application FPGA
 * The user must lock the spinlock `lock` when using the following variables in
 * this data structure: flags.
 */
struct svec_dev {
	char name[8];
	struct vme_mapping map_cr;

	uint32_t bitstream_last_word;
	uint32_t bitstream_last_word_size;
	enum fpga_mgr_states fpga_status;
};


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
	int i;

	for (i = 0; i < 8; i++) {
		iowrite32be(boot_unlock_sequence[i],
			    svec->map_cr.kernel_va + SVEC_BASE_LOADER + XLDR_REG_BTRIGR);
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
	void *loader_addr = svec->map_cr.kernel_va + SVEC_BASE_LOADER;
	uint32_t xldr_fifo_r0;	/* Bitstream data input control register */
	uint32_t xldr_fifo_r1;	/* Bitstream data input register */
	int rv, try = 10000;
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
 * @mgr FPGA manager instance
 * Return 0 on success, otherwise a negative errno number.
 */
static int svec_fpga_write_start(struct fpga_manager *mgr)
{
	struct svec_dev *svec = mgr->priv;
	void *loader_addr = svec->map_cr.kernel_va + SVEC_BASE_LOADER;
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
 * It starts the programming procedure.
 * It is usable only when there is a valid CR/CSR space mapped
 * @mgr FPGA manager instance
 * Return 0 on success, otherwise a negative errno number
 */
static int svec_fpga_write_stop(struct fpga_manager *mgr,
				struct fpga_image_info *info)
{
	struct svec_dev *svec = mgr->priv;
	void *loader_addr = svec->map_cr.kernel_va + SVEC_BASE_LOADER;
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
	timeout = get_jiffies_64() + usecs_to_jiffies(info->config_complete_timeout_us);
	while (time_before64(get_jiffies_64(), timeout)) {
		rval = ioread32be(loader_addr + XLDR_REG_CSR);
		if (rval & XLDR_CSR_DONE)
			break;
		msleep(1);
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
	msleep(10);

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
	int err;

	/* Reset the bitstream programming words */
	svec->bitstream_last_word = -1;
	svec->bitstream_last_word_size = -1;

	err = vme_find_mapping(&svec->map_cr, 1);
	if (err)
		return err;
	err = svec_fpga_write_start(mgr);
	if (err)
		goto err;
	return 0;

err:
	vme_release_mapping(&svec->map_cr, 1);
	return err;
}


static int svec_fpga_write(struct fpga_manager *mgr, const char *buf, size_t count)
{
	return svec_fpga_write_buf(mgr, buf, count);
}


static int svec_fpga_write_complete(struct fpga_manager *mgr,
				    struct fpga_image_info *info)
{
	struct svec_dev *svec = mgr->priv;
	int err;

	err = svec_fpga_write_stop(mgr, info);
	vme_release_mapping(&svec->map_cr, 1);

	return err;
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
		err = -ENOMEM;
		goto err;
	}

	svec->map_cr = map_tmpl_cr;
	svec->map_cr.vme_addrl = svec->map_cr.sizel * vdev->slot;

	svec->fpga_status = FPGA_MGR_STATE_UNKNOWN;

	snprintf(svec->name, 8, "svec.%d", vdev->slot);
	err = fpga_mgr_register(&vdev->dev, svec->name,
				&svec_fpga_ops, svec);
	if (err)
		goto err_fpga_reg;

	return 0;

err_fpga_reg:
	kfree(svec);
err:
	dev_err(dev, "Failed to register SVEC device\n");
	return err;
}


/**
 * It removes a SVEC device instance
 * @vdev Linux device pointer
 * @ndev DEPRECATED Device instance
 * Return: 0 on success, otherwise a negative errno number
 */
static int svec_remove(struct device *vdev, unsigned int ndev)
{
	fpga_mgr_unregister(vdev);

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
MODULE_LICENSE("GPL v2");
MODULE_VERSION(GIT_VERSION);
MODULE_DESCRIPTION("svec driver");

ADDITIONAL_VERSIONS;
