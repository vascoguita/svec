target = "xilinx"
action = "synthesis"

# Allow the user to override fetchto using:
#  hdlmake -p "fetchto='xxx'"
if locals().get('fetchto', None) is None:
  fetchto = "../../ip_cores"

syn_device = "xc6slx150t"
syn_grade = "-3"
syn_package = "fgg900"
syn_project = "svec_golden_wr.xise"
syn_tool = "ise"
syn_top = "svec_golden_wr"

board = "svec"
ctrls = ["bank4_64b_32b"]

svec_template_ucf = ['ddr4', 'wr', 'gpio', 'led']

files = [ "buildinfo_pkg.vhd" ]

modules = {
  "local" : [
      "../../top/golden_wr",
      "../../syn/common",
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
