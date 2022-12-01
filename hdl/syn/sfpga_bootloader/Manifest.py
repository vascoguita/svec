# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

target = "xilinx"
action = "synthesis"

fetchto = "../../ip_cores"

syn_device = "xc6slx9"
syn_grade = "-2"
syn_package = "ftg256"
syn_top = "svec_sfpga_top"
syn_project = "svec_sfpga.xise"
syn_tool = "ise"

modules = {
    "local" : [
        "../../top/sfpga_bootloader",
    ],
}
