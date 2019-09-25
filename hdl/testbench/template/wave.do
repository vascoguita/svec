onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/vme_write_n_i
add wave -noupdate /main/DUT/vme_sysreset_n_i
add wave -noupdate /main/DUT/vme_retry_oe_o
add wave -noupdate /main/DUT/vme_retry_n_o
add wave -noupdate /main/DUT/vme_lword_n_b
add wave -noupdate /main/DUT/vme_iackout_n_o
add wave -noupdate /main/DUT/vme_iackin_n_i
add wave -noupdate /main/DUT/vme_iack_n_i
add wave -noupdate /main/DUT/vme_gap_i
add wave -noupdate /main/DUT/vme_dtack_oe_o
add wave -noupdate /main/DUT/vme_dtack_n_o
add wave -noupdate /main/DUT/vme_ds_n_i
add wave -noupdate /main/DUT/vme_data_oe_n_o
add wave -noupdate /main/DUT/vme_data_dir_o
add wave -noupdate /main/DUT/vme_berr_o
add wave -noupdate /main/DUT/vme_as_n_i
add wave -noupdate /main/DUT/vme_addr_oe_n_o
add wave -noupdate /main/DUT/vme_addr_dir_o
add wave -noupdate /main/DUT/vme_irq_o
add wave -noupdate /main/DUT/vme_ga_i
add wave -noupdate /main/DUT/vme_data_b
add wave -noupdate /main/DUT/vme_am_i
add wave -noupdate /main/DUT/vme_addr_b
add wave -noupdate -expand /main/DUT/vme_wb_out
add wave -noupdate -expand /main/DUT/vme_wb_in
add wave -noupdate /main/rst_n
add wave -noupdate -divider ddr
add wave -noupdate /main/DUT/ddr4_calib_done
add wave -noupdate /main/DUT/csr_ddr4_addr_out
add wave -noupdate /main/DUT/csr_ddr4_addr_wr
add wave -noupdate /main/DUT/csr_ddr4_addr
add wave -noupdate /main/DUT/csr_ddr4_data_in
add wave -noupdate /main/DUT/csr_ddr4_data_out
add wave -noupdate /main/DUT/csr_ddr4_data_wr
add wave -noupdate /main/DUT/csr_ddr4_data_rd
add wave -noupdate /main/DUT/csr_ddr4_data_wack
add wave -noupdate /main/DUT/csr_ddr4_data_rack
add wave -noupdate /main/DUT/ddr4_read_ip
add wave -noupdate /main/DUT/ddr4_write_ip
add wave -noupdate -expand /main/DUT/ddr4_wb_out
add wave -noupdate /main/DUT/ddr4_wb_in
add wave -noupdate /main/DUT/inst_carrier/rd_int
add wave -noupdate /main/DUT/cmp_vme_core/inst_vme_bus/s_mainFSMstate
add wave -noupdate /main/DUT/cmp_vme_core/inst_vme_bus/s_dataPhase
add wave -noupdate /main/DUT/cmp_vme_core/inst_vme_bus/stall_d
add wave -noupdate /main/DUT/cmp_vme_core/inst_vme_bus/wb_stall_i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9332000000 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 206
configure wave -valuecolwidth 100
configure wave -justifyvalue right
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
WaveRestoreZoom {9216871530 fs} {10041217290 fs}
