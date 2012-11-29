action = "simulation"
target = "xilinx"
fetchto = "../../ip_cores"
vlog_opt="+incdir+../../sim/vme64x_bfm +incdir+../../sim/wb"

files = [ "main.sv" ]

modules = { "local" :  [ "../../top/golden" ] }

