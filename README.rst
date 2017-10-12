SVEC Driver
===========
This is the simplified version of the SVEC driver which only purpose is
to export an interface to enable the users to program their bitstream on
the SVEC FPGA.

Build Sources
=============
In order to be able to build this SVEC driver you need the VMEBUS sources
at hand, otherwise you cannot compile the kernel sources.

The documentation is written in reStructuredText and it generates HTML files
and man pages. For this you need the python docutils package installed

If the requirements are satified you can run the following commant in
the project root directory:

.. code::

    make VMEBUS=/path/to/vmebus/

Futuristic Vision
=================
Actually this is not a driver for the SVEC card but for that little gateware
core in the SVEC bootloader FPGA. In the future we can think about standardize
other designs around this concept. Then this driver will become the FPGA
programmer driver for a set of devices.
