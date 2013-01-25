onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/enable_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/clk_sys_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/rst_n_i
add wave -noupdate -radix hexadecimal -expand -subitemconfig {/main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.csr_start_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.csr_msbf_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.csr_swrst_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.csr_exit_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.csr_clkdiv_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.btrigr_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.btrigr_wr_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.gpior_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.fifo_rd_full_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.fifo_rd_empty_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.fifo_xsize_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.fifo_xlast_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.fifo_xdata_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.far_data_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.far_data_load_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.far_xfer_o {-height 17 -radix hexadecimal} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i.far_cs_o {-height 17 -radix hexadecimal}} /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/regs_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/set_addr_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/addr_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/read_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/data_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/ready_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_cs_n_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_sclk_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_mosi_o
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_miso_i
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_cs
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_cs_muxed
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_start
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_start_host
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_start_muxed
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_wdata
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_wdata_host
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_wdata_muxed
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_rdata
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/spi_ready
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/state
add wave -noupdate -radix hexadecimal /main/DUT/U_Bootloader_Core/U_Flash_Boot_Engine/U_Flash_Controller/ready_int
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {729769000 ps} 0}
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
WaveRestoreZoom {446436072 ps} {1011421928 ps}
