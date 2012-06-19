onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/g_interface_mode
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/g_address_granularity
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/clk_sys_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/rst_n_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_cyc_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_stb_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_we_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_adr_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_sel_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_dat_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_dat_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_ack_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_stall_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/xlx_cclk_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/xlx_din_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/xlx_program_b_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/xlx_init_b_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/xlx_done_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/xlx_suspend_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/xlx_m_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/boot_trig_p1_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/boot_exit_p1_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/boot_en_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/gpio_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/state
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/clk_div
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/tick
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/init_b_synced
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/done_synced
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/timeout_counter
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_in
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/wb_out
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/regs_in
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/regs_out
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/d_data
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/d_size
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/d_last
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/bit_counter
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/boot_state
add wave -noupdate -radix hexadecimal /main/DUT/U_Xilinx_Loader/U_Wrapped_XLDR/startup_count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {123219856 ps} 0}
configure wave -namecolwidth 177
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {282492928 ps}
