#!/bin/bash

# A trivial script to build the SDB flash image for the SVEC. Requires sdb-tools installed in the system

PROMGEN=`which promgen`
GENSDBFS=`which gensdbfs`

if [ ! -f "$PROMGEN" ]; then
	echo "You seem to not have the promgen utility. Do you have Xilinx ISE installed?"
	exit
fi

if [ ! -f "$GENSDBFS" ]; then
	echo "You seem to not have the gensdbfs. Have you compiled and installed it (check the manual)?"
	exit
fi


gensdbfs fs image.bin
promgen -p mcs -o image.mcs -spi -data_file up 0 image.bin  -w
./bin2vmf image.bin > image.vmf
