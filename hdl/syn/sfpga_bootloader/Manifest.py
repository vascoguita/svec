target = "xilinx"
action = "synthesis"

fetchto = "../../ip_cores"

syn_device = "xc6slx9"
syn_grade = "-2"
syn_package = "ftg256"
syn_top = "svec_sfpga_top"
syn_project = "svec_sfpga.xise"

modules = { "local" : [ "../../top/sfpga_bootloader", "../../platform" ] }
