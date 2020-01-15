..
  SPDX-License-Identifier: CC-BY-SA-4.0
  SPDX-FileCopyrightText: 2019-2020 CERN

.. _svec_driver:

SVEC Driver(s)
==============

Driver(s) Structure
-------------------

There are drivers for the SVEC card and there are drivers for the
:ref:`SVEC base<svec_hdl_svec_base>` component. All these drivers are
managed by:

.. _svec_fmc_carrier:

SVEC FMC Carrier
  This is the driver that wrap up all the physical components and the
  :ref:`SVEC base<svec_hdl_svec_base>` ones. It configures the card so
  that all components cooperate correctly. It also provides the support
  for FPGA programming through the `FPGA manager interface`_.

If the SVEC based application is using the :ref:`SVEC
base<svec_hdl_svec_base>` component then it can profit from the
following driver. They are not all mandatory, it depends on the
application, and most of them are distributed separately:

.. _i2c_ocore:

I2C OCORE
  This is the driver for the I2C OCORE IP-core. It is used to communicate with
  the standard FMC EEPROM available what on FMC modules. The driver is
  available in Linux but also (as a backport) in `general cores`_.

.. _spi_ocore:

SPI OCORE
  This is the driver for the SPI OCORE IP-core. It is used to communicate with
  the M25P32 FLASH memory where FPGA bitstreams are stored. The driver is
  distributed separately in `general cores`_.

.. _vic:

VIC
  The driver for the VIC interrupt controller IP-core. The driver is
  distributed separately in `general cores`_.

.. _`OHWR`: https://ohwr.org
.. _`SVEC project`: https://ohwr.org/project/svec
.. _`FMC`: https://www.ohwr.org/projects/fmc-sw
.. _`FPGA manager interface`: https://www.kernel.org/doc/html/latest/driver-api/fpga/index.html
.. _`DMA Engine`: https://www.kernel.org/doc/html/latest/driver-api/dmaengine/index.html
.. _`general cores`: https://www.ohwr.org/projects/general-cores

Drivers Build and Install
-------------------------

From the project top level directory, you can find the driver(s) source files
under ``software/kernel``.

The SVEC software uses plain ``Makefile`` to build drivers. Therefore, you can
build the driver by executing ``make``.  To successfully build the SVEC driver
you need to install the `cheby`_ tool that will generate on fly part of the
code for the :ref:`SVEC base<svec_hdl_svec_base>`.  If you do not want to
install `cheby`_ you can define the path to it with the environment
variable ``CHEBY``.  Following an example on how to build the driver.::

  # define CHEBY only if it is not installed
  export CHEBY=/path/to/cheby/proto/cheby.py
  cd /path/to/svec/
  make -C software/kernel modules
  make -C software/kernel modules_install

This will build and install 1 driver:

- :ref:`svec-fmc-carrier.ko<svec_fmc_carrier>`,

::

  find software -name "*.ko"
  software/kernel/svec-fmc-carrier.ko

Please note that this will not install all soft dependencies which are
distributed separately (:ref:`I2C OpenCore<i2c_ocore>`,
:ref:`SPI OpenCore<spi_ocore>`, :ref:`HT Vector Interrupt Controller<vic>`,
`FMC`_).

.. _`cheby`: https://gitlab.cern.ch/cohtdrivers/cheby

Driver(s) Loading
-----------------

The VME Slave ip-core is part of the :ref:`SVEC base<svec_hdl_svec_base>`
component. Since this is on FPGA, if the FPGA is not programmed then you do not
get the full VME support.

If you need to manually install/remove the driver and its dependencies, you
can use `modprobe(8)`_.::

  sudo modprobe svec-fmc-carrier

If you did not install the drivers you can use `insmod(8)`_ and `rmmod(8)`_.
In this case is useful to know what drivers to load (dependencies) and their
(un)loading order.::

  # typically part of the distribution
  modprobe at24
  modprobe mtd
  modprobe m25p80
  # from OHWR
  insmod /path/to/fmc-sw/drivers/fmc/fmc.ko
  insmod /path/to/general-cores/software/htvic/drivers/htvic.ko
  insmod /path/to/general-cores/software/i2c-ocores/drivers/i2c/busses/i2c-ocores.ko
  insmod /path/to/general-cores/software/spi-ocores/drivers/spi/spi-ocores.ko
  # Actually the order above does not really matter, what matters
  # it is that svec-fmc-carrier.ko is loaded as last
  insmod /path/to/svec/software/kernel/svec-fmc-carrier.ko

.. _`modprobe(8)`: https://linux.die.net/man/8/modprobe
.. _`insmod(8)`: https://linux.die.net/man/8/insmod
.. _`rmmod(8)`: https://linux.die.net/man/8/rmmod


Attributes From *sysfs*
-----------------------

In addition to standard *sysfs* attributes for VME, `FPGA manager`_,
and `FMC`_ there more SVEC specific *sysfs* attributes.  Here we focus
only on those.

If the FPGA is correctly programmed (an FPGA configuration that uses the
:ref:`SVEC base<svec_hdl_svec_base>`) then there will be a directory
named ``svec-vme-<vme-slot>`` that contains the reference to all FPGA
sub-devices and the following *sysfs* attributes.

``svec-vme-<vme-slot>/application_offset`` [R]
  It shows the relative offset (from FPGA base address - resource0) to the
  user application loaded.

``svec-vme-<vme-slot>/pcb_rev`` [R]
  It shows the SVEC carrier PCB revision number.

``svec-vme-<vme-slot>/reset_app`` [R/W]
  It puts in *reset* (1) or *unreset* (0) the user application.

.. _`FPGA manager`: https://www.kernel.org/doc/html/latest/driver-api/fpga/index.html

Attributes From *debugfs*
-------------------------

In addition to standard *debugfs* attributes for VME, `FPGA manager`_,
and `FMC`_ there more SVEC specific *debugfs* attributes.  Here we
focus only on those.

``vme-<vme-slot>/fpga_device_metadata`` [R]
  It dumps the FPGA device metadata information for the
  :ref:`SVEC base<svec_hdl_svec_base>` and, when it exists, the user
  application one.

``vme-<vme-slot>/fpga_firmware`` [W]
  It configure the FPGA with a bitstream which name is provided as input.
  Remember that firmwares are installed in ``/lib/firmware`` and alternatively
  you can provide your own path by setting it in
  ``/sys/module/firmware_class/parameters/path``.

``vme-<vme-slot>/svec-vme-<vme-slot>/csr_regs`` [R]
  It dumps the Control/Status register for
  the :ref:`SVEC base<svec_hdl_svec_base>`

``vme-<vme-slot>/svec-vme-<vme-slot>/build_info`` [R]
  It shows the FPGA configuration synthesis information
