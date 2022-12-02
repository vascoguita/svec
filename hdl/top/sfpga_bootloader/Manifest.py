# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0+

files = [
    "svec_sfpga_top.vhd",
    "reset_gen.vhd",
]

modules = {
    "local" : [
        "../../rtl/bootloader",
    ],
}
