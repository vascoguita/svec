.. SPDX-License-Identifier: CC-BY-SA-4.0
.. SPDX-FileCopyrightText: 2019-2020 CERN

The SPI FLASH Memory
====================

The on-board SPI flash memory can be the `M25P128`_ or the `MT25QL128`_. It is
used to store the :doc:`hdl-bootloader`, an application bitstream, and
eventually also user data.

Flash memory organization
-------------------------

The memory contains 16 Megabytes of data, that is 65536 pages of 256 bytes. The
first 6 MiB are used for bitstream storage. The flash format is compatible with
the SDB filesystem, with the SDB descriptor table located at offset
``0x600000``. Locations of the bitstreams are fixed to:

=========================== ==============================================
Address Range               Description
=========================== ==============================================
``0x00000000 - 0x000FFFFF`` Bitstream (``.bin``) for the System FPGA
``0x00100000 - 0x005FFFFF`` Bitstream  (``.bin``) for the Application FPGA
``0x00600000 - 0x00600FFF`` Obsolete (SDB)
``0x00601000 - 0x00ffffff`` Free space, private data storage.
=========================== ==============================================

Accessing the SPI Flash from the Application FPGA
-------------------------------------------------

:doc:`hdl-bootloader` version 3 allows the Application FPGA to access the SPI
interface of the Flash memory. Once the boot process is done, the System FPGA
routes the following AFPGA pins directly to the Flash memory's SPI interface
(Xilinx UCF file syntax).::

    NET "flash_sck_o" LOC=AG26;
    NET "flash_mosi_o" LOC=AH26;
    NET "flash_cs_n_o" LOC=AG27;
    NET "flash_miso_i" LOC=AH27;

    NET "flash_sck_o" IOSTANDARD = "LVCMOS33";
    NET "flash_mosi_o" IOSTANDARD = "LVCMOS33";
    NET "flash_cs_n_o" IOSTANDARD = "LVCMOS33";
    NET "flash_miso_i" IOSTANDARD = "LVCMOS33";


.. _`M25P128`: http://www.micron.com/parts/nor-flash/serial-nor-flash/m25p128-vme6gb
.. _`MT25QL128`: https://www.micron.com/-/media/client/global/documents/products/data-sheet/nor-flash/serial-nor/mt25q/die-rev-a/mt25q_qlhs_l_128_aba_0.pdf
