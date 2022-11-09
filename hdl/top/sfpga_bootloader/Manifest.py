# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

files = [ "svec_sfpga_top.vhd", "svec_sfpga_top.ucf", "reset_gen.vhd" ]

fetchto = "../../ip_cores"

modules = {
    "local" : ["../../rtl/bootloader" ],
    "git" : [ "git://ohwr.org/hdl-core-lib/general-cores.git" ]
    }
