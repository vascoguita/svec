action = "simulation"
target = "xilinx"
fetchto = "../../ip_cores"
vlog_opt="+incdir+../../sim/vme64x_bfm +incdir+../../sim/wb +incdir+../../sim/regs +incdir+../../sim"

files = [ "main.sv", "glbl.v", "SIM_CONFIG_S6_SERIAL.v" ]

modules = { "local" :  [ "../../top/sfpga_bootloader" ] }

