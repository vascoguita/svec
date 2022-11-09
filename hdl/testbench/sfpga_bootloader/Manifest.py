# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

action = "simulation"
target = "xilinx"
fetchto = "../../ip_cores"
vlog_opt="+incdir+../../sim/vme64x_bfm +incdir+../../sim/flash/include +incdir+../../sim/wb +incdir+../../sim/regs +incdir+../../sim"

files = [ "main.sv", "glbl.v", "SIM_CONFIG_S6_SERIAL.v", "../../sim/flash/M25P128.v" ]

modules = { "local" :  [ "../../top/sfpga_bootloader" ] }

