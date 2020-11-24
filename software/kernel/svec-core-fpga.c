// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * Copyright (C) 2019 CERN (www.cern.ch)
 * Author: Federico Vaga <federico.vaga@cern.ch>
 */
#include <linux/slab.h>
#include <linux/debugfs.h>
#include <linux/mfd/core.h>
#include <linux/fpga/fpga-mgr.h>
#include <linux/types.h>
#include <linux/platform_data/i2c-ocores.h>
#include <linux/platform_data/spi-ocores.h>
#include <linux/spi/spi.h>
#include <linux/spi/flash.h>
#include <linux/delay.h>
#include <linux/sizes.h>
#include <linux/mtd/partitions.h>
#include "svec.h"
#include "svec-core-fpga.h"

enum svec_fpga_irq_lines {
	SVEC_FPGA_IRQ_FMC_I2C = 0,
	SVEC_FPGA_IRQ_SPI,
};

enum svec_fpga_csr_offsets {
	SVEC_FPGA_CSR_APP_OFF = SVEC_BASE_REGS_CSR + 0x00,
	SVEC_FPGA_CSR_RESETS = SVEC_BASE_REGS_CSR + 0x04,
	SVEC_FPGA_CSR_FMC_PRESENT = SVEC_BASE_REGS_CSR + 0x08,
	SVEC_FPGA_CSR_UNUSED = SVEC_BASE_REGS_CSR + 0x0C,
	SVEC_FPGA_CSR_DDR_STATUS = SVEC_BASE_REGS_CSR + 0x10,
	SVEC_FPGA_CSR_PCB_REV = SVEC_BASE_REGS_CSR + 0x14,
	SVEC_FPGA_CSR_DDR4_ADDR = SVEC_BASE_REGS_CSR + 0x18,
	SVEC_FPGA_CSR_DDR4_DATA = SVEC_BASE_REGS_CSR + 0x1C,
	SVEC_FPGA_CSR_DDR5_ADDR = SVEC_BASE_REGS_CSR + 0x20,
	SVEC_FPGA_CSR_DDR5_DATA = SVEC_BASE_REGS_CSR + 0x24,
};

enum svec_fpga_therm_offsets {
	SVEC_FPGA_THERM_SERID_MSB = SVEC_BASE_REGS_THERM_ID + 0x0,
	SVEC_FPGA_THERM_SERID_LSB = SVEC_BASE_REGS_THERM_ID + 0x4,
	SVEC_FPGA_THERM_TEMP = SVEC_BASE_REGS_THERM_ID + 0x8,
};

enum svec_fpga_meta_cap_mask {
	SVEC_META_CAP_VIC = BIT(0),
	SVEC_META_CAP_THERM = BIT(1),
	SVEC_META_CAP_SPI = BIT(2),
	SVEC_META_CAP_WR = BIT(3),
	SVEC_META_CAP_BLD = BIT(4),
};

static void svec_fpga_metadata_get(struct svec_meta_id *meta,
				   void __iomem *fpga)
{
	uint32_t *meta_tmp = (uint32_t *)meta;
	int i;

	for (i = 0; i < sizeof(*meta) / 4; ++i)
		meta_tmp[i] = ioread32be(fpga + (i * 4));
}

static const struct debugfs_reg32 svec_fpga_debugfs_reg32[] = {
	{
		.name = "Application offset",
		.offset = SVEC_FPGA_CSR_APP_OFF,
	},
	{
		.name = "Resets",
		.offset = SVEC_FPGA_CSR_RESETS,
	},
	{
		.name = "FMC present",
		.offset = SVEC_FPGA_CSR_FMC_PRESENT,
	},
	{
		.name = "PCB revision",
		.offset = SVEC_FPGA_CSR_PCB_REV,
	},
	{
		.name = "DDR4 ADDR",
		.offset = SVEC_FPGA_CSR_DDR4_ADDR,
	},
	{
		.name = "DDR4 DATA",
		.offset = SVEC_FPGA_CSR_DDR4_DATA,
	},
	{
		.name = "DDR5 ADDR",
		.offset = SVEC_FPGA_CSR_DDR5_ADDR,
	},
	{
		.name = "DDR5 DATA",
		.offset = SVEC_FPGA_CSR_DDR5_DATA,
	},
};

static int svec_fpga_dbg_bld_info(struct seq_file *s, void *offset)
{
	struct svec_fpga *svec_fpga = s->private;
	struct svec_dev *svec_dev = to_svec_dev(svec_fpga->dev.parent);
	int off;

	if (!(svec_dev->meta.cap & SVEC_META_CAP_BLD)) {
		seq_puts(s, "not available\n");
		return 0;
	}

	for (off = SVEC_BASE_REGS_BUILDINFO;
	     off < SVEC_BASE_REGS_BUILDINFO + SVEC_BASE_REGS_BUILDINFO_SIZE - 1;
	     off += 4) {
		uint32_t tmp = ioread32be(svec_fpga->fpga + off);
		int k;

		for (k = 0; k < 4; ++k) {
			char c = ((char *)&tmp)[k];

			if (!c)
				return 0;
			seq_putc(s, c);
		}
	}

	return 0;
}

static int svec_fpga_dbg_bld_info_open(struct inode *inode,
					 struct file *file)
{
	struct svec_fpga *svec = inode->i_private;

	return single_open(file, svec_fpga_dbg_bld_info, svec);
}

static const struct file_operations svec_fpga_dbg_bld_info_ops = {
	.owner = THIS_MODULE,
	.open  = svec_fpga_dbg_bld_info_open,
	.read = seq_read,
	.llseek = seq_lseek,
	.release = single_release,
};

static int svec_fpga_dbg_init(struct svec_fpga *svec_fpga)
{
	struct svec_dev *svec_dev = to_svec_dev(svec_fpga->dev.parent);
	int err;

	svec_fpga->dbg_dir = debugfs_create_dir(dev_name(&svec_fpga->dev),
						svec_dev->dbg_dir);
	if (IS_ERR_OR_NULL(svec_fpga->dbg_dir)) {
		err = PTR_ERR(svec_fpga->dbg_dir);
		dev_err(&svec_fpga->dev,
			"Cannot create debugfs directory \"%s\" (%d)\n",
			dev_name(&svec_fpga->dev), err);
		return err;
	}

	svec_fpga->dbg_csr_reg.regs = svec_fpga_debugfs_reg32;
	svec_fpga->dbg_csr_reg.nregs = ARRAY_SIZE(svec_fpga_debugfs_reg32);
	svec_fpga->dbg_csr_reg.base = svec_fpga->fpga;
	svec_fpga->dbg_csr = debugfs_create_regset32(SVEC_DBG_CSR_NAME, 0200,
						svec_fpga->dbg_dir,
						&svec_fpga->dbg_csr_reg);
	if (IS_ERR_OR_NULL(svec_fpga->dbg_csr)) {
		err = PTR_ERR(svec_fpga->dbg_csr);
		dev_warn(&svec_fpga->dev,
			"Cannot create debugfs file \"%s\" (%d)\n",
			SVEC_DBG_CSR_NAME, err);
		goto err;
	}

	svec_fpga->dbg_bld_info = debugfs_create_file(SVEC_DBG_BLD_INFO_NAME,
						      0444,
						      svec_fpga->dbg_dir,
						      svec_fpga,
						      &svec_fpga_dbg_bld_info_ops);
	if (IS_ERR_OR_NULL(svec_fpga->dbg_bld_info)) {
		err = PTR_ERR(svec_fpga->dbg_bld_info);
		dev_err(&svec_fpga->dev,
			"Cannot create debugfs file \"%s\" (%d)\n",
			SVEC_DBG_BLD_INFO_NAME, err);
		goto err;
	}

	return 0;
err:
	debugfs_remove_recursive(svec_fpga->dbg_dir);
	return err;
}

static void svec_fpga_dbg_exit(struct svec_fpga *svec_fpga)
{
	debugfs_remove_recursive(svec_fpga->dbg_dir);
}

static inline uint32_t svec_fpga_csr_app_offset(struct svec_fpga *svec_fpga)
{
	return ioread32be(svec_fpga->fpga + SVEC_FPGA_CSR_APP_OFF);
}

static inline uint32_t svec_fpga_csr_pcb_rev(struct svec_fpga *svec_fpga)
{
	return ioread32be(svec_fpga->fpga + SVEC_FPGA_CSR_PCB_REV);
}

/* Vector Interrupt Controller */
static struct resource svec_fpga_vic_res[] = {
	{
		.name = "htvic-mem",
		.flags = IORESOURCE_MEM,
		.start = SVEC_BASE_REGS_VIC,
		.end = SVEC_BASE_REGS_VIC,
	}, {
		.name = "htvic-irq",
		.flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHLEVEL,
		.start = 0,
		.end = 0,
	},
};

struct irq_domain *svec_fpga_irq_find_host(struct device *dev)
{
#if LINUX_VERSION_CODE >= KERNEL_VERSION(4,7,0)
	struct irq_fwspec fwspec = {
		.fwnode = dev->fwnode,
		.param_count = 2,
		.param[0] = ((unsigned long)dev >> 32) & 0xffffffff,
		.param[1] = ((unsigned long)dev) & 0xffffffff,
	};
	return irq_find_matching_fwspec(&fwspec, DOMAIN_BUS_ANY);
#else
	return (irq_find_host((void *)dev));
#endif
}

static int svec_fpga_vic_init(struct svec_fpga *svec_fpga)
{
	struct svec_dev *svec_dev = to_svec_dev(svec_fpga->dev.parent);
	struct vme_dev *vdev = to_vme_dev(svec_dev->dev.parent);
	unsigned long vme_start = vme_resource_start(vdev, svec_fpga->function_nr);
	const unsigned int res_n = ARRAY_SIZE(svec_fpga_vic_res);
	struct resource res[ARRAY_SIZE(svec_fpga_vic_res)];
	struct platform_device *pdev;

	if (!(svec_dev->meta.cap & SVEC_META_CAP_VIC))
		return 0;

	memcpy(&res, svec_fpga_vic_res, sizeof(svec_fpga_vic_res));
	res[0].start += vme_start;
	res[0].end += vme_start;
	res[1].start = vdev->irq;
	res[1].end = res[1].start;
	pdev = platform_device_register_resndata(&svec_fpga->dev,
						 "htvic-svec",
						 PLATFORM_DEVID_AUTO,
						 res, res_n,
						 NULL, 0);
	if (IS_ERR(pdev))
		return PTR_ERR(pdev);
	svec_fpga->vic_pdev = pdev;

	return 0;
}

static void svec_fpga_vic_exit(struct svec_fpga *svec_fpga)
{
	if (svec_fpga->vic_pdev) {
		platform_device_unregister(svec_fpga->vic_pdev);
		svec_fpga->vic_pdev = NULL;
	}
}

/* MFD devices */
enum svec_fpga_mfd_devs_enum {
	SVEC_FPGA_MFD_FMC_I2C = 0,
	SVEC_FPGA_MFD_SPI,
};

static struct resource svec_fpga_fmc_i2c_res[] = {
	{
		.name = "i2c-ocores-mem",
		.flags = IORESOURCE_MEM,
		.start = SVEC_BASE_REGS_FMC_I2C,
		.end = SVEC_BASE_REGS_FMC_I2C
		       + SVEC_BASE_REGS_FMC_I2C_SIZE - 1,
	}, {
		.name = "i2c-ocores-irq",
		.flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHLEVEL,
		.start = SVEC_FPGA_IRQ_FMC_I2C,
		.end = SVEC_FPGA_IRQ_FMC_I2C,
	},
};

#define SVEC_FPGA_WB_CLK_HZ 62500000
#define SVEC_FPGA_WB_CLK_KHZ (SVEC_FPGA_WB_CLK_HZ / 1000)
static struct ocores_i2c_platform_data svec_fpga_fmc_i2c_pdata = {
	.reg_shift = 2, /* 32bit aligned */
	.reg_io_width = 4,
	.clock_khz = SVEC_FPGA_WB_CLK_KHZ,
	.big_endian = 1,
	.num_devices = 0,
	.devices = NULL,
};

static struct resource svec_fpga_spi_res[] = {
	{
		.name = "spi-ocores-mem",
		.flags = IORESOURCE_MEM,
		.start = SVEC_BASE_REGS_FLASH_SPI,
		.end = SVEC_BASE_REGS_FLASH_SPI
		       + SVEC_BASE_REGS_FLASH_SPI_SIZE - 1,
	}, {
		.name = "spi-ocores-irq",
		.flags = IORESOURCE_IRQ | IORESOURCE_IRQ_HIGHLEVEL,
		.start = SVEC_FPGA_IRQ_SPI,
		.end = SVEC_FPGA_IRQ_SPI,
	},
};

static struct mtd_partition svec_flash_parts[] = {
	{
		.name = "SFPGA",
		.offset = 0,
		.size = SZ_1M,
	}, {
		.name = "AFPGA",
		.offset = 0x100000,
		.size = 5 * SZ_1M,
	}, {
		.name = "AFPGA_DATA",
		.offset = MTDPART_OFS_APPEND,
		.size = MTDPART_SIZ_FULL,
	},

};

struct flash_platform_data svec_flash_pdata = {
	.name = "svec-flash",
	.parts = svec_flash_parts,
	.nr_parts = ARRAY_SIZE(svec_flash_parts),
	.type = "m25p128",
};

static struct spi_board_info svec_fpga_spi_devices_info[] = {
	{
		.modalias = "m25p128",
		.max_speed_hz = SVEC_FPGA_WB_CLK_HZ / 4,
		.chip_select = 0,
		.platform_data = &svec_flash_pdata,
	}
};

static struct spi_ocores_platform_data svec_fpga_spi_pdata = {
	.big_endian = 1,
	.clock_hz = SVEC_FPGA_WB_CLK_HZ,
	.num_devices = ARRAY_SIZE(svec_fpga_spi_devices_info),
	.devices = svec_fpga_spi_devices_info,
};

static const struct mfd_cell svec_fpga_mfd_devs[] = {
	[SVEC_FPGA_MFD_FMC_I2C] = {
		.name = "i2c-ohwr",
		.platform_data = &svec_fpga_fmc_i2c_pdata,
		.pdata_size = sizeof(svec_fpga_fmc_i2c_pdata),
		.num_resources = ARRAY_SIZE(svec_fpga_fmc_i2c_res),
		.resources = svec_fpga_fmc_i2c_res,
	},
	[SVEC_FPGA_MFD_SPI] = {
		.name = "spi-ocores",
		.platform_data = &svec_fpga_spi_pdata,
		.pdata_size = sizeof(svec_fpga_spi_pdata),
		.num_resources = ARRAY_SIZE(svec_fpga_spi_res),
		.resources = svec_fpga_spi_res,
	},
};

static inline size_t __fpga_mfd_devs_size(void)
{
#define SVEC_FPGA_MFD_DEVS_MAX 2
	return (sizeof(struct mfd_cell) * SVEC_FPGA_MFD_DEVS_MAX);
}

static int svec_fpga_devices_init(struct svec_fpga *svec_fpga)
{
	struct vme_dev *vdev = to_vme_dev(svec_fpga->dev.parent->parent);
	struct svec_dev *svec_dev = dev_get_drvdata(&vdev->dev);
	struct mfd_cell *fpga_mfd_devs;
	struct irq_domain *vic_domain;
	unsigned int n_mfd = 0;
	int err;

	fpga_mfd_devs = devm_kzalloc(&svec_fpga->dev,
				     __fpga_mfd_devs_size(),
				     GFP_KERNEL);
	if (!fpga_mfd_devs)
		return -ENOMEM;

	memcpy(&fpga_mfd_devs[n_mfd],
	       &svec_fpga_mfd_devs[SVEC_FPGA_MFD_FMC_I2C],
	       sizeof(fpga_mfd_devs[n_mfd]));

	n_mfd++;
	if(svec_dev->meta.cap & SVEC_META_CAP_SPI) {
		memcpy(&fpga_mfd_devs[n_mfd],
			&svec_fpga_mfd_devs[SVEC_FPGA_MFD_SPI],
			sizeof(fpga_mfd_devs[n_mfd]));
		n_mfd++;
	}

	vic_domain = svec_fpga_irq_find_host((void *)&svec_fpga->vic_pdev->dev);
	if (!vic_domain) {
		/* Remove IRQ resource from all devices */
		fpga_mfd_devs[0].num_resources = 1;  /* FMC I2C */
		fpga_mfd_devs[1].num_resources = 1;  /* SPI */
	}

	err = mfd_add_devices(&svec_fpga->dev, PLATFORM_DEVID_AUTO,
			      fpga_mfd_devs, n_mfd,
			      &vdev->resource[svec_fpga->function_nr],
			      0, vic_domain);
	if (err)
		goto err_mfd;

	return 0;

err_mfd:
	devm_kfree(&svec_fpga->dev, fpga_mfd_devs);

	return err;
}

static void svec_fpga_devices_exit(struct svec_fpga *svec_fpga)
{
	mfd_remove_devices(&svec_fpga->dev);
}

/* Thermometer */
static ssize_t temperature_show(struct device *dev,
				struct device_attribute *attr,
				char *buf)
{
	struct svec_fpga *svec_fpga = to_svec_fpga(dev);
	struct svec_dev *svec_dev = to_svec_dev(svec_fpga->dev.parent);

	if (svec_dev->meta.cap & SVEC_META_CAP_THERM) {
		uint32_t temp = ioread32be(svec_fpga->fpga
					   + SVEC_FPGA_THERM_TEMP);

		return snprintf(buf, PAGE_SIZE, "%d.%d C\n",
			temp / 16, (temp & 0xF) * 1000 / 16);
	} else {
		return snprintf(buf, PAGE_SIZE, "-.- C\n");
	}

}
static DEVICE_ATTR_RO(temperature);

static ssize_t serial_number_show(struct device *dev,
				  struct device_attribute *attr,
				  char *buf)
{
	struct svec_fpga *svec_fpga = to_svec_fpga(dev);
	struct svec_dev *svec_dev = to_svec_dev(svec_fpga->dev.parent);

	if (svec_dev->meta.cap & SVEC_META_CAP_THERM) {
		uint32_t msb = ioread32be(svec_fpga->fpga
					  + SVEC_FPGA_THERM_SERID_MSB);
		uint32_t lsb = ioread32be(svec_fpga->fpga
					  + SVEC_FPGA_THERM_SERID_LSB);

		return snprintf(buf, PAGE_SIZE, "0x%08x%08x\n", msb, lsb);
	} else {
		return snprintf(buf, PAGE_SIZE, "0x----------------\n");
	}

}
static DEVICE_ATTR_RO(serial_number);

static struct attribute *svec_fpga_therm_attrs[] = {
	&dev_attr_serial_number.attr,
	&dev_attr_temperature.attr,
	NULL,
};

static const struct attribute_group svec_fpga_therm_group = {
	.name = "thermometer",
	.attrs = svec_fpga_therm_attrs,
};

/* CSR attributes */
static ssize_t pcb_rev_show(struct device *dev,
			    struct device_attribute *attr,
			    char *buf)
{
	struct svec_fpga *svec_fpga = to_svec_fpga(dev);

	return snprintf(buf, PAGE_SIZE, "0x%x\n",
			svec_fpga_csr_pcb_rev(svec_fpga));
}
static DEVICE_ATTR_RO(pcb_rev);

static ssize_t application_offset_show(struct device *dev,
			    struct device_attribute *attr,
			    char *buf)
{
	struct svec_fpga *svec_fpga = to_svec_fpga(dev);

	return snprintf(buf, PAGE_SIZE, "0x%x\n",
			svec_fpga_csr_app_offset(svec_fpga));
}
static DEVICE_ATTR_RO(application_offset);

enum svec_fpga_csr_resets {
	SVEC_FPGA_CSR_RESETS_ALL = BIT(0),
	SVEC_FPGA_CSR_RESETS_APP = BIT(1),
};

static void svec_fpga_app_reset(struct svec_fpga *svec_fpga, bool val)
{
	uint32_t resets;

	resets = ioread32be(svec_fpga->fpga + SVEC_FPGA_CSR_RESETS);
	if (val)
		resets |= SVEC_FPGA_CSR_RESETS_APP;
	else
		resets &= ~SVEC_FPGA_CSR_RESETS_APP;
	iowrite32be(resets, svec_fpga->fpga + SVEC_FPGA_CSR_RESETS);
}

static void svec_fpga_app_restart(struct svec_fpga *svec_fpga)
{
	svec_fpga_app_reset(svec_fpga, true);
	udelay(1);
	svec_fpga_app_reset(svec_fpga, false);
	udelay(1);
}

static ssize_t reset_app_show(struct device *dev,
			      struct device_attribute *attr,
			      char *buf)
{
	struct svec_fpga *svec_fpga = to_svec_fpga(dev);
	uint32_t resets;

	resets = ioread32be(svec_fpga->fpga + SVEC_FPGA_CSR_RESETS);
	return snprintf(buf, PAGE_SIZE, "%d\n",
			!!(resets & SVEC_FPGA_CSR_RESETS_APP));
}
static ssize_t reset_app_store(struct device *dev,
			       struct device_attribute *attr,
			       const char *buf, size_t count)
{
	long val;
	int err;

	err = kstrtol(buf, 10, &val);
	if (err)
		return err;

	svec_fpga_app_reset(to_svec_fpga(dev), val);

	return count;
}
static DEVICE_ATTR_RW(reset_app);

static struct attribute *svec_fpga_csr_attrs[] = {
	&dev_attr_pcb_rev.attr,
	&dev_attr_application_offset.attr,
	&dev_attr_reset_app.attr,
	NULL,
};

static const struct attribute_group svec_fpga_csr_group = {
	.attrs = svec_fpga_csr_attrs,
};

/* FMC */
static inline u8 svec_fmc_presence(struct svec_fpga *svec_fpga)
{
	u8 presence;

	presence = ioread32be(svec_fpga->fpga + SVEC_FPGA_CSR_FMC_PRESENT);
	return presence & (BIT(SVEC_FMC_SLOTS) - 1);
}

static int svec_fmc_is_present(struct fmc_carrier *carrier,
			       struct fmc_slot *slot)
{
	struct svec_fpga *svec_fpga = carrier->priv;

	return !!(svec_fmc_presence(svec_fpga) & BIT(slot->lun - 1));
}

static const struct fmc_carrier_operations svec_fmc_ops = {
	.owner = THIS_MODULE,
	.is_present = svec_fmc_is_present,
};

struct svec_i2c_filter {
	struct svec_fpga *svec_fpga;
	unsigned int slot_nr;
};

static int svec_i2c_find_adapter(struct device *dev, void *data)
{
	struct svec_i2c_filter *flt = data;
	struct svec_fpga *svec_fpga = flt->svec_fpga;
	struct i2c_adapter *adap, *adap_parent;

	if (dev->type != &i2c_adapter_type)
		return 0;

	adap = to_i2c_adapter(dev);
	adap_parent = i2c_parent_is_i2c_adapter(adap);
	if (!adap_parent)
		return 0;

	/* We have a muxed I2C master */
	if (&svec_fpga->dev != adap_parent->dev.parent->parent)
		return 0;

	if (flt->slot_nr > 0) {
		/* We want the following one */
		flt->slot_nr--;
		return 0;
	}
	return i2c_adapter_id(adap);
}

/**
 * Get the I2C adapter associated with an FMC slot
 * @data: data used to find the correct I2C bus
 * @slot_nr: FMC slot number
 *
 * Return: the I2C bus to be used
 */
static int svec_i2c_get_bus(struct svec_i2c_filter *flt)
{
	return i2c_for_each_dev(flt, svec_i2c_find_adapter);
}

/**
 * Create an FMC interface
 */
static int svec_fmc_init(struct svec_fpga *svec_fpga)
{
	int err, i;

	for (i = 0; i < SVEC_FMC_SLOTS; ++i) {
		struct svec_i2c_filter flt = {svec_fpga, i};

		svec_fpga->slot_info[i].i2c_bus_nr = svec_i2c_get_bus(&flt);
		if (svec_fpga->slot_info[i].i2c_bus_nr <= 0)
			return -ENODEV;
		svec_fpga->slot_info[i].ga = i;
		svec_fpga->slot_info[i].lun = i + 1;
	}

	err = fmc_carrier_register(&svec_fpga->dev, &svec_fmc_ops,
				   SVEC_FMC_SLOTS, svec_fpga->slot_info,
				   svec_fpga);
	if (err) {
		dev_err(svec_fpga->dev.parent,
			"Failed to register as FMC carrier\n");
		goto err_fmc;
	}


	return 0;

err_fmc:
	return err;
}

static int svec_fmc_exit(struct svec_fpga *svec_fpga)
{
	return fmc_carrier_unregister(&svec_fpga->dev);
}

/* FPGA Application */

/**
 * Build the platform_device_id->name from metadata
 *
 * The byte order on SVEC is big endian, but we want to convert it
 * in string. Use little-endian read to keep the string order
 * from MSB to LSB
 */
static int svec_fpga_app_id_build(struct svec_fpga *svec_fpga,
				  unsigned long app_off,
				  char *id, unsigned int size)
{
	uint32_t vendor = ioread32(svec_fpga->fpga + app_off
				   + FPGA_META_VENDOR);
	uint32_t device = ioread32(svec_fpga->fpga + app_off
				   + FPGA_META_DEVICE);

	memset(id, 0, size);
	if (vendor == 0xFF000000) {
		dev_warn(&svec_fpga->dev, "Vendor UUID not supported yet\n");
		return -ENODEV;
	}
	snprintf(id, size, "id:%4phN%4phN", &vendor, &device);

	return 0;
}

static int svec_fpga_app_init_res_mem(struct svec_fpga *svec_fpga,
				      unsigned int app_offset,
				      struct resource *res)
{
	struct svec_dev *svec_dev = to_svec_dev(svec_fpga->dev.parent);
	struct vme_dev *vdev = to_vme_dev(svec_dev->dev.parent);
	int fn = svec_fpga->function_nr;

	if (!app_offset)
		return -ENODEV;

	res->name  = "app-mem";
	res->flags = IORESOURCE_MEM;
	res->start = vme_resource_start(vdev, fn) + app_offset;
	res->end = vme_resource_end(vdev, fn);

	return 0;
}

static void svec_fpga_app_init_res_irq(struct svec_fpga *svec_fpga,
				       unsigned int first_hwirq,
				       struct resource *res,
				       unsigned int res_n)
{
	struct irq_domain *vic_domain;
	int i, hwirq;

	if (!svec_fpga->vic_pdev)
		return;

	vic_domain = svec_fpga_irq_find_host(&svec_fpga->vic_pdev->dev);
	for (i = 0, hwirq = first_hwirq; i < res_n; ++i, ++hwirq) {
		res[i].name = "app-irq";
		res[i].flags = IORESOURCE_IRQ;
		res[i].start = irq_find_mapping(vic_domain, hwirq);
	}
}


#define SVEC_FPGA_APP_NAME_MAX 47
#define SVEC_FPGA_APP_IRQ_BASE 6
#define SVEC_FPGA_APP_RES_IRQ_START 1
#define SVEC_FPGA_APP_RES_IRQ_N (32 - SVEC_FPGA_APP_IRQ_BASE)
#define SVEC_FPGA_APP_RES_N (SVEC_FPGA_APP_RES_IRQ_N + 1) /* IRQs MEM DMA */
#define SVEC_FPGA_APP_RES_MEM 0
static int svec_fpga_app_init(struct svec_fpga *svec_fpga)
{
	unsigned int res_n = SVEC_FPGA_APP_RES_N;
	struct resource *res;
	struct platform_device *pdev;
	char app_name[SVEC_FPGA_APP_NAME_MAX];
	unsigned long app_offset;
	int err = 0;

	app_offset = svec_fpga_csr_app_offset(svec_fpga);
	res = kcalloc(SVEC_FPGA_APP_RES_N, sizeof(*res), GFP_KERNEL);
	if (!res)
		return -ENOMEM;

        err = svec_fpga_app_init_res_mem(svec_fpga, app_offset,
					 &res[SVEC_FPGA_APP_RES_MEM]);
	if (err) {
		dev_warn(&svec_fpga->dev, "Application not found\n");
		err = 0;
		goto err_free;
	}


	svec_fpga_metadata_get(&svec_fpga->meta_app,
			       svec_fpga->fpga + app_offset);
	svec_fpga_app_init_res_irq(svec_fpga,
				   SVEC_FPGA_APP_IRQ_BASE,
				   &res[SVEC_FPGA_APP_RES_IRQ_START],
				   SVEC_FPGA_APP_RES_IRQ_N);

	err = svec_fpga_app_id_build(svec_fpga, app_offset,
				     app_name, SVEC_FPGA_APP_NAME_MAX);
	if (err)
		goto err_free;

	dev_info(&svec_fpga->dev,
		 "Application \"%s\" found at offset: 0x%08lx (res: %pr)\n",
		 app_name, app_offset, &res[0]);
	svec_fpga_app_restart(svec_fpga);
	pdev = platform_device_register_resndata(&svec_fpga->dev,
						 app_name, PLATFORM_DEVID_AUTO,
						 res, res_n,
						 NULL, 0);
	if (IS_ERR(pdev)) {
		err = PTR_ERR(pdev);
		goto err_free;
	}

	svec_fpga->app_pdev = pdev;

err_free:
	kfree(res);
	return err;
}

static void svec_fpga_app_exit(struct svec_fpga *svec_fpga)
{
	if (svec_fpga->app_pdev) {
		platform_device_unregister(svec_fpga->app_pdev);
		svec_fpga->app_pdev = NULL;
	}
}

static bool svec_fpga_is_valid(struct svec_dev *svec_dev,
			       struct svec_meta_id *meta)
{
	if ((meta->bom & SVEC_META_BOM_END_MASK) != SVEC_META_BOM_BE) {
		dev_err(&svec_dev->dev,
			"Expected Big Endian devices BOM: 0x%x\n",
			meta->bom);
		return false;
	}

	if ((meta->bom & SVEC_META_BOM_VER_MASK) != 0) {
		dev_err(&svec_dev->dev,
			"Unknow Metadata svecification version BOM: 0x%x\n",
			meta->bom);
		return false;
	}

	if (meta->vendor != SVEC_META_VENDOR_ID ||
	    meta->device != SVEC_META_DEVICE_ID) {
		dev_err(&svec_dev->dev,
			"Unknow vendor/device ID: %08x:%08x\n",
			meta->vendor, meta->device);
		return false;
	}

	if ((meta->version & SVEC_META_VERSION_MASK) != SVEC_META_VERSION_1_4) {
		dev_err(&svec_dev->dev,
			"Unknow version: %08x\n", meta->version);
		return false;
	}

	return true;
}

static void svec_fpga_release(struct device *dev)
{

}

static int svec_fpga_uevent(struct device *dev, struct kobj_uevent_env *env)
{
	return 0;
}

static const struct attribute_group *svec_fpga_groups[] = {
	&svec_fpga_therm_group,
	&svec_fpga_csr_group,
	NULL
};

static const struct device_type svec_fpga_type = {
	.name = "svec-fpga",
	.release = svec_fpga_release,
	.uevent = svec_fpga_uevent,
	.groups = svec_fpga_groups,
};

int svec_fpga_init(struct svec_dev *svec_dev, unsigned int function_nr)
{
	struct svec_fpga *svec_fpga;
	struct vme_dev *vdev = to_vme_dev(svec_dev->dev.parent);
	struct resource *r = &vdev->resource[function_nr];
	int err;

	if (r->flags != IORESOURCE_MEM)
		return -EINVAL;

	svec_fpga = kzalloc(sizeof(*svec_fpga), GFP_KERNEL);
	if (!svec_fpga)
		return -ENOMEM;

	svec_fpga->function_nr = function_nr;
	svec_fpga->fpga = ioremap(r->start, resource_size(r));
	if (!svec_fpga->fpga) {
		err = -ENOMEM;
		goto err_map;
	}

	svec_fpga_metadata_get(&svec_dev->meta,
			       svec_fpga->fpga + SVEC_META_BASE);
	if (!svec_fpga_is_valid(svec_dev, &svec_dev->meta)) {
		err =  -EINVAL;
		goto err_valid;
	}

	svec_fpga->dev.parent = &svec_dev->dev;
	svec_fpga->dev.driver = svec_dev->dev.driver;
	svec_fpga->dev.type = &svec_fpga_type;
	err = dev_set_name(&svec_fpga->dev, "%s-fpga",
			   dev_name(&svec_dev->dev));
	if (err)
		goto err_name;

	err = device_register(&svec_fpga->dev);
	if (err) {
		dev_err(&svec_dev->dev, "Failed to register '%s'\n",
			dev_name(&svec_fpga->dev));
		goto err_dev;
	}

	svec_fpga_dbg_init(svec_fpga);

	err = svec_fpga_vic_init(svec_fpga);
	if (err) {
		dev_err(&svec_dev->dev,
			"Failed to initialize VIC %d\n", err);
		goto err_vic;
	}
	err = svec_fpga_devices_init(svec_fpga);
	if (err) {
		dev_err(&svec_dev->dev,
			"Failed to initialize Devices %d\n", err);
		goto err_devs;
	}
	err = svec_fmc_init(svec_fpga);
	if (err) {
		dev_err(&svec_dev->dev,
			"Failed to initialize FMC %d\n", err);
		goto err_fmc;
	}
	err = svec_fpga_app_init(svec_fpga);
	if (err) {
		dev_err(&svec_dev->dev,
			"Failed to initialize APP %d\n", err);
		goto err_app;
	}

	svec_dev->svec_fpga = svec_fpga;
	return 0;

err_app:
	svec_fmc_exit(svec_fpga);
err_fmc:
	svec_fpga_devices_exit(svec_fpga);
err_devs:
	svec_fpga_vic_exit(svec_fpga);
err_vic:
	return err;

err_dev:
err_name:
err_valid:
	iounmap(svec_fpga->fpga);
err_map:
	kfree(svec_fpga);
	svec_dev->svec_fpga = NULL;
	return err;
}

int svec_fpga_exit(struct svec_dev *svec_dev)
{
	struct svec_fpga *svec_fpga = svec_dev->svec_fpga;

	if (!svec_fpga)
		return 0;

	/* this function must run before re-flashing */
	BUG_ON(svec_dev->flags & SVEC_DEV_FLAGS_REPROGRAMMED);
	svec_fpga_app_exit(svec_fpga);
	svec_fmc_exit(svec_fpga);
	svec_fpga_devices_exit(svec_fpga);
	svec_fpga_vic_exit(svec_fpga);

	svec_fpga_dbg_exit(svec_fpga);
	device_unregister(&svec_fpga->dev);
	iounmap(svec_fpga->fpga);
	kfree(svec_fpga);
	svec_dev->svec_fpga = NULL;

	return 0;
}
