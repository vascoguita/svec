# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: LGPL-2.1-or-later

import os
import unittest


class SvecTestProgramming(unittest.TestCase):
    def setUp(self):
        slot = os.environ["VME_SLOT"]
        self.file_path = "/sys/bus/vme/devices/vme.{}/svec/svec.{}/AFPGA/lock".format(slot, slot)
        self.dev_path = "/dev/svec.{}".format(slot)
        self.bitstream = os.environ["BITSTREAM"]

    def test_01(self):
        """It writes a dummy FPGA bitstream"""
        with open(self.file_path, "w") as f:
            f.write("unlock")

        with open(self.bitstream, "rb") as d:
            with open(self.dev_path, "wb") as f:
                f.write(d.read())

        with open(self.file_path, "r") as f:
            val = f.read().strip()
        self.assertEqual(val, "locked")
