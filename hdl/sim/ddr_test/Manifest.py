# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

target = "xilinx"
action = "simulation"

modules = { "local" : ["../../top/ddr_test/",
                       "testbench",
                       "sim_models/2048Mb_ddr3"]}
