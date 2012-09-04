--------------------------------------------------------------------------------
-- CERN (BE-CO-HT)
-- Top level entity for Simple VME FMC Carrier (SVEC) Application FPGA
-- http://www.ohwr.org/projects/svec
--------------------------------------------------------------------------------
--
-- unit name: svec_afpga_top
--
-- author: Matthieu Cattin (matthieu.cattin@cern.ch)
--
-- date: 14-06-2012
--
-- version: 1.0
--
-- description: Generic top level entity for the application FPGA of the
--              Simple VME FMC Carrier (SVEC).
--
-- dependencies:
--
--------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--------------------------------------------------------------------------------
-- This source file is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Lesser General Public License as published by the
-- Free Software Foundation; either version 2.1 of the License, or (at your
-- option) any later version. This source is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
-- of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU Lesser General Public License for more details. You should have
-- received a copy of the GNU Lesser General Public License along with this
-- source; if not, download it from http://www.gnu.org/licenses/lgpl-2.1.html
--------------------------------------------------------------------------------
-- last changes: see log.
--------------------------------------------------------------------------------
-- TODO: - 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library UNISIM;
use UNISIM.vcomponents.all;

library work;
use work.ddr3_ctrl_pkg.all;
use work.wishbone_pkg.all;
use work.vme64x_pack.all;
use work.genram_pkg.all;

entity svec_afpga_top is
  generic(
    g_CARRIER_TYPE   : std_logic_vector(15 downto 0) := X"0002";
    g_BITSTREAM_TYPE : std_logic_vector(31 downto 0) := X"00002222";
    g_BITSTREAM_DATE : std_logic_vector(31 downto 0) := X"4FE9BABD";
    g_SIMULATION     : string                        := "FALSE";
    g_CALIB_SOFT_IP  : string                        := "TRUE");
  port
    (

      ------------------------------------------
      -- VME interface
      ------------------------------------------
      vme_write_n_i    : in    std_logic;
      vme_sysreset_n_i : in    std_logic;
--      vme_sysclk_i     : in    std_logic;
      vme_retry_oe_o   : out   std_logic;
      vme_retry_n_o    : out   std_logic;
      vme_lword_n_b    : inout std_logic;
      vme_iackout_n_o  : out   std_logic;
      vme_iackin_n_i   : in    std_logic;
      vme_iack_n_i     : in    std_logic;
      vme_gap_n_i      : in    std_logic;
      vme_dtack_oe_o   : out   std_logic;
      vme_dtack_n_o    : out   std_logic;
      vme_ds_n_i       : in    std_logic_vector(1 downto 0);
      vme_d_oe_n_o     : out   std_logic;
      vme_d_dir_o      : out   std_logic;
      vme_berr_o       : out   std_logic;
      vme_as_n_i       : in    std_logic;
      vme_a_oe_n_o     : out   std_logic;
      vme_a_dir_o      : out   std_logic;
      vme_irq_n_o      : out   std_logic_vector(7 downto 1);
      vme_ga_i         : in    std_logic_vector(4 downto 0);
      vme_d_b          : inout std_logic_vector(31 downto 0);
      vme_am_i         : in    std_logic_vector(5 downto 0);
      vme_a_b          : inout std_logic_vector(31 downto 1);

      ------------------------------------------
      -- Clock and reset inputs
      ------------------------------------------
      rst_n_i : in std_logic;

      clk20_vcxo_i : in std_logic;
--      fpga_clk_n_i   : in std_logic;
--      fpga_clk_p_i   : in std_logic;
--      si57x_clk_n_i  : in std_logic;
--      si57x_clk_p_i  : in std_logic;
--      pll_2afpga_n_i : in std_logic;
--      pll_2afpga_p_i : in std_logic;

      ------------------------------------------
      -- Switches and button
      ------------------------------------------
--      pushbutton_i : in std_logic;
--      noga_i       : in std_logic_vector(4 downto 0);
--      switch_i     : in std_logic_vector(1 downto 0);
--      usega_i      : in std_logic;

      ------------------------------------------
      -- Inter-FPGA lines
      ------------------------------------------
--      rsvd_b : inout std_logic_vector(7 downto 0);

      ------------------------------------------
      -- PCB revision
      ------------------------------------------
      pcbrev_i : in std_logic_vector(4 downto 0);

      ------------------------------------------
      -- SFP slot
      ------------------------------------------
--      sfprx_123_n_i : in  std_logic;
--      sfprx_123_p_i : in  std_logic;
--      sfptx_123_n_o : out std_logic;
--      sfptx_123_p_o : out std_logic;
--      gtp_ck1_p_i   : in  std_logic;
--      gtp_ck1_n_i   : in  std_logic;

--      wr_los_i        : in    std_logic;
--      wr_moddef0_i    : in    std_logic;
--      wr_moddef1_o    : out   std_logic;
--      wr_moddef2_b    : inout std_logic;
--      wr_rateselect_o : out   std_logic;
--      wr_txdisable_o  : out   std_logic;
--      wr_txfault_i    : in    std_logic;

      ------------------------------------------
      -- SATA connectors
      ------------------------------------------
--      sata1_tx_p_o : out std_logic;
--      sata1_tx_n_o : out std_logic;
--      sata1_rx_p_i : in  std_logic;
--      sata1_rx_n_i : in  std_logic;
--      sata0_tx_p_o : out std_logic;
--      sata0_tx_n_o : out std_logic;
--      sata0_rx_p_i : in  std_logic;
--      sata0_rx_n_i : in  std_logic;
--      gtp_ck0_p_i  : in  std_logic;
--      gtp_ck0_n_i  : in  std_logic;

      ------------------------------------------
      -- PCIe interface (optional)
      ------------------------------------------
--      pcie_tx1_p_o        : out std_logic;
--      pcie_tx1_n_o        : out std_logic;
--      pcie_rx1_p_i        : in  std_logic;
--      pcie_rx1_n_i        : in  std_logic;
--      pcie_master_clk_p_i : in  std_logic;
--      pcie_master_clk_n_i : in  std_logic;

      ------------------------------------------
      -- Clock controls
      ------------------------------------------
--      oe_si57x_o   : out   std_logic;
--      si57x_scl_o  : out   std_logic;
--      si57x_sda_b  : inout std_logic;
--      si57x_tune_o : out   std_logic;   -- (optional)

--      pll20dac_din_o    : out std_logic;
--      pll20dac_sclk_o   : out std_logic;
--      pll20dac_sync_n_o : out std_logic;
--      pll25dac_din_o    : out std_logic;
--      pll25dac_sclk_o   : out std_logic;
--      pll25dac_sync_n_o : out std_logic;

      ------------------------------------------
      -- UART
      ------------------------------------------
--      uart_rxd_o : out std_logic;
--      uart_txd_i : in  std_logic;

      ------------------------------------------
      -- USB (optional)
      ------------------------------------------
--      usb_clkout_i : in    std_logic;
--      usb_oe_n_o   : out   std_logic;
--      usb_rd_n_o   : out   std_logic;
--      usb_rxf_n_i  : in    std_logic;
--      usb_siwua_i  : in    std_logic;
--      usb_txe_n_i  : in    std_logic;
--      usb_wr_n_o   : out   std_logic;
--      usb_d_b      : inout std_logic_vector(7 downto 0);
--      io7_i        : in    std_logic;

      ------------------------------------------
      -- VME P2
      ------------------------------------------
--      p2_data_p_b : inout std_logic_vector(19 downto 0);
--      p2_data_n_b : inout std_logic_vector(19 downto 0);

      ------------------------------------------
      -- DDR3 (bank 4)
      ------------------------------------------
      ddr_we_n_o    : out   std_logic;
      ddr_udqs_p_b  : inout std_logic;
      ddr_udqs_n_b  : inout std_logic;
      ddr_udm_o     : out   std_logic;
      ddr_reset_n_o : out   std_logic;
      ddr_ras_n_o   : out   std_logic;
      ddr_odt_o     : out   std_logic;
      ddr_ldqs_p_b  : inout std_logic;
      ddr_ldqs_n_b  : inout std_logic;
      ddr_ldm_o     : out   std_logic;
      ddr_cke_o     : out   std_logic;
      ddr_ck_p_o    : out   std_logic;
      ddr_ck_n_o    : out   std_logic;
      ddr_cas_n_o   : out   std_logic;
      ddr_dq_b      : inout std_logic_vector(15 downto 0);
      ddr_ba_o      : out   std_logic_vector(2 downto 0);
      ddr_a_o       : out   std_logic_vector(13 downto 0);
      ddr_zio_b     : inout std_logic;
      ddr_rzq_b     : inout std_logic;

      ------------------------------------------
      -- DDR3 (bank 5)
      ------------------------------------------
      ddr_2_we_n_o    : out   std_logic;
      ddr_2_udqs_p_b  : inout std_logic;
      ddr_2_udqs_n_b  : inout std_logic;
      ddr_2_udm_o     : out   std_logic;
      ddr_2_reset_n_o : out   std_logic;
      ddr_2_ras_n_o   : out   std_logic;
      ddr_2_odt_o     : out   std_logic;
      ddr_2_ldqs_p_b  : inout std_logic;
      ddr_2_ldqs_n_b  : inout std_logic;
      ddr_2_ldm_o     : out   std_logic;
      ddr_2_cke_o     : out   std_logic;
      ddr_2_ck_p_o    : out   std_logic;
      ddr_2_ck_n_o    : out   std_logic;
      ddr_2_cas_n_o   : out   std_logic;
      ddr_2_dq_b      : inout std_logic_vector(15 downto 0);
      ddr_2_ba_o      : out   std_logic_vector(2 downto 0);
      ddr_2_a_o       : out   std_logic_vector(13 downto 0);
      ddr_2_zio_b     : inout std_logic;
      ddr_2_rzq_b     : inout std_logic;

      ------------------------------------------
      -- FMC slot 1
      ------------------------------------------
--      fmc1_gbtclk0m2c_p_i : in  std_logic;
--      fmc1_gbtclk0m2c_n_i : in  std_logic;
--      fmc1_dp0m2c_p_i     : in  std_logic;
--      fmc1_dp0m2c_n_i     : in  std_logic;
--      fmc1_dp0c2m_p_o     : out std_logic;
--      fmc1_dp0c2m_n_o     : out std_logic;

--      fmc1_pg_c2m_o     : out   std_logic;
      fmc1_prsntm2c_n_i : in std_logic;
--      fmc1_scl_o        : out   std_logic;
--      fmc1_sda_b        : inout std_logic;
--      fmc1_tck_o        : out   std_logic;
--      fmc1_tdi_i        : in    std_logic;
--      fmc1_tdo_o        : out   std_logic;
--      fmc1_tms_o        : out   std_logic;
--      fmc1_clk1m2c_p_i  : in    std_logic;
--      fmc1_clk1m2c_n_i  : in    std_logic;
--      fmc1_clk0m2c_p_i  : in    std_logic;
--      fmc1_clk0m2c_n_I  : in    std_logic;
--      fmc1_la_p_b       : inout std_logic_vector(33 downto 0);
--      fmc1_la_n_b       : inout std_logic_vector(33 downto 0);

      ------------------------------------------
      -- FMC slot 2
      ------------------------------------------
--      fmc2_gbtclk0m2c_p_i : in  std_logic;
--      fmc2_gbtclk0m2c_n_i : in  std_logic;
--      fmc2_dp0m2c_p_i     : in  std_logic;
--      fmc2_dp0m2c_n_i     : in  std_logic;
--      fmc2_dp0c2m_p_o     : out std_logic;
--      fmc2_dp0c2m_n_o     : out std_logic;

--      fmc2_pg_c2m_o     : out   std_logic;
      fmc2_prsntm2c_n_i : in std_logic;
--      fmc2_scl_o        : out   std_logic;
--      fmc2_sda_b        : inout std_logic;
--      fmc2_tck_o        : out   std_logic;
--      fmc2_tdi_i        : in    std_logic;
--      fmc2_tdo_o        : out   std_logic;
--      fmc2_tms_o        : out   std_logic;
--      fmc2_clk1m2c_p_i  : in    std_logic;
--      fmc2_clk1m2c_n_i  : in    std_logic;
--      fmc2_clk0m2c_p_i  : in    std_logic;
--      fmc2_clk0m2c_n_i  : in    std_logic;
--      fmc2_la_p_b       : inout std_logic_vector(33 downto 0);
--      fmc2_la_n_b       : inout std_logic_vector(33 downto 0);

      ------------------------------------------
      -- I2C EEPROM
      ------------------------------------------
--      scl_afpga_o : out   std_logic;
--      sda_afpga_b : inout std_logic;

      ------------------------------------------
      -- Front panel IO and LEDs
      ------------------------------------------
      fp_gpio_b : inout std_logic_vector(4 downto 1);

      fpgpio1_a2b_o  : out std_logic;
      fpgpio2_a2b_o  : out std_logic;
      fpgpio34_a2b_o : out std_logic;

      term_en_o : out std_logic_vector(4 downto 1);

      fp_led_n_o : out std_logic_vector(7 downto 0);

      ------------------------------------------
      -- 1-wire thermoeter + unique ID
      ------------------------------------------
      tempid_dq_b : inout std_logic;

      ------------------------------------------
      -- Debug LEDs
      ------------------------------------------
      dbg_led_n_o : out std_logic_vector(4 downto 1)

      );
end svec_afpga_top;



architecture rtl of svec_afpga_top is


  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------
  component VME64xCore_Top
    generic(
      g_width      : integer := c_width;
      g_addr_width : integer := c_addr_width;
      g_CRAM_SIZE  : integer := c_CRAM_SIZE
      );
    port(
      clk_i           : in  std_logic;
      reset_o         : out std_logic;
      VME_AS_n_i      : in  std_logic;
      VME_RST_n_i     : in  std_logic;
      VME_WRITE_n_i   : in  std_logic;
      VME_AM_i        : in  std_logic_vector(5 downto 0);
      VME_DS_n_i      : in  std_logic_vector(1 downto 0);
      VME_GA_i        : in  std_logic_vector(5 downto 0);
      VME_BERR_o      : out std_logic;
      VME_DTACK_n_o   : out std_logic;
      VME_RETRY_n_o   : out std_logic;
      VME_LWORD_n_b_i : in  std_logic;
      VME_LWORD_n_b_o : out std_logic;
      VME_ADDR_b_i    : in  std_logic_vector(31 downto 1);
      VME_ADDR_b_o    : out std_logic_vector(31 downto 1);
      VME_DATA_b_i    : in  std_logic_vector(31 downto 0);
      VME_DATA_b_o    : out std_logic_vector(31 downto 0);
      VME_IRQ_n_o     : out std_logic_vector(6 downto 0);
      VME_IACKIN_n_i  : in  std_logic;
      VME_IACK_n_i    : in  std_logic;
      VME_IACKOUT_n_o : out std_logic;
      VME_DTACK_OE_o  : out std_logic;
      VME_DATA_DIR_o  : out std_logic;
      VME_DATA_OE_N_o : out std_logic;
      VME_ADDR_DIR_o  : out std_logic;
      VME_ADDR_OE_N_o : out std_logic;
      VME_RETRY_OE_o  : out std_logic;
      DAT_i           : in  std_logic_vector(g_width - 1 downto 0);
      DAT_o           : out std_logic_vector(g_width - 1 downto 0);
      ADR_o           : out std_logic_vector(g_addr_width - 1 downto 0);
      CYC_o           : out std_logic;
      ERR_i           : in  std_logic;
      RTY_i           : in  std_logic;
      SEL_o           : out std_logic_vector(f_div8(g_width) - 1 downto 0);
      STB_o           : out std_logic;
      ACK_i           : in  std_logic;
      WE_o            : out std_logic;
      STALL_i         : in  std_logic;
      INT_ack         : out std_logic;
      IRQ_i           : in  std_logic;
      leds            : out std_logic_vector(7 downto 0)
      );
  end component;

  component wb_addr_decoder
    generic
      (
        g_WINDOW_SIZE  : integer := 18;  -- Number of bits to address periph on the board (32-bit word address)
        g_WB_SLAVES_NB : integer := 2
        );
    port
      (
        ---------------------------------------------------------
        -- GN4124 core clock and reset
        clk_i   : in std_logic;
        rst_n_i : in std_logic;

        ---------------------------------------------------------
        -- wishbone master interface
        wbm_adr_i   : in  std_logic_vector(31 downto 0);  -- Address
        wbm_dat_i   : in  std_logic_vector(31 downto 0);  -- Data out
        wbm_sel_i   : in  std_logic_vector(3 downto 0);   -- Byte select
        wbm_stb_i   : in  std_logic;                      -- Strobe
        wbm_we_i    : in  std_logic;                      -- Write
        wbm_cyc_i   : in  std_logic;                      -- Cycle
        wbm_dat_o   : out std_logic_vector(31 downto 0);  -- Data in
        wbm_ack_o   : out std_logic;                      -- Acknowledge
        wbm_stall_o : out std_logic;                      -- Stall

        ---------------------------------------------------------
        -- wishbone slaves interface
        wb_adr_o   : out std_logic_vector(31 downto 0);                     -- Address
        wb_dat_o   : out std_logic_vector(31 downto 0);                     -- Data out
        wb_sel_o   : out std_logic_vector(3 downto 0);                      -- Byte select
        wb_stb_o   : out std_logic;                                         -- Strobe
        wb_we_o    : out std_logic;                                         -- Write
        wb_cyc_o   : out std_logic_vector(g_WB_SLAVES_NB-1 downto 0);       -- Cycle
        wb_dat_i   : in  std_logic_vector((32*g_WB_SLAVES_NB)-1 downto 0);  -- Data in
        wb_ack_i   : in  std_logic_vector(g_WB_SLAVES_NB-1 downto 0);       -- Acknowledge
        wb_stall_i : in  std_logic_vector(g_WB_SLAVES_NB-1 downto 0)        -- Stall
        );
  end component wb_addr_decoder;

  component csr
    port (
      rst_n_i                        : in  std_logic;
      wb_clk_i                       : in  std_logic;
      wb_addr_i                      : in  std_logic_vector(2 downto 0);
      wb_data_i                      : in  std_logic_vector(31 downto 0);
      wb_data_o                      : out std_logic_vector(31 downto 0);
      wb_cyc_i                       : in  std_logic;
      wb_sel_i                       : in  std_logic_vector(3 downto 0);
      wb_stb_i                       : in  std_logic;
      wb_we_i                        : in  std_logic;
      wb_ack_o                       : out std_logic;
      csr_carrier_pcb_rev_i          : in  std_logic_vector(4 downto 0);
      csr_carrier_reserved_i         : in  std_logic_vector(10 downto 0);
      csr_carrier_type_i             : in  std_logic_vector(15 downto 0);
      csr_bitstream_type_i           : in  std_logic_vector(31 downto 0);
      csr_bitstream_date_i           : in  std_logic_vector(31 downto 0);
      csr_stat_fmc1_pres_i           : in  std_logic;
      csr_stat_fmc2_pres_i           : in  std_logic;
      csr_stat_sys_pll_lck_i         : in  std_logic;
      csr_stat_ddr3_bank4_cal_done_i : in  std_logic;
      csr_stat_ddr3_bank5_cal_done_i : in  std_logic;
      csr_stat_gpio_in_i             : in  std_logic_vector(3 downto 0);
      csr_stat_reserved_i            : in  std_logic_vector(22 downto 0);
      csr_ctrl_fp_leds_o             : out std_logic_vector(7 downto 0);
      csr_ctrl_dbg_leds_o            : out std_logic_vector(3 downto 0);
      csr_ctrl_gpio_term_o           : out std_logic_vector(3 downto 0);
      csr_ctrl_gpio_1_dir_o          : out std_logic;
      csr_ctrl_gpio_2_dir_o          : out std_logic;
      csr_ctrl_gpio_34_dir_o         : out std_logic;
      csr_ctrl_gpio_out_o            : out std_logic_vector(3 downto 0);
      csr_ctrl_reserved_o            : out std_logic_vector(8 downto 0)
      );
  end component csr;


  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  constant c_WB_SLAVES_NB : integer := 4;

  constant c_WB_CSR       : integer := 0;
  constant c_ONEWIRE      : integer := 1;
  constant c_WB_DDR_BANK4 : integer := 2;
  constant c_WB_DDR_BANK5 : integer := 3;

  constant c_ONEWIRE_NB : integer := 1;


  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------

  -- Reset
  signal sys_rst_n : std_logic;
  signal sys_rst   : std_logic;

  -- Clock
  signal clk_in         : std_logic;
  signal clk_pll_locked : std_logic;

  -- System clock
  signal sys_clk            : std_logic;
  signal sys_clk_62_buf     : std_logic;
  signal sys_clk_125_buf    : std_logic;
  signal sys_clk_250_buf    : std_logic;
  signal sys_clk_62         : std_logic;
  signal sys_clk_125        : std_logic;
  signal sys_clk_250        : std_logic;
  signal sys_clk_fb         : std_logic;
  signal sys_clk_pll_locked : std_logic;

  -- DDR3 clock
  signal ddr_clk            : std_logic;
  signal ddr_clk_buf        : std_logic;
  signal ddr_clk_fb         : std_logic;
  signal ddr_clk_pll_locked : std_logic;

  -- VME interface
  signal vme_lword_n_i : std_logic;
  signal vme_lword_n_o : std_logic;
  signal vme_a_i       : std_logic_vector(31 downto 1);
  signal vme_a_o       : std_logic_vector(31 downto 1);
  signal vme_a_dir     : std_logic;
  signal vme_d_i       : std_logic_vector(31 downto 0);
  signal vme_d_o       : std_logic_vector(31 downto 0);
  signal vme_d_dir     : std_logic;
  signal vme_ga        : std_logic_vector(5 downto 0);

  -- Wishbone bus (master -> address decoder)
  signal wbm_adr   : std_logic_vector(31 downto 0);
  signal wbm_dat_i : std_logic_vector(31 downto 0);
  signal wbm_dat_o : std_logic_vector(31 downto 0);
  signal wbm_sel   : std_logic_vector(3 downto 0);
  signal wbm_cyc   : std_logic;
  signal wbm_stb   : std_logic;
  signal wbm_we    : std_logic;
  signal wbm_ack   : std_logic;
  signal wbm_stall : std_logic;

  -- Wishbone bus (address decoder -> slaves)
  signal wb_adr   : std_logic_vector(31 downto 0);
  signal wb_dat_i : std_logic_vector((32*c_WB_SLAVES_NB)-1 downto 0);
  signal wb_dat_o : std_logic_vector(31 downto 0);
  signal wb_sel   : std_logic_vector(3 downto 0);
  signal wb_cyc   : std_logic_vector(c_WB_SLAVES_NB-1 downto 0);
  signal wb_stb   : std_logic;
  signal wb_we    : std_logic;
  signal wb_ack   : std_logic_vector(c_WB_SLAVES_NB-1 downto 0);
  signal wb_stall : std_logic_vector(c_WB_SLAVES_NB-1 downto 0);

  -- GPIO
  signal gpio_1_dir  : std_logic;
  signal gpio_2_dir  : std_logic;
  signal gpio_34_dir : std_logic;
  signal gpio_out    : std_logic_vector(4 downto 1);
  signal gpio_in     : std_logic_vector(4 downto 1);

  -- Status
  signal ddr3_bank4_status : std_logic_vector(31 downto 0);
  signal ddr3_bank5_status : std_logic_vector(31 downto 0);

  -- 1-wire
  signal owr_pwren : std_logic_vector(c_ONEWIRE_NB - 1 downto 0);
  signal owr_en    : std_logic_vector(c_ONEWIRE_NB - 1 downto 0);
  signal owr_i     : std_logic_vector(c_ONEWIRE_NB - 1 downto 0);

  -- LEDs
  signal led_blink_cnt : unsigned(25 downto 0);
  signal led_blink     : std_logic;
  signal fp_led_n      : std_logic_vector(7 downto 0);

  -- DDR access FIFOs
  signal ddr_bank4_start_addr    : std_logic_vector(31 downto 0);
  signal ddr_bank4_addr_cnt      : std_logic_vector(31 downto 0);
  signal ddr_bank4_start_addr_wr : std_logic;
  signal ddr_bank4_data_o        : std_logic_vector(31 downto 0);
  signal ddr_bank4_data_i        : std_logic_vector(31 downto 0);
  signal ddr_bank4_data_load     : std_logic;
  signal ddr_bank5_start_addr    : std_logic_vector(31 downto 0);
  signal ddr_bank5_addr_cnt      : std_logic_vector(31 downto 0);
  signal ddr_bank5_start_addr_wr : std_logic;
  signal ddr_bank5_data_o        : std_logic_vector(31 downto 0);
  signal ddr_bank5_data_i        : std_logic_vector(31 downto 0);
  signal ddr_bank5_data_load     : std_logic;

  -- FOR TEST
  --signal ram_we : std_logic;


begin

  ------------------------------------------------------------------------------
  -- System reset
  ------------------------------------------------------------------------------
  sys_rst_n <=
    rst_n_i and                         -- power-on reset
    vme_sysreset_n_i;                   -- VME system reset


  ------------------------------------------------------------------------------
  -- Clocks distribution from 20MHz TCXO
  --  62.500 MHz slow system clock
  -- 125.000 MHz system clock
  -- 250.000 MHz fast system clock
  -- 300.000 MHz DDR3 clock
  ------------------------------------------------------------------------------
  cmp_sys_clk_buf : IBUFG
    port map (
      I => clk20_vcxo_i,
      O => clk_in);

  cmp_sys_clk_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 50,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 16,
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 8,
      CLKOUT1_PHASE      => 0.000,
      CLKOUT1_DUTY_CYCLE => 0.500,
      CLKOUT2_DIVIDE     => 4,
      CLKOUT2_PHASE      => 0.000,
      CLKOUT2_DUTY_CYCLE => 0.500,
      CLKIN_PERIOD       => 50.0,
      REF_JITTER         => 0.016)
    port map (
      CLKFBOUT => sys_clk_fb,
      CLKOUT0  => sys_clk_62_buf,
      CLKOUT1  => sys_clk_125_buf,
      CLKOUT2  => sys_clk_250_buf,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => sys_clk_pll_locked,
      RST      => '0',
      CLKFBIN  => sys_clk_fb,
      CLKIN    => clk_in);

  cmp_clk_62_buf : BUFG
    port map (
      O => sys_clk_62,
      I => sys_clk_62_buf);

  cmp_clk_125_buf : BUFG
    port map (
      O => sys_clk_125,
      I => sys_clk_125_buf);

  cmp_clk_250_buf : BUFG
    port map (
      O => sys_clk_250,
      I => sys_clk_250_buf);

  sys_clk <= sys_clk_62;

  cmp_ddr_clk_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 30,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 2,
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKIN_PERIOD       => 50.0,
      REF_JITTER         => 0.016)
    port map (
      CLKFBOUT => ddr_clk_fb,
      CLKOUT0  => ddr_clk_buf,
      CLKOUT1  => open,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => ddr_clk_pll_locked,
      RST      => '0',
      CLKFBIN  => ddr_clk_fb,
      CLKIN    => clk_in);

  cmp_ddr_clk_buf : BUFG
    port map (
      O => ddr_clk,
      I => ddr_clk_buf);

  ------------------------------------------------------------------------------
  -- VME interface
  ------------------------------------------------------------------------------
  cmp_vme64x_core : VME64xCore_Top
    port map (
      clk_i   => sys_clk,
      reset_o => open,

      VME_AS_n_i      => vme_as_n_i,
      VME_RST_n_i     => vme_sysreset_n_i,
      VME_WRITE_n_i   => vme_write_n_i,
      VME_AM_i        => vme_am_i,
      VME_DS_n_i      => vme_ds_n_i,
      VME_GA_i        => vme_ga,
      VME_BERR_o      => vme_berr_o,
      VME_DTACK_n_o   => vme_dtack_n_o,
      VME_RETRY_n_o   => vme_retry_n_o,
      VME_RETRY_OE_o  => vme_retry_oe_o,
      VME_LWORD_n_b_i => vme_lword_n_i,
      VME_LWORD_n_b_o => vme_lword_n_o,
      VME_ADDR_b_i    => vme_a_i,
      VME_ADDR_b_o    => vme_a_o,
      VME_DATA_b_i    => vme_d_i,
      VME_DATA_b_o    => vme_d_o,
      VME_IRQ_n_o     => vme_irq_n_o,
      VME_IACK_n_i    => vme_iack_n_i,
      VME_IACKIN_n_i  => vme_iackin_n_i,
      VME_IACKOUT_n_o => vme_iackout_n_o,
      VME_DTACK_OE_o  => vme_dtack_oe_o,
      VME_DATA_DIR_o  => vme_d_dir,
      VME_DATA_OE_N_o => vme_d_oe_n_o,
      VME_ADDR_DIR_o  => vme_a_dir,
      VME_ADDR_OE_N_o => vme_a_oe_n_o,

      DAT_i(31 downto 0) => wbm_dat_i,
      DAT_o(31 downto 0) => wbm_dat_o,
      ADR_o(31 downto 0) => wbm_adr,
      CYC_o              => wbm_cyc,
      ERR_i              => '0',
      RTY_i              => '0',
      SEL_o(3 downto 0)  => wbm_sel,
      STB_o              => wbm_stb,
      ACK_i              => wbm_ack,
      WE_o               => wbm_we,
      STALL_i            => wbm_stall,

      INT_ack => open,
      IRQ_i   => '0',

      leds => open
      );

  vme_ga <= vme_gap_n_i & vme_ga_i;

  -- Tri-state buffer for bi-directrional ports
  vme_lword_n_i <= vme_lword_n_b;
  vme_lword_n_b <= vme_lword_n_o when vme_a_dir = '1' else 'Z';
  vme_a_i       <= vme_a_b;
  vme_a_b       <= vme_a_o       when vme_a_dir = '1' else (others => 'Z');
  vme_d_i       <= vme_d_b;
  vme_d_b       <= vme_d_o       when vme_d_dir = '1' else (others => 'Z');

  vme_a_dir_o <= vme_a_dir;
  vme_d_dir_o <= vme_d_dir;

  ------------------------------------------------------------------------------
  -- Wishbone address decoder
  --     0x000 -> CSR
  --     0x400 -> 1-wire master
  --     0x800 -> DDR3 bank 4
  --     0xC00 -> DDR3 bank 5
  ------------------------------------------------------------------------------
  cmp_csr_wb_addr_decoder : wb_addr_decoder
    generic map (
--      g_WINDOW_SIZE  => 30,             -- in bits => Needs A32 VME accesses
      g_WINDOW_SIZE  => 12,             -- TEMPORARY
      g_WB_SLAVES_NB => c_WB_SLAVES_NB
      )
    port map (
      -- GN4124 core clock and reset
      clk_i       => sys_clk,
      rst_n_i     => sys_rst_n,
      -- wishbone master interface
      wbm_adr_i   => wbm_adr,
      wbm_dat_i   => wbm_dat_o,
      wbm_sel_i   => wbm_sel,
      wbm_stb_i   => wbm_stb,
      wbm_we_i    => wbm_we,
      wbm_cyc_i   => wbm_cyc,
      wbm_dat_o   => wbm_dat_i,
      wbm_ack_o   => wbm_ack,
      wbm_stall_o => wbm_stall,
      -- wishbone slaves interface
      wb_adr_o    => wb_adr,
      wb_dat_o    => wb_dat_o,
      wb_sel_o    => wb_sel,
      wb_stb_o    => wb_stb,
      wb_we_o     => wb_we,
      wb_cyc_o    => wb_cyc,
      wb_dat_i    => wb_dat_i,
      wb_ack_i    => wb_ack,
      wb_stall_i  => wb_stall
      );


  ------------------------------------------------------------------------------
  -- CSR
  ------------------------------------------------------------------------------
  cmp_csr : csr
    port map(
      rst_n_i                        => sys_rst_n,
      wb_clk_i                       => sys_clk,
      wb_addr_i                      => wb_adr(2 downto 0),
      wb_data_i                      => wb_dat_o,
      wb_data_o                      => wb_dat_i(c_WB_CSR * 32 + 31 downto c_WB_CSR * 32),
      wb_cyc_i                       => wb_cyc(c_WB_CSR),
      wb_sel_i                       => wb_sel,
      wb_stb_i                       => wb_stb,
      wb_we_i                        => wb_we,
      wb_ack_o                       => wb_ack(c_WB_CSR),
      csr_carrier_pcb_rev_i          => pcbrev_i,
      csr_carrier_reserved_i         => "00000000000",
      csr_carrier_type_i             => g_CARRIER_TYPE,
      csr_bitstream_type_i           => g_BITSTREAM_TYPE,
      csr_bitstream_date_i           => g_BITSTREAM_DATE,
      csr_stat_fmc1_pres_i           => fmc1_prsntm2c_n_i,
      csr_stat_fmc2_pres_i           => fmc2_prsntm2c_n_i,
      csr_stat_sys_pll_lck_i         => sys_clk_pll_locked,
      csr_stat_ddr3_bank4_cal_done_i => ddr3_bank4_status(0),
      csr_stat_ddr3_bank5_cal_done_i => ddr3_bank5_status(0),
      csr_stat_gpio_in_i             => gpio_in,
      csr_stat_reserved_i            => "00000000000000000000000",
      csr_ctrl_fp_leds_o             => fp_led_n,
      csr_ctrl_dbg_leds_o            => dbg_led_n_o,
      csr_ctrl_gpio_term_o           => term_en_o,
      csr_ctrl_gpio_1_dir_o          => gpio_1_dir,
      csr_ctrl_gpio_2_dir_o          => gpio_2_dir,
      csr_ctrl_gpio_34_dir_o         => gpio_34_dir,
      csr_ctrl_gpio_out_o            => gpio_out,
      csr_ctrl_reserved_o            => open
      );

  wb_stall(c_WB_CSR) <= '0';


  ------------------------------------------------------------------------------
  -- 1-wire master for DS18B20 (thermometer + unique ID)
  ------------------------------------------------------------------------------
  cmp_onewire : wb_onewire_master
    generic map(
      g_num_ports        => 1,
      g_ow_btp_normal    => "5.0",
      g_ow_btp_overdrive => "1.0"
      )
    port map(
      clk_sys_i => sys_clk,
      rst_n_i   => sys_rst_n,

      wb_cyc_i => wb_cyc(c_ONEWIRE),
      wb_sel_i => wb_sel,
      wb_stb_i => wb_stb,
      wb_we_i  => wb_we,
      wb_adr_i => wb_adr(2 downto 0),   -- byte addressing
      wb_dat_i => wb_dat_o,
      wb_dat_o => wb_dat_i(c_ONEWIRE * 32 + 31 downto 32 * c_ONEWIRE),
      wb_ack_o => wb_ack(c_ONEWIRE),
      wb_int_o => open,

      owr_pwren_o => owr_pwren,
      owr_en_o    => owr_en,
      owr_i       => owr_i
      );

  tempid_dq_b <= '0' when owr_en(0) = '1' else 'Z';
  owr_i(0)    <= tempid_dq_b;

  -- Classic slave supporting single pipelined accesses, stall isn't used
  wb_stall(c_ONEWIRE) <= '0';


  ------------------------------------------------------------------------------
  -- DDR3 controller bank4
  ------------------------------------------------------------------------------

  --############################################################################
  -- block RAM for test
  --############################################################################
  --process (sys_clk)
  --begin
  --  if rising_edge(sys_clk) then
  --    if (sys_rst_n = '0') then
  --      wb_ack(c_WB_DDR_BANK4) <= '0';
  --    elsif (wb_cyc(c_WB_DDR_BANK4) = '1' and wb_stb = '1') then
  --      wb_ack(c_WB_DDR_BANK4) <= '1';
  --    else
  --      wb_ack(c_WB_DDR_BANK4) <= '0';
  --    end if;
  --  end if;
  --end process;

  --wb_stall(c_WB_DDR_BANK4) <= '0';

  --ram_we <= wb_we and wb_cyc(c_WB_DDR_BANK4) and wb_stb;

  --cmp_test_ram : generic_spram
  --  generic map(
  --    g_data_width               => 32,
  --    g_size                     => 2048,
  --    g_with_byte_enable         => false,
  --    g_addr_conflict_resolution => "write_first"
  --    )
  --  port map(
  --    rst_n_i => sys_rst_n,
  --    clk_i   => sys_clk,
  --    bwe_i   => "0000",
  --    we_i    => ram_we,
  --    a_i     => wb_adr(10 downto 0),
  --    d_i     => wb_dat_o,
  --    q_o     => wb_dat_i(c_WB_DDR_BANK4 * 32 + 31 downto c_WB_DDR_BANK4 * 32)
  --    );


  cmp_ddr_ctrl_bank4 : ddr3_ctrl
    generic map(
      g_BANK_PORT_SELECT   => "SVEC_BANK4_32B_32B",
      g_MEMCLK_PERIOD      => 3333,
      g_SIMULATION         => g_SIMULATION,
      g_CALIB_SOFT_IP      => g_CALIB_SOFT_IP,
      g_P0_MASK_SIZE       => 4,
      g_P0_DATA_PORT_SIZE  => 32,
      g_P0_BYTE_ADDR_WIDTH => 30,
      g_P1_MASK_SIZE       => 4,
      g_P1_DATA_PORT_SIZE  => 32,
      g_P1_BYTE_ADDR_WIDTH => 30)
    port map (
      clk_i   => ddr_clk,
      rst_n_i => sys_rst_n,

      status_o => ddr3_bank4_status,

      ddr3_dq_b     => ddr_dq_b,
      ddr3_a_o      => ddr_a_o,
      ddr3_ba_o     => ddr_ba_o,
      ddr3_ras_n_o  => ddr_ras_n_o,
      ddr3_cas_n_o  => ddr_cas_n_o,
      ddr3_we_n_o   => ddr_we_n_o,
      ddr3_odt_o    => ddr_odt_o,
      ddr3_rst_n_o  => ddr_reset_n_o,
      ddr3_cke_o    => ddr_cke_o,
      ddr3_dm_o     => ddr_ldm_o,
      ddr3_udm_o    => ddr_udm_o,
      ddr3_dqs_p_b  => ddr_ldqs_p_b,
      ddr3_dqs_n_b  => ddr_ldqs_n_b,
      ddr3_udqs_p_b => ddr_udqs_p_b,
      ddr3_udqs_n_b => ddr_udqs_n_b,
      ddr3_clk_p_o  => ddr_ck_p_o,
      ddr3_clk_n_o  => ddr_ck_n_o,
      ddr3_rzq_b    => ddr_rzq_b,
      ddr3_zio_b    => ddr_zio_b,

      wb0_clk_i   => sys_clk,
      wb0_sel_i   => wb_sel,
      wb0_cyc_i   => wb_cyc(c_WB_DDR_BANK4),
      wb0_stb_i   => wb_stb,
      wb0_we_i    => wb_we,
      wb0_addr_i  => wb_adr,
      wb0_data_i  => wb_dat_o,
      wb0_data_o  => wb_dat_i(c_WB_DDR_BANK4 * 32 + 31 downto c_WB_DDR_BANK4 * 32),
      wb0_ack_o   => wb_ack(c_WB_DDR_BANK4),
      wb0_stall_o => wb_stall(c_WB_DDR_BANK4),

      p0_cmd_empty_o   => open,
      p0_cmd_full_o    => open,
      p0_rd_full_o     => open,
      p0_rd_empty_o    => open,
      p0_rd_count_o    => open,
      p0_rd_overflow_o => open,
      p0_rd_error_o    => open,
      p0_wr_full_o     => open,
      p0_wr_empty_o    => open,
      p0_wr_count_o    => open,
      p0_wr_underrun_o => open,
      p0_wr_error_o    => open,

      wb1_clk_i   => '0',
      wb1_sel_i   => "0000",
      wb1_cyc_i   => '0',
      wb1_stb_i   => '0',
      wb1_we_i    => '0',
      wb1_addr_i  => X"00000000",
      wb1_data_i  => X"00000000",
      wb1_data_o  => open,
      wb1_ack_o   => open,
      wb1_stall_o => open,

      p1_cmd_empty_o   => open,
      p1_cmd_full_o    => open,
      p1_rd_full_o     => open,
      p1_rd_empty_o    => open,
      p1_rd_count_o    => open,
      p1_rd_overflow_o => open,
      p1_rd_error_o    => open,
      p1_wr_full_o     => open,
      p1_wr_empty_o    => open,
      p1_wr_count_o    => open,
      p1_wr_underrun_o => open,
      p1_wr_error_o    => open
      );


  ------------------------------------------------------------------------------
  -- DDR3 controller bank5
  ------------------------------------------------------------------------------
  cmp_ddr_ctrl_bank5 : ddr3_ctrl
    generic map(
      g_BANK_PORT_SELECT   => "SVEC_BANK5_32B_32B",
      g_MEMCLK_PERIOD      => 3333,
      g_SIMULATION         => g_SIMULATION,
      g_CALIB_SOFT_IP      => g_CALIB_SOFT_IP,
      g_P0_MASK_SIZE       => 4,
      g_P0_DATA_PORT_SIZE  => 32,
      g_P0_BYTE_ADDR_WIDTH => 30,
      g_P1_MASK_SIZE       => 4,
      g_P1_DATA_PORT_SIZE  => 32,
      g_P1_BYTE_ADDR_WIDTH => 30)
    port map (
      clk_i   => ddr_clk,
      rst_n_i => sys_rst_n,

      status_o => ddr3_bank5_status,

      ddr3_dq_b     => ddr_2_dq_b,
      ddr3_a_o      => ddr_2_a_o,
      ddr3_ba_o     => ddr_2_ba_o,
      ddr3_ras_n_o  => ddr_2_ras_n_o,
      ddr3_cas_n_o  => ddr_2_cas_n_o,
      ddr3_we_n_o   => ddr_2_we_n_o,
      ddr3_odt_o    => ddr_2_odt_o,
      ddr3_rst_n_o  => ddr_2_reset_n_o,
      ddr3_cke_o    => ddr_2_cke_o,
      ddr3_dm_o     => ddr_2_ldm_o,
      ddr3_udm_o    => ddr_2_udm_o,
      ddr3_dqs_p_b  => ddr_2_ldqs_p_b,
      ddr3_dqs_n_b  => ddr_2_ldqs_n_b,
      ddr3_udqs_p_b => ddr_2_udqs_p_b,
      ddr3_udqs_n_b => ddr_2_udqs_n_b,
      ddr3_clk_p_o  => ddr_2_ck_p_o,
      ddr3_clk_n_o  => ddr_2_ck_n_o,
      ddr3_rzq_b    => ddr_2_rzq_b,
      ddr3_zio_b    => ddr_2_zio_b,

      wb0_clk_i   => sys_clk,
      wb0_sel_i   => wb_sel,
      wb0_cyc_i   => wb_cyc(c_WB_DDR_BANK5),
      wb0_stb_i   => wb_stb,
      wb0_we_i    => wb_we,
      wb0_addr_i  => wb_adr,
      wb0_data_i  => wb_dat_o,
      wb0_data_o  => wb_dat_i(c_WB_DDR_BANK5 * 32 + 31 downto c_WB_DDR_BANK5 * 32),
      wb0_ack_o   => wb_ack(c_WB_DDR_BANK5),
      wb0_stall_o => wb_stall(c_WB_DDR_BANK5),

      p0_cmd_empty_o   => open,
      p0_cmd_full_o    => open,
      p0_rd_full_o     => open,
      p0_rd_empty_o    => open,
      p0_rd_count_o    => open,
      p0_rd_overflow_o => open,
      p0_rd_error_o    => open,
      p0_wr_full_o     => open,
      p0_wr_empty_o    => open,
      p0_wr_count_o    => open,
      p0_wr_underrun_o => open,
      p0_wr_error_o    => open,

      wb1_clk_i   => '0',
      wb1_sel_i   => "0000",
      wb1_cyc_i   => '0',
      wb1_stb_i   => '0',
      wb1_we_i    => '0',
      wb1_addr_i  => X"00000000",
      wb1_data_i  => X"00000000",
      wb1_data_o  => open,
      wb1_ack_o   => open,
      wb1_stall_o => open,

      p1_cmd_empty_o   => open,
      p1_cmd_full_o    => open,
      p1_rd_full_o     => open,
      p1_rd_empty_o    => open,
      p1_rd_count_o    => open,
      p1_rd_overflow_o => open,
      p1_rd_error_o    => open,
      p1_wr_full_o     => open,
      p1_wr_empty_o    => open,
      p1_wr_count_o    => open,
      p1_wr_underrun_o => open,
      p1_wr_error_o    => open
      );


  ------------------------------------------------------------------------------
  -- GPIO
  -----------------------------------------------------------------------------
  fpgpio1_a2b_o  <= gpio_1_dir;
  fpgpio2_a2b_o  <= gpio_2_dir;
  fpgpio34_a2b_o <= gpio_34_dir;

  fp_gpio_b(1) <= gpio_out(1) when gpio_1_dir = '1'  else 'Z';
  fp_gpio_b(2) <= gpio_out(2) when gpio_2_dir = '1'  else 'Z';
  fp_gpio_b(3) <= gpio_out(3) when gpio_34_dir = '1' else 'Z';
  fp_gpio_b(4) <= gpio_out(4) when gpio_34_dir = '1' else 'Z';

  gpio_in <= fp_gpio_b;

  ------------------------------------------------------------------------------
  -- LEDs
  -----------------------------------------------------------------------------
  process (sys_clk)
  begin
    if rising_edge(sys_clk) then
      led_blink_cnt <= led_blink_cnt + 1;
      if led_blink_cnt(24) = '1' then
        led_blink <= '1';
      else
        led_blink <= '0';
      end if;
    end if;
  end process;

  l_fp_led : for I in 0 to 7 generate
    fp_led_n_o(I) <= not(fp_led_n(I) or led_blink);
  end generate l_fp_led;


end rtl;
