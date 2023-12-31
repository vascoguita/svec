.. SPDX-FileCopyrightText: 2022 CERN (home.cern)
..
.. SPDX-License-Identifier: CC-BY-SA-4.0+

==========
Change Log
==========

3.0.0 - 2022-12-05
==================
Added
-----
- ci: better automation
- sw: support for Linux 5.10

Removed
-------
- hdl: unused and obsolete top-levels and simulations
- hdl: Xilinx chipscope for SFPGA (files were actually for AFPGA)

Changed
-------
- hdl: 'golden_wr' top-level renamed to 'wr_example'
- hdl: 'template' testbench now used for simulating the golden top-level
- sw|API change: the API to flash a bitstream moved from debugfs to sysfs. The
  Linux kernel community removed API we used. The same behavior was achievable
  only using sysfs.
- bld: improved Makefiles

Fixed
-----
- hdl: building of all top-levels
- hdl: missing ddr and wr-cores dependencies
- hdl: corrected and re-enabled timing constraints
- hdl: location of general-cores in rtl Manifest

2.0.4 - 2021-07-29
==================
Fixed
-----
- sw: improve compatibility with newer ( > 3.10) Linux kernel version

2.0.3 - 2021-03-22
==================
Fixed
-----
- sw: fix SVEC flasher size

2.0.2 - 2021-03-16
==================
Changed
-------
- sw: better version validation implementation

2.0.1 - 2021-02-08
==================
Added
-----
- sw: dynamically set the compatibility version between software and FPGA
- sw: added the possibility to ignore the version check

Changed
-------
- hdl: the DMA interface changed to support BLT and MBLT acquisitions

1.5.2 - 2020-11-24
==================
Added
-----
- sw: tool to inspect SVEC bitstream ROM

Fixed
-----
- hdl: svec-base version

1.5.1 - 2020-11-24
==================
Fixed
-----
- sw: NULL pointer at load time when using the SPI controller
- sw: remove old unload procedure that causes BUG_ON to be triggered
  without valid reasons

1.5.0 - 2020-11-02
===================
Added
-----
- sw: add SPI flash partitions
- hdl: enable DDR4

Changed
-------
- sw: internal driver improvements

1.4.12 - 2020-06-03
===================
Added
-----
- hdl: ignore autogenerated files to build metadata (otherwise the repository
  is always marked as dirty)

Fixed
-----
- sw: impossibility of loading application because of wrong address space

1.4.11 - 2020-05-20
===================
Added
-----
- hdl: export DDMTD clock output

1.4.10 - 2020-05-12
===================
Added
-----
- hdl: metadata source-id automatic assignment
- hdl: add option to consider AM in VME slave decoder

Fixed
-----
- hdl: fix typos when ddr is not configured. This froze the board when
  reading a ddr data register.

Changed
-------
- sw: Linux device hierarchy seen in sysfs. It is incompatible but
  tools, today do not rely in this. So we take the freedom to change
  it without a major release.
- sw: on device removal the IRQ vector number in the CR/CSR space is set
  to 0x0

1.4.9 - 2020-03-10
==================
Fixed
-----
- sw: reduce allocation on stack
- sw: automatically remove device after FPGA reprogram (otherwise unusable)

1.4.8 - 2020-02-12
==================
Fixed
-----
- sw: fix kernel crash when programming new bitstream


1.4.7 - 2020-01-15
==================
Added
-----
- hdl: Add support for DDR5 bank to SVEC base

Fixed
-----
- hdl: DDR constraints
- hdl: DDR controller generic values are now properly capitalised
- sw: Update svec-flasher to work with new type of flash memory used in
  newer SVEC boards

1.4.6 - 2019-12-16
==================
Changed
-------
- sw: better integration in coht, rename environment variable to FPGA_MGR

1.4.5 - 2019-12-16
==================
Fixed
-----
- sw: suggested fixed reported by checkpatch and coccicheck

1.4.4 - 2019-12-13
==================
Fixed
-----
- sw: soft dependency from i2c_ohwr to i2c-ocores

1.4.3 - 2019-10-17
==================
Added
-----
- doc: sphinx documentation

1.4.2 - 2019-10-17
==================
Changed
-------
- sw: show application metadata in debugfs

1.4.1 - 2019-10-15
==================
Fixed
-----
- sw: fix building system failure

1.4.0 - 2019-09-11
==================
Added
-----
- hdl: svec-base IP-core to support SVEC based designs
- sw: Support for svec-base IP-core
- sw: Support for FMC

0.0.0 - 2017-09-28
====================
Added
-----
- sw: basic Linux device driver
