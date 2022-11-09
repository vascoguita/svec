# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

action = "simulation"
target = "xilinx"
sim_tool = "modelsim"
sim_top = "main"
vcom_opt = "-93 -mixedsvvh"

syn_device = "xc6slx150t"
svec_template_ucf = []
board = "svec"
ctrls = ["bank4_64b_32b"]

# Allow the user to override fetchto using:
#  hdlmake -p "fetchto='xxx'"
if locals().get('fetchto', None) is None:
  fetchto = "../../ip_cores"

include_dirs=[fetchto + "/vme64x-core/hdl/sim/vme64x_bfm", 
              fetchto + "/general-cores/sim"]

files = [ "main.sv", "buildinfo_pkg.vhd" ]

modules = {
  "local" :  [ "../../rtl" ],
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
