action = "simulation"
target = "xilinx"
fetchto = "../../ip_cores"
vlog_opt="+incdir+../../sim/vme64x_bfm +incdir+../../sim/wb"

files = [ "main.sv", "glbl.v", "SIM_CONFIG_S6_SERIAL.v" ]

modules = { "local" :  [ "../../top/svec_sfpga" ] }

