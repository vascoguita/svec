-include Makefile.specific
# include parent_common.mk for buildsystem's defines
#use absolute path for REPO_PARENT
REPO_PARENT ?= $(shell /bin/pwd)/../..
-include $(REPO_PARENT)/parent_common.mk

TOP_DIR ?= $(shell pwd)/../..
HDL_DIR ?= $(TOP_DIR)/hdl

KVERSION ?= $(shell uname -r)
LINUX ?= /lib/modules/$(KVERSION)/build

CONFIG_FPGA_MGR_BACKPORT_PATH_ABS ?= $(abspath $(CONFIG_FPGA_MGR_BACKPORT_PATH))

VMEBRIDGE_ABS ?= $(abspath $(VMEBRIDGE))
FPGA_MGR_ABS ?= $(abspath $(FPGA_MGR))
FMC_ABS ?= $(abspath $(FMC))
I2C_ABS ?= $(abspath $(I2C))

VERSION = $(shell git describe --dirty --long --tags)

CHEBY ?= /usr/bin/cheby

all: modules

.PHONY: all modules clean help install modules_install coccicheck svec-core-fpga.h

svec-core-fpga.h:
	$(CHEBY) --gen-c -i $(HDL_DIR)/rtl/svec_base_regs.cheby > $@

clean-spec-core-fpga.h:
	rm -f spec-core-fpga.h

install: modules_install
clean: clean-spec-core-fpga.h
modules help coccichek modules_install: svec-core-fpga.h
	$(MAKE) -C $(LINUX) M=$(shell pwd) \
		VERSION=$(VERSION) \
		VMEBRIDGE_ABS=$(VMEBRIDGE_ABS) \
		CONFIG_FPGA_MGR_BACKPORT_PATH_ABS=$(CONFIG_FPGA_MGR_BACKPORT_PATH_ABS) \
		CONFIG_FPGA_MGR_BACKPORT=$(CONFIG_FPGA_MGR_BACKPORT) \
		FMC_ABS=$(FMC_ABS) \
		I2C_ABS=$(I2C_ABS) \
		$@
