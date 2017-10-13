====
SVEC
====
---------------------------------------------
programming application FPGA
---------------------------------------------

:Author: Federico Vaga <federico.vaga@cern.ch>
:organization: CERN
:Date:   2017-10-12
:Copyright: GNU GPL, version 2 or any later version
:Version: 0.9.0
:Manual section: 4
:Manual group: CERN BECOHT Toolkit


Description
===========
The file ``/dev/svec.[0-N]`` is a character device, usually of mode 0440
and owner root:root. The number ``[0-N]`` represents a *SVEC Module* instance.

It is used to program the *Application FPGA* of a `SVEC module`_ on the VME bus.
The programming procedure consists in taking an FPGA bit-stream from the user
and writing it in the Application FPGA on the SVEC Module.
Once the device has been closed the Application FPGA become active and,
if valid, it will run the FPGA bit-stream provided by the user.

In order to prevent accidental programming, the Application FPGA programming
procedure is protected by the sysfs attribute ``AFPGA/lock``, usually of mode
0644 and owner root:root. On read it returns a string representing the current
locking status. On write it accepts only the strings:

- "unlock" to unlock the programming procedure.
- "lock" to lock the programming procedure

Once the programming procedure has been completed, the device go back to the
locking status.

The complete programming procedure is:

#. unlock the programming procedure by writing "unlock" in ``AFPGA/lock``
#. write the FPGA bit-stream in the character device ``/dev/svec.<N>``

Files
=====

/dev/svec.[0-N]

/sys/bus/vme/device/vme.[0-N]/svec/svec.[0-N]/AFPGA/lock


.. _`SVEC module`: https://www.ohwr.org/projects/svec/


Examples
========

.. code:: sh

    echo "unlock" > /sys/bus/vme/devices/vme.8/svec/svec.8/AFPGA/lock
    dd if=/path/to/bitstream.bin of=/dev/svec.8

.. code:: sh

    echo "unlock" > /sys/bus/vme/devices/vme.8/svec/svec.8/AFPGA/lock
    cat /path/to/bitstream.bin > /dev/svec.8
