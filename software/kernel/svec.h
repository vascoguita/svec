/* SPDX-License-Identifier: GPL-2.0-or-later */
/*
 * Copyright (C) 2019 CERN (www.cern.ch)
 * Author: Federico Vaga <federico.vaga@cern.ch>
 */
#ifndef __SVEC_H__
#define __SVEC_H__
#include <linux/bitmap.h>
#include <linux/debugfs.h>
#include <linux/platform_device.h>
#include <linux/fmc.h>
#include <linux/spinlock.h>
#include <vmebus.h>
#include <uapi/linux/svec.h>

#include "svec-core-fpga.h"

#define SVEC_BASE_LOADER	0x70000

/* On FPGA components */
#define SVEC_GOLDEN_ADDR	0x10000
#define SVEC_I2C_SIZE		32
#define SVEC_I2C_ADDR_START	0x14000
#define SVEC_I2C_ADDR_END	((SVEC_I2C_ADDR_START + SVEC_I2C_SIZE) - 1)

/**
 * Byte sequence to unlock and clear the Application FPGA
 */
static const uint32_t boot_unlock_sequence[8] = {
	0xde, 0xad, 0xbe, 0xef, 0xca, 0xfe, 0xba, 0xbe
};

enum svec_dev_flags {
	SVEC_DEV_F_APP = BIT(0),
};

enum {
	/* Metadata */
	FPGA_META_VENDOR = 0x00,
	FPGA_META_DEVICE = 0x04,
	FPGA_META_VERSION = 0x08,
	FPGA_META_BOM = 0x0C,
	FPGA_META_SRC = 0x10,
	FPGA_META_CAP = 0x20,
	FPGA_META_UUID = 0x30,

};

enum {
	/* Metadata */
	SVEC_META_BASE = SVEC_BASE_REGS_METADATA,
	SVEC_META_VENDOR = SVEC_META_BASE + FPGA_META_VENDOR,
	SVEC_META_DEVICE = SVEC_META_BASE + FPGA_META_DEVICE,
	SVEC_META_VERSION = SVEC_META_BASE + FPGA_META_VERSION,
	SVEC_META_BOM = SVEC_META_BASE + FPGA_META_BOM,
	SVEC_META_SRC = SVEC_META_BASE + FPGA_META_SRC,
	SVEC_META_CAP = SVEC_META_BASE + FPGA_META_CAP,
	SVEC_META_UUID = SVEC_META_BASE + FPGA_META_UUID,
};

struct svec_fpga {
	struct device dev;
	struct svec_meta_id meta_app;
	unsigned int function_nr;
	void __iomem *fpga;
	struct platform_device *vic_pdev;
	struct platform_device *app_pdev;
	struct fmc_slot_info slot_info[SVEC_FMC_SLOTS];
	struct dentry *dbg_dir;
#define SVEC_DBG_CSR_NAME "csr_regs"
	struct dentry *dbg_csr;
	struct debugfs_regset32 dbg_csr_reg;
#define SVEC_DBG_BLD_INFO_NAME "build_info"
	struct dentry *dbg_bld_info;
};

static inline struct svec_fpga *to_svec_fpga(struct device *_dev)
{
	return container_of(_dev, struct svec_fpga, dev);
}


/**
 * struct svec_dev - SVEC instance
 * It describes a SVEC device instance.
 * @vdev VME device instance
 * @flags: flags
 * @mgr FPGA manager instance
 * @bitstream_last_word last data to write into the FPGA
 * @bistream_last_word_size last data size to write in the FPGA. This is a dirty
 *                          and ugly hack in order to properly handle a dirty
 *                          and ugly interface. The SVEC bootloader does not
 *                          accept emtpy transfers and neither to declare the
 *                          transmission over without sending data.
 * @fpga_status state of the Application FPGA
 * @i2c_adapter the I2C adapter to access the FMC EEPROMs
 * The user must lock the spinlock `lock` when using the following variables in
 * this data structure: flags.
 * @mem: ioremapped memory
 */
struct svec_dev {
	struct device dev;
	char name[8];
	unsigned long flags;
	struct svec_meta_id meta;
	struct mutex mtx;
	spinlock_t lock;
	struct fpga_manager *mgr;

	uint32_t bitstream_last_word;
	uint32_t bitstream_last_word_size;
	enum fpga_mgr_states fpga_status;
	struct platform_device *i2c_pdev;
	struct i2c_adapter *i2c_adapter;
	struct fmc_slot_info slot_info[SVEC_FMC_SLOTS];
	void *mem;

	struct dentry *dbg_dir;
#define SVEC_DBG_FW_NAME "fpga_firmware"
#define SVEC_DBG_META_NAME "fpga_device_metadata"
	struct dentry *dbg_meta;
	struct svec_fpga *svec_fpga;
};

#define SVEC_VERSION_DRV SVEC_VERSION_BLD
#define SVEC_VERSION_MAJ(_VER) ((_VER >> 24) & 0xFF)
#define SVEC_VERSION_MIN(_VER) ((_VER >> 16) & 0xFF)
#define SVEC_VERSION_PATCH(_VER) (_VER & 0xFFFF)

static inline struct svec_dev *to_svec_dev(struct device *_dev)
{
	return container_of(_dev, struct svec_dev, dev);
}

extern int svec_fpga_init(struct svec_dev *svec_dev, unsigned int function_nr);
extern int svec_fpga_exit(struct svec_dev *svec_dev);
#endif /* __SVEC_H__ */
