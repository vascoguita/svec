#ifndef __CHEBY__SVEC_TEMPLATE_REGS__H__
#define __CHEBY__SVEC_TEMPLATE_REGS__H__
#define SVEC_TEMPLATE_REGS_SIZE 8192

/* a ROM containing the carrier metadata */
#define SVEC_TEMPLATE_REGS_METADATA 0x0UL
#define SVEC_TEMPLATE_REGS_METADATA_SIZE 64

/* carrier and fmc status and control */
#define SVEC_TEMPLATE_REGS_CSR 0x40UL
#define SVEC_TEMPLATE_REGS_CSR_SIZE 32

/* offset to the application metadata */
#define SVEC_TEMPLATE_REGS_CSR_APP_OFFSET 0x40UL

/* global and application resets */
#define SVEC_TEMPLATE_REGS_CSR_RESETS 0x44UL
#define SVEC_TEMPLATE_REGS_CSR_RESETS_GLOBAL 0x1UL
#define SVEC_TEMPLATE_REGS_CSR_RESETS_APPL 0x2UL

/* presence lines for the fmcs */
#define SVEC_TEMPLATE_REGS_CSR_FMC_PRESENCE 0x48UL

/* status of gennum */
#define SVEC_TEMPLATE_REGS_CSR_GN4124_STATUS 0x4cUL

/* status of the ddr3 controller */
#define SVEC_TEMPLATE_REGS_CSR_DDR_STATUS 0x50UL
#define SVEC_TEMPLATE_REGS_CSR_DDR_STATUS_CALIB_DONE 0x1UL

/* pcb revision */
#define SVEC_TEMPLATE_REGS_CSR_PCB_REV 0x54UL
#define SVEC_TEMPLATE_REGS_CSR_PCB_REV_REV_MASK 0xfUL
#define SVEC_TEMPLATE_REGS_CSR_PCB_REV_REV_SHIFT 0

/* Thermometer and unique id */
#define SVEC_TEMPLATE_REGS_THERM_ID 0x70UL
#define SVEC_TEMPLATE_REGS_THERM_ID_SIZE 16

/* i2c controllers to the fmcs */
#define SVEC_TEMPLATE_REGS_FMC_I2C 0x80UL
#define SVEC_TEMPLATE_REGS_FMC_I2C_SIZE 32

/* spi controller to the flash */
#define SVEC_TEMPLATE_REGS_FLASH_SPI 0xa0UL
#define SVEC_TEMPLATE_REGS_FLASH_SPI_SIZE 32

/* dma registers for the gennum core */
#define SVEC_TEMPLATE_REGS_DMA 0xc0UL
#define SVEC_TEMPLATE_REGS_DMA_SIZE 64

/* vector interrupt controller */
#define SVEC_TEMPLATE_REGS_VIC 0x100UL
#define SVEC_TEMPLATE_REGS_VIC_SIZE 256

/* a ROM containing build information */
#define SVEC_TEMPLATE_REGS_BUILDINFO 0x200UL
#define SVEC_TEMPLATE_REGS_BUILDINFO_SIZE 256

/* white-rabbit core registers */
#define SVEC_TEMPLATE_REGS_WRC_REGS 0x1000UL
#define SVEC_TEMPLATE_REGS_WRC_REGS_SIZE 4096

struct svec_template_regs {
  /* [0x0]: SUBMAP a ROM containing the carrier metadata */
  uint32_t metadata[16];

  /* [0x40]: BLOCK carrier and fmc status and control */
  struct csr {
    /* [0x0]: REG (ro) offset to the application metadata */
    uint32_t app_offset;

    /* [0x4]: REG (rw) global and application resets */
    uint32_t resets;

    /* [0x8]: REG (ro) presence lines for the fmcs */
    uint32_t fmc_presence;

    /* [0xc]: REG (ro) status of gennum */
    uint32_t gn4124_status;

    /* [0x10]: REG (ro) status of the ddr3 controller */
    uint32_t ddr_status;

    /* [0x14]: REG (ro) pcb revision */
    uint32_t pcb_rev;

    /* padding to: 5 words */
    uint32_t __padding_0[2];
  } csr;

  /* padding to: 28 words */
  uint32_t __padding_0[4];

  /* [0x70]: SUBMAP Thermometer and unique id */
  uint32_t therm_id[4];

  /* [0x80]: SUBMAP i2c controllers to the fmcs */
  uint32_t fmc_i2c[8];

  /* [0xa0]: SUBMAP spi controller to the flash */
  uint32_t flash_spi[8];

  /* [0xc0]: SUBMAP dma registers for the gennum core */
  uint32_t dma[16];

  /* [0x100]: SUBMAP vector interrupt controller */
  uint32_t vic[64];

  /* [0x200]: SUBMAP a ROM containing build information */
  uint32_t buildinfo[64];

  /* padding to: 1024 words */
  uint32_t __padding_1[832];

  /* [0x1000]: SUBMAP white-rabbit core registers */
  uint32_t wrc_regs[1024];
};

#endif /* __CHEBY__SVEC_TEMPLATE_REGS__H__ */
