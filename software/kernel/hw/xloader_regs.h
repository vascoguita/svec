// SPDX-FileCopyrightText: 2022 CERN (home.cern)
//
// SPDX-License-Identifier: GPL-2.0-or-later

/*
  Register definitions for slave core: Xilinx FPGA loader

  * File           : xloader_regs.h
  * Author         : auto-generated by wbgen2 from xloader_wb.wb
  * Created        : Thu Jun 21 15:17:30 2012
  * Standard       : ANSI C

    THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE xloader_wb.wb
    DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!

*/

#ifndef __WBGEN2_REGDEFS_XLOADER_WB_WB
#define __WBGEN2_REGDEFS_XLOADER_WB_WB


#if defined( __GNUC__)
#define PACKED __attribute__ ((packed))
#else
#error "Unsupported compiler?"
#endif

#ifndef __WBGEN2_MACROS_DEFINED__
#define __WBGEN2_MACROS_DEFINED__
#define WBGEN2_GEN_MASK(offset, size) (((1<<(size))-1) << (offset))
#define WBGEN2_GEN_WRITE(value, offset, size) (((value) & ((1<<(size))-1)) << (offset))
#define WBGEN2_GEN_READ(reg, offset, size) (((reg) >> (offset)) & ((1<<(size))-1))
#define WBGEN2_SIGN_EXTEND(value, bits) (((value) & (1<<bits) ? ~((1<<(bits))-1): 0 ) | (value))
#endif


/* definitions for register: Control/status register */

/* definitions for field: Start configuration in reg: Control/status register */
#define XLDR_CSR_START                        WBGEN2_GEN_MASK(0, 1)

/* definitions for field: Configuration done in reg: Control/status register */
#define XLDR_CSR_DONE                         WBGEN2_GEN_MASK(1, 1)

/* definitions for field: Configuration error in reg: Control/status register */
#define XLDR_CSR_ERROR                        WBGEN2_GEN_MASK(2, 1)

/* definitions for field: Loader busy in reg: Control/status register */
#define XLDR_CSR_BUSY                         WBGEN2_GEN_MASK(3, 1)

/* definitions for field: Byte order select in reg: Control/status register */
#define XLDR_CSR_MSBF                         WBGEN2_GEN_MASK(4, 1)

/* definitions for field: Software resest in reg: Control/status register */
#define XLDR_CSR_SWRST                        WBGEN2_GEN_MASK(5, 1)

/* definitions for field: Exit bootloader mode in reg: Control/status register */
#define XLDR_CSR_EXIT                         WBGEN2_GEN_MASK(6, 1)

/* definitions for field: Serial clock divider in reg: Control/status register */
#define XLDR_CSR_CLKDIV_MASK                  WBGEN2_GEN_MASK(8, 6)
#define XLDR_CSR_CLKDIV_SHIFT                 8
#define XLDR_CSR_CLKDIV_W(value)              WBGEN2_GEN_WRITE(value, 8, 6)
#define XLDR_CSR_CLKDIV_R(reg)                WBGEN2_GEN_READ(reg, 8, 6)
/* definitions for field: Bootloader version */
#define XLDR_CSR_VERSION_MASK                 WBGEN2_GEN_MASK(14, 8)
#define XLDR_CSR_VERSION_SHIFT                14
#define XLDR_CSR_VERSION_R(reg)               WBGEN2_GEN_READ(reg, 14, 8)


/* definitions for register: Bootloader Trigger Register */

/* definitions for register: GPIO Output Register */

/* definitions for register: ID Register */

/* definitions for register: FIFO 'Bitstream FIFO' data input register 0 */

/* definitions for field: Entry size in reg: FIFO 'Bitstream FIFO' data input register 0 */
#define XLDR_FIFO_R0_XSIZE_MASK               WBGEN2_GEN_MASK(0, 2)
#define XLDR_FIFO_R0_XSIZE_SHIFT              0
#define XLDR_FIFO_R0_XSIZE_W(value)           WBGEN2_GEN_WRITE(value, 0, 2)
#define XLDR_FIFO_R0_XSIZE_R(reg)             WBGEN2_GEN_READ(reg, 0, 2)

/* definitions for field: Last xfer in reg: FIFO 'Bitstream FIFO' data input register 0 */
#define XLDR_FIFO_R0_XLAST                    WBGEN2_GEN_MASK(2, 1)

/* definitions for register: FIFO 'Bitstream FIFO' data input register 1 */

/* definitions for field: Data in reg: FIFO 'Bitstream FIFO' data input register 1 */
#define XLDR_FIFO_R1_XDATA_MASK               WBGEN2_GEN_MASK(0, 32)
#define XLDR_FIFO_R1_XDATA_SHIFT              0
#define XLDR_FIFO_R1_XDATA_W(value)           WBGEN2_GEN_WRITE(value, 0, 32)
#define XLDR_FIFO_R1_XDATA_R(reg)             WBGEN2_GEN_READ(reg, 0, 32)

/* definitions for register: FIFO 'Bitstream FIFO' control/status register */

/* definitions for field: FIFO full flag in reg: FIFO 'Bitstream FIFO' control/status register */
#define XLDR_FIFO_CSR_FULL                    WBGEN2_GEN_MASK(16, 1)

/* definitions for field: FIFO empty flag in reg: FIFO 'Bitstream FIFO' control/status register */
#define XLDR_FIFO_CSR_EMPTY                   WBGEN2_GEN_MASK(17, 1)

/* definitions for field: FIFO clear in reg: FIFO 'Bitstream FIFO' control/status register */
#define XLDR_FIFO_CSR_CLEAR_BUS               WBGEN2_GEN_MASK(18, 1)

/* definitions for field: FIFO counter in reg: FIFO 'Bitstream FIFO' control/status register */
#define XLDR_FIFO_CSR_USEDW_MASK              WBGEN2_GEN_MASK(0, 8)
#define XLDR_FIFO_CSR_USEDW_SHIFT             0
#define XLDR_FIFO_CSR_USEDW_W(value)          WBGEN2_GEN_WRITE(value, 0, 8)
#define XLDR_FIFO_CSR_USEDW_R(reg)            WBGEN2_GEN_READ(reg, 0, 8)
/* [0x0]: REG Control/status register */
#define XLDR_REG_CSR 0x00000000
/* [0x4]: REG Bootloader Trigger Register */
#define XLDR_REG_BTRIGR 0x00000004
/* [0x8]: REG GPIO Output Register */
#define XLDR_REG_GPIOR 0x00000008
/* [0xc]: REG ID Register */
#define XLDR_REG_IDR 0x0000000c
/* [0x10]: REG FIFO 'Bitstream FIFO' data input register 0 */
#define XLDR_REG_FIFO_R0 0x00000010
/* [0x14]: REG FIFO 'Bitstream FIFO' data input register 1 */
#define XLDR_REG_FIFO_R1 0x00000014
/* [0x18]: REG FIFO 'Bitstream FIFO' control/status register */
#define XLDR_REG_FIFO_CSR 0x00000018
#endif
