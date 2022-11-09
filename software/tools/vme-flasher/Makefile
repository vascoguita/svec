# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: LGPL-2.1-or-later

CC = gcc
CFLAGS = -I.
OBJS = libvmebus.o svec-flasher.o

all:	$(OBJS)
	${CC} -o svec-flasher $(OBJS)

clean:
	rm -f $(OBJS) svec-flasher