..
  SPDX-License-Identifier: CC-BY-SA-4.0
  SPDX-FileCopyrightText: 2019-2020 CERN

.. _svec_hdl_svec_base:

SVEC Base HDL Component
=======================

The ``SVEC base`` HDL component provides the basic support for the SVEC card
and it is strongly recommended for any SVEC based design, even though it
is not mandatory.  This component groups together a set of ip-cores which
are required to drive hardware chips and FPGA ip-cores that are handy to
develop SPEC based designs.

The ``SPEC base`` is compliant with the `FPGA device identification`_ rules.

Components
----------

The following table summarizes the ``SVEC base`` components  and after that
you have a brief description of each of them.  We do not expect to add or
remove components in the future so this should be an exhaustive list.

     ===================  =============
     Component            Cap. Mask Bit
     CSR                  (Mandatory)
     Therm. & ID          1
     Gen-Core I2C Ocore   (Mandatory)
     Gen-Core SPI         2
     Gen-Core VIC         0
     Build info           4
     White-Rabbit         3
     ===================  =============

.. note::
   The *Capability Mask Bit* (Cap. Mask Bit) refers to the bit in the
   capability mask described in the `FPGA device identification`_
   rules.

CSR
  Control and Status register for the ``SVEC base`` device.

Therm. & ID
  A onewire interface from `general cores`_ that accesses the SVEC
  thermometer to get temperature and serial number.

General Cores I2C OpenCore
  An I2C controller from `general cores`_ which bus is wired to the FMC
  connector to access the I2C EEPROM on the FMC module.

General Cores SPI OpenCore
  An SPI controller from `general cores`_ which bus is wired to the SPI
  flash memory on which we store FPGA configurations.

General Cores VIC
  An interrupt controller from `general cores`_ that routes FPGA
  interrupts to VME slave. The interrupt lines from 0 to 5 are
  reserved for internal use as described in the following table. All
  other lines are available for users.

    ==============  ===================
    Interrupt Line  Component
    0               Gen-Core I2C Ocore
    1               Gen-Core SPI Ocore
    2               (reserved)
    3               (reserved)
    4               (reserved)
    5               (reserved)
    ==============  ===================

Build Info
  Free format information (ASCII) about the FPGA synthesis.

White-Rabbit
  The `White-Rabbit core`_.

.. note::
  If the `White-Rabbit core`_ is instantiated then the components
  *Therm. & ID* and *General Cores SPI OpenCore* get disabled because
  they are incompatible.  This because the `White-Rabbit core`_ needs
  the OneWire bus and the SPI bus for internal use, therefore those
  resources can't be used.

Usage
-----

The ``SVEC base`` component is in ``hdl/rtl/svec_base_wr.vhd`` and
examples of its usage are available in ``hdl/top/``.

Remember that the Linux driver expects the ``SVEC base`` at offset
``0x00000000``.

Meta-Data ROM
-------------

These are the fixed fields in the current (|version|) release.

  ==========  ==========  ==================  ============
  Offset      Size (bit)  Name                Default (LE)
  0x00000000  32          Vendor ID           0x000010DC
  0x00000004  32          Device ID           0x53564543
  0x00000008  32          Version             0x0105xxxx
  0x0000000C  32          Byte Order Mark     0xFFFE0000
  0x00000010  128         Source ID           <variable>
  0x00000020  32          Capability Mask     0x0000000x
  0x00000030  128         Vendor UUID         0x00000000
  ==========  ==========  ==================  ============

Memory Map
----------

.. include:: svec_base_regs.rst

SVEC Golden FPGA bitstream
--------------------------

The SVEC Application FPGA golden bitstream is a safe FPGA application
instantiating only the `SVEC Base HDL Component`_. This enables all SVEC
hardware features allowing users to perform basic actions:

- reading the card temperature,
- accessing the on-board SPI flash,
- verify the presence of an FMC module,
- accessing the FMC module's EEPROM,
- get a working white-rabbit link.

.. note:: You might find this bitstream pre-programmed on your card

.. note:: The bitstream does not drive any of the FMC module user/clock pins to
          protect from electrical damage resulting from mismatched I/O standards.

.. note:: SVEC base memory map is instanciated at the beginning of the address
          space. Hence, `Memory Map`_ is the same.

.. _`SVEC project`: https://ohwr.org/project/svec
.. _`FPGA device identification`: https://www.ohwr.org/project/fpga-dev-id/
.. _`general cores`: https://www.ohwr.org/projects/general-cores
.. _`GN4124 core`: https://www.ohwr.org/project/gn4124-core/
.. _`White-Rabbit core`: https://ohwr.org/project/wr-cores
