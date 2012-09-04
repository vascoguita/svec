vsim -novopt -t 1ps vme64x_ddr_tb
log -r /*
do wave_wb_buses.do

view wave
view transcript

run 50 us


