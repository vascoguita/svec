# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

action = "simulation"
target = "xilinx"
sim_tool = "modelsim"
sim_top = "main"
vcom_opt = "-93 -mixedsvvh"

syn_device = "xc6slx150t"
board = "svec"

ctrls = ["bank4_64b_32b", "bank5_64b_32b"]

# Allow the user to override fetchto using:
#  hdlmake -p "fetchto='xxx'"
if locals().get('fetchto', None) is None:
  fetchto = "../../ip_cores"

# Ideally this should be done by hdlmake itself, to allow downstream Manifests to be able to use the
# fetchto variable independent of where those Manifests reside in the filesystem.
import os
fetchto = os.path.abspath(fetchto)

include_dirs = [
  "../include",
  fetchto + "/vme64x-core/hdl/sim/vme64x_bfm",
  fetchto + "/general-cores/sim",
]

files = [ "main.sv", "buildinfo_pkg.vhd" ]

modules = {
  "local" :  [ "../../top/golden" ],
  "git" : [
      "https://ohwr.org/project/wr-cores.git",
      "https://ohwr.org/project/general-cores.git",
      "https://ohwr.org/project/vme64x-core.git",
      "https://ohwr.org/project/ddr3-sp6-core.git",
  ],
}

# Do not fail during hdlmake fetch
try:
    exec(open(fetchto + "/general-cores/tools/gen_buildinfo.py").read())
except:
    pass
