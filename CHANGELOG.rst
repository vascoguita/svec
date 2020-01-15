==========
Change Log
==========

[unreleased]
============
Added
-----
- [hdl] Add support for DDR5 bank to SVEC base

Fixed
-----
- [hdl] DDR constraints
- [hdl] DDR controller generic values are now properly capitalised

[1.4.6] 2019-12-16
==================
Changed
-----
- [sw] better integration in coht, rename environment variable to FPGA_MGR

[1.4.5] 2019-12-16
==================
Fixed
-----
- [sw] suggested fixed reported by checkpatch and coccicheck

[1.4.4] 2019-12-13
==================
Fixed
-----
- [sw] soft dependency from i2c_ohwr to i2c-ocores

[1.4.3] 2019-10-17
==================
Added
-----
- [doc] sphinx documentation

[1.4.2] 2019-10-17
==================
Changed
-----
- [sw] show application metadata in debugfs

[1.4.1] 2019-10-15
==================
Fixed
-----
- [sw] fix building system failure

[1.4.0] 2019-09-11
==================
Added
-----
- [hdl] svec-base IP-core to support SVEC based designs
- [sw] Support for svec-base IP-core
- [sw] Support for FMC

[0.0.0] - 2017-09-28
====================
Added
-----
- [sw] basic Linux device driver
