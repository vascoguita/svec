# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: GPL-2.0-or-later

-include Makefile.specific
-include $(REPO_PARENT)/parent_common.mk

TOP_DIR ?= $(shell pwd)/../..
HDL_DIR ?= $(TOP_DIR)/hdl

KVERSION ?= $(shell uname -r)
KERNELSRC ?= /lib/modules/$(KVERSION)/build

VMEBRIDGE_ABS ?= $(abspath $(VMEBRIDGE))
FPGA_MGR_ABS ?= $(abspath $(FPGA_MGR))
FMC_ABS ?= $(abspath $(FMC))
I2C_ABS ?= $(abspath $(I2C))
SPI_ABS ?= $(abspath $(SPI))

VERSION = $(shell git describe --dirty --long --tags)

CHEBY ?= cheby

CONFIG_FPGA_MGR_BACKPORT ?= n

all: modules

.PHONY: all modules clean help install modules_install coccicheck svec-core-fpga.h

svec-core-fpga.h:
	$(CHEBY) --gen-c -i $(HDL_DIR)/rtl/svec_base_regs.cheby > $@

clean-spec-core-fpga.h:
	rm -f spec-core-fpga.h

install: modules_install

clean: clean-spec-core-fpga.h
	$(MAKE) -C $(KERNELSRC) M=$(shell pwd) $@

modules help coccicheck modules_install: svec-core-fpga.h
	$(MAKE) -C $(KERNELSRC) M=$(shell pwd) \
		VERSION=$(VERSION) \
		VMEBRIDGE_ABS=$(VMEBRIDGE_ABS) \
		FPGA_MGR_ABS=$(FPGA_MGR_ABS) \
		CONFIG_FPGA_MGR_BACKPORT=$(CONFIG_FPGA_MGR_BACKPORT) \
		FMC_ABS=$(FMC_ABS) \
		I2C_ABS=$(I2C_ABS) \
		SPI_ABS=$(SPI_ABS) \
		$@
