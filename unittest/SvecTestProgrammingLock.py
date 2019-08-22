import os
import random
import string
import unittest


class SvecTestProgrammingLock(unittest.TestCase):
    def setUp(self):
        slot = os.environ["VME_SLOT"]
        self.file_path = "/sys/bus/vme/devices/vme.{}/svec/svec.{}/AFPGA/lock".format(slot, slot)
        self.dev_path = "/dev/svec.{}".format(slot)

    def test_01(self):
        """It flips the previous lock status"""
        with open(self.file_path, "r") as f:
            val = f.read().strip()

        for i in range(2):
            new = "lock" if val == "unlocked" else "unlock"
            with open(self.file_path, "w") as f:
                f.write(new)
            with open(self.file_path, "r") as f:
                val = f.read().strip()
            self.assertEqual(val, "{}ed".format(new))

    def test_02(self):
        """It writes invalid commands to the lock attribute"""
        chars = (random.choice(string.ascii_uppercase) for _ in range(3))
        with self.assertRaises(OSError):
            with open(self.file_path) as f:
                f.write(''.join(chars))

    def test_03(self):
        """It unlocks the programming"""
        with open(self.file_path, "w") as f:
            f.write("unlock")
        with open(self.file_path, "r") as f:
            val = f.read().strip()
        self.assertEqual(val, "unlocked")

        # we should be able to open the device
        with open(self.dev_path) as f:
            pass

        # It should lock automatically
        with open(self.file_path, "r") as f:
            val = f.read().strip()
        self.assertEqual(val, "locked")

    def test_04(self):
        """It locks the programming"""
        with open(self.file_path, "w") as f:
            f.write("lock")
        with open(self.file_path, "r") as f:
            val = f.read().strip()
        self.assertEqual(val, "locked")

        # we should not be able to open the device
        with self.assertRaises(OSError):
            f = open(self.dev_path)
