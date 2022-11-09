# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: LGPL-2.1-or-later

-include Makefile.specific
-include $(REPO_PARENT)/parent_common.mk

DIRS = kernel

.PHONY: all clean modules install modules_install coccicheck $(DIRS)

all clean : $(DIRS)
install modules_install coccicheck modules: kernel

clean: TARGET = clean
modules: TARGET = modules
coccicheck: TARGET = coccicheck
install: TARGET = install
modules_install: TARGET = modules_install

$(DIRS):
	$(MAKE) -C $@ $(TARGET)
