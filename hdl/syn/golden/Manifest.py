# SPDX-FileCopyrightText: 2022 CERN (home.cern)
#
# SPDX-License-Identifier: CERN-OHL-W-2.0

target = "xilinx"
action = "synthesis"

# Allow the user to override fetchto using:
#  hdlmake -p "fetchto='xxx'"
if locals().get('fetchto', None) is None:
  fetchto = "../../ip_cores"

syn_device = "xc6slx150t"
syn_grade = "-3"
syn_package = "fgg900"
syn_project = "svec_golden.xise"
syn_tool = "ise"
syn_top = "svec_golden"

board = "svec"
ctrls = ["bank4_64b_32b"]

svec_base_ucf = ['ddr4']

files = [ "buildinfo_pkg.vhd" ]

modules = {
  "local" : [
      "../../top/golden", "../common",
      ],
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

syn_post_project_cmd = "$(TCL_INTERPRETER) syn_extra_steps.tcl $(PROJECT_FILE)"
