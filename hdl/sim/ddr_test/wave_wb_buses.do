onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /vme64x_ddr_tb/rst_n_i
add wave -noupdate /vme64x_ddr_tb/VME_RST_n_i
add wave -noupdate /vme64x_ddr_tb/uut/sys_rst_n
add wave -noupdate /vme64x_ddr_tb/clk_i
add wave -noupdate -divider VME
add wave -noupdate /vme64x_ddr_tb/VME_BERR_o
add wave -noupdate /vme64x_ddr_tb/VME_DS_n_i
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/VME_DATA_b
add wave -noupdate /vme64x_ddr_tb/VME_AS_n_i
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/VME_ADDR_b
add wave -noupdate /vme64x_ddr_tb/VME_LWORD_n_b
add wave -noupdate /vme64x_ddr_tb/VME_WRITE_n_i
add wave -noupdate /vme64x_ddr_tb/VME_DTACK_n_o
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/s_dataToReceive
add wave -noupdate -divider {Master WB}
add wave -noupdate /vme64x_ddr_tb/uut/wbm_we
add wave -noupdate /vme64x_ddr_tb/uut/wbm_stb
add wave -noupdate /vme64x_ddr_tb/uut/wbm_stall
add wave -noupdate /vme64x_ddr_tb/uut/wbm_sel
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/uut/wbm_dat_o
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/uut/wbm_dat_i
add wave -noupdate /vme64x_ddr_tb/uut/wbm_cyc
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/uut/wbm_adr
add wave -noupdate /vme64x_ddr_tb/uut/wbm_ack
add wave -noupdate -divider {Slaves WB}
add wave -noupdate /vme64x_ddr_tb/uut/wb_we
add wave -noupdate /vme64x_ddr_tb/uut/wb_stb
add wave -noupdate /vme64x_ddr_tb/uut/wb_stall
add wave -noupdate /vme64x_ddr_tb/uut/wb_sel
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/uut/wb_dat_o
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/uut/wb_dat_i
add wave -noupdate /vme64x_ddr_tb/uut/wb_cyc
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/uut/wb_adr
add wave -noupdate /vme64x_ddr_tb/uut/wb_ack
add wave -noupdate -divider DDR
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_we_i
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_we_f_edge
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_we_d
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_stb_i
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_stb_f_edge
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_stb_d
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_cyc_r_edge
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_cyc_i
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_cyc_f_edge
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/wb_cyc_d
add wave -noupdate /vme64x_ddr_tb/uut/ddr3_bank5_status(0)
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/ddr_wr_en
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/ddr_wr_data
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/ddr_rd_en
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/ddr_rd_data_i
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/ddr_cmd_instr
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/ddr_cmd_en
add wave -noupdate -radix hexadecimal /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/ddr_cmd_byte_addr
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/ddr_cmd_bl
add wave -noupdate /vme64x_ddr_tb/uut/cmp_ddr_ctrl_bank5/cmp_ddr3_ctrl_wb_0/ddr_burst_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {17089000 ps} 0}
configure wave -namecolwidth 520
configure wave -valuecolwidth 203
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {16585011 ps} {17481412 ps}
