SVEC Driver(s)
==============

There are drivers for the SVEC card and there are drivers for the
:ref:`SVEC base<svec_hdl_svec_base>` component. All these drivers are
managed by:

SVEC FMC Carrier
  This is the driver that wrap up all the physical components and the
  :ref:`SVEC base<svec_hdl_svec_base>` ones. It configures the card so
  that all components cooperate correctly. It also export an
  `FPGA manager interface`_.

If the SVEC based application is using the :ref:`SVEC
base<svec_hdl_svec_base>` component then it can profit from the
following driver. They are not all mandatory, it depends on the
application, and most of them are distributed separately:

I2C OCORE
  This is the driver for the I2C OCORE IP-core. It is used to communicate with
  the standard FMC EEPROM available what on FMC modules. The driver is
  available in Linux.

SPI OCORE
  This is the driver for the SPI OCORE IP-core. It is used to communicate with
  the M25P32 FLASH memory where FPGA bitstreams are stored. The driver is
  distributed separately.

VIC
  The driver for the VIC interrupt controller IP-core. The driver is
  distributed separately.

.. _`SVEC project`: https://ohwr.org/project/svec
.. _`GPIO interface`: https://www.kernel.org/doc/html/latest/driver-api/gpio/index.html
.. _`FPGA manager interface`: https://www.kernel.org/doc/html/latest/driver-api/fpga/index.html
.. _`DMA Engine`: https://www.kernel.org/doc/html/latest/driver-api/dmaengine/index.html~
