# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

action = "simulation"
target = "xilinx"
fetchto = "../../ip_cores"
vlog_opt="+incdir+../../sim/vme64x_bfm +incdir+../../sim/wb"

files = [ "main.sv" ]

modules = { "local" :  [ "../../top/golden" ] }

