onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Pwr-rst /main/DUT/U_Powerup_Reset/clk_sys_i
add wave -noupdate -expand -group Pwr-rst /main/DUT/U_Powerup_Reset/rst_vme_n_a_i
add wave -noupdate -expand -group Pwr-rst /main/DUT/U_Powerup_Reset/rst_local_n_a_i
add wave -noupdate -expand -group Pwr-rst /main/DUT/U_Powerup_Reset/rst_n_o
add wave -noupdate -expand -group Pwr-rst /main/DUT/U_Powerup_Reset/powerup_cnt
add wave -noupdate -expand -group Pwr-rst /main/DUT/U_Powerup_Reset/local_synced_n
add wave -noupdate -expand -group Pwr-rst /main/DUT/U_Powerup_Reset/vme_synced_n
add wave -noupdate -expand -group Pwr-rst /main/DUT/U_Powerup_Reset/powerup_n
add wave -noupdate /main/DUT/lclk_n_i
add wave -noupdate /main/DUT/rst_n_i
add wave -noupdate /main/DUT/VME_AS_n_i
add wave -noupdate /main/DUT/VME_RST_n_i
add wave -noupdate /main/DUT/VME_WRITE_n_i
add wave -noupdate /main/DUT/VME_AM_i
add wave -noupdate /main/DUT/VME_DS_n_i
add wave -noupdate /main/DUT/VME_GA_i
add wave -noupdate /main/DUT/VME_DTACK_n_o
add wave -noupdate /main/DUT/VME_LWORD_n_b
add wave -noupdate /main/DUT/VME_ADDR_b
add wave -noupdate /main/DUT/VME_DATA_b
add wave -noupdate /main/DUT/VME_DTACK_OE_o
add wave -noupdate /main/DUT/VME_DATA_DIR_o
add wave -noupdate /main/DUT/VME_DATA_OE_N_o
add wave -noupdate /main/DUT/VME_ADDR_DIR_o
add wave -noupdate /main/DUT/VME_ADDR_OE_N_o
add wave -noupdate /main/DUT/VME_BBSY_n_i
add wave -noupdate /main/DUT/boot_clk_o
add wave -noupdate /main/DUT/boot_config_o
add wave -noupdate /main/DUT/boot_done_i
add wave -noupdate /main/DUT/boot_dout_o
add wave -noupdate /main/DUT/boot_status_i
add wave -noupdate /main/DUT/spi_cs_n_o
add wave -noupdate /main/DUT/spi_mosi_o
add wave -noupdate /main/DUT/spi_miso_i
add wave -noupdate /main/DUT/spi_sclk_o
add wave -noupdate /main/DUT/debugled_o
add wave -noupdate /main/DUT/pll_ce_o
add wave -noupdate /main/DUT/VME_DATA_o_int
add wave -noupdate /main/DUT/vme_dtack_oe_int
add wave -noupdate /main/DUT/VME_DTACK_n_int
add wave -noupdate /main/DUT/vme_data_dir_int
add wave -noupdate /main/DUT/VME_DATA_OE_N_int
add wave -noupdate /main/DUT/wb_vme_in
add wave -noupdate /main/DUT/wb_vme_out
add wave -noupdate /main/DUT/passive
add wave -noupdate /main/DUT/boot_en
add wave -noupdate /main/DUT/boot_trig_p1
add wave -noupdate /main/DUT/boot_exit_p1
add wave -noupdate /main/DUT/CONTROL
add wave -noupdate /main/DUT/CLK
add wave -noupdate /main/DUT/TRIG0
add wave -noupdate /main/DUT/TRIG1
add wave -noupdate /main/DUT/TRIG2
add wave -noupdate /main/DUT/TRIG3
add wave -noupdate /main/DUT/boot_config_int
add wave -noupdate /main/DUT/erase_afpga_n
add wave -noupdate /main/DUT/erase_afpga_n_d0
add wave -noupdate /main/DUT/pllout_clk_fb_sys
add wave -noupdate /main/DUT/pllout_clk_sys
add wave -noupdate /main/DUT/clk_sys
add wave -noupdate /main/DUT/rst_n_sys
add wave -noupdate /main/DUT/go_passive
add wave -noupdate /main/DUT/vme_idle
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2145098 ps} 0}
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
WaveRestoreZoom {0 ps} {17655808 ps}
