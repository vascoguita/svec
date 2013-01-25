#!/bin/bash

# A trivial script to build the SDB flash image for the SVEC. Requires sdb-tools installed in the system

cp ../../hdl/syn/sfpga_bootloader/svec_sfpga_top.bin fs/sfpga.bin
cp ../../hdl/syn/golden/svec_top.bin fs/afpga.bin
gcc bin2vmf.c -o bin2vmf
gcc bin2ihex.c -o bin2ihex
gensdbfs fs image.bin
./bin2vmf image.bin > image.vmf
./bin2ihex -e -o image.mcs image.bin