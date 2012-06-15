--------------------------------------------------------------------------------
-- CERN (BE-CO-HT)
-- Top level entity for Simple VME FMC Carrier (SVEC) Application FPGA
-- http://www.ohwr.org/projects/svec
--------------------------------------------------------------------------------
--
-- unit name: svec_v0_afpga_top
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
-- last changes: see svn log.
--------------------------------------------------------------------------------
-- TODO: - 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--library UNISIM;
--use UNISIM.vcomponents.all;

library work;


entity svec_v0_afpga_top is
  generic(
    g_GENERIC : string := "FALSE");
  port
    (

      ------------------------------------------
      -- VME interface
      ------------------------------------------
      vme_write_n_i    : in    std_logic;
      vme_sysreset_n_i : in    std_logic;
      vme_sysclk_i     : in    std_logic;
      vme_retry_oe_o   : out   std_logic;
      vme_retry_n_o    : out   std_logic;
      vme_lword_n_b    : inout std_logic;
      vme_iackout_n_o  : out   std_logic;
      vme_iackin_n_i   : in    std_logic;
      vme_iack_n_1     : in    std_logic;
      vme_gap_i        : in    std_logic;
      vme_dtack_oe_o   : out   std_logic;
      vme_dtack_n_o    : out   std_logic;
      vme_ds2_n_i      : in    std_logic;
      vme_ds1_n_i      : in    std_logic;
      vme_d_oe_n_o     : out   std_logic;
      vme_d_dir_o      : out   std_logic;
      vme_berr_o       : out   std_logic;
      vme_as_n_i       : in    std_logic;
      vme_a_oe_n_o     : out   std_logic;
      vme_a_dir_o      : out   std_logic;
      vme_irq_o        : out   std_logic_vector(7 downto 1);
      vme_ga_i         : in    std_logic_vector(4 downto 0);
      vme_d_b          : inout std_logic_vector(31 downto 0);
      vme_am_i         : in    std_logic_vector(5 downto 0);
      vme_a_b          : inout std_logic_vector(31 downto 1);

      ------------------------------------------
      -- Clock and reset inputs
      ------------------------------------------
      rst_n_i : in std_logic;

      clk20_vcxo_i   : in std_logic;
      fpga_clk_n_i   : in std_logic;
      fpga_clk_p_i   : in std_logic;
      si57x_clk_n_i  : in std_logic;
      si57x_clk_p_i  : in std_logic;
      pll_2afpga_n_i : in std_logic;
      pll_2afpga_p_i : in std_logic;

      ------------------------------------------
      -- Switches and button
      ------------------------------------------
      pushbutton_i : in std_logic;
      noga_i       : in std_logic_vector(4 downto 0);
      switch_i     : in std_logic_vector(1 downto 0);
      usega_i      : in std_logic;

      ------------------------------------------
      -- Inter-FPGA lines
      ------------------------------------------
      rsvd_b : inout std_logic_vector(7 downto 0);

      ------------------------------------------
      -- PCB revision
      ------------------------------------------
      pcbrev_i : in std_logic_vector(4 downto 0);

      ------------------------------------------
      -- SFP slot
      ------------------------------------------
      sfprx_123_n_i : in  std_logic;
      sfprx_123_p_i : in  std_logic;
      sfptx_123_n_o : out std_logic;
      sfptx_123_p_o : out std_logic;
      gtp_ck1_p_i   : in  std_logic;
      gtp_ck1_n_i   : in  std_logic;

      wr_los_i        : in    std_logic;
      wr_moddef0_i    : in    std_logic;
      wr_moddef1_o    : out   std_logic;
      wr_moddef2_b    : inout std_logic;
      wr_rateselect_o : out   std_logic;
      wr_txdisable_o  : out   std_logic;
      wr_txfault_i    : in    std_logic;

      ------------------------------------------
      -- SATA connectors
      ------------------------------------------
      sata1_tx_p_o : out std_logic;
      sata1_tx_n_o : out std_logic;
      sata1_rx_p_i : in  std_logic;
      sata1_rx_n_i : in  std_logic;
      sata0_tx_p_o : out std_logic;
      sata0_tx_n_o : out std_logic;
      sata0_rx_p_i : in  std_logic;
      sata0_rx_n_i : in  std_logic;
      gtp_ck0_p_i  : in  std_logic;
      gtp_ck0_n_i  : in  std_logic;

      ------------------------------------------
      -- PCIe interface (optional)
      ------------------------------------------
      pcie_tx1_p_o        : out std_logic;
      pcie_tx1_n_o        : out std_logic;
      pcie_rx1_p_i        : in  std_logic;
      pcie_rx1_n_i        : in  std_logic;
      pcie_master_clk_p_i : in  std_logic;
      pcie_master_clk_n_i : in  std_logic;

      ------------------------------------------
      -- Clock controls
      ------------------------------------------
      oe_si57x_o   : out   std_logic;
      si57x_scl_o  : out   std_logic;
      si57x_sda_b  : inout std_logic;
      si57x_tune_o : out   std_logic;   -- (optional)

      pll20dac_din_o    : out std_logic;
      pll20dac_sclk_o   : out std_logic;
      pll20dac_sync_n_o : out std_logic;
      pll25dac_din_o    : out std_logic;
      pll25dac_sclk_o   : out std_logic;
      pll25dac_sync_n_o : out std_logic;

      ------------------------------------------
      -- UART
      ------------------------------------------
      uart_rxd_o : out std_logic;
      uart_txd_i : in  std_logic;

      ------------------------------------------
      -- USB (optional)
      ------------------------------------------
      usb_clkout_i : in    std_logic;
      usb_oe_n_o   : out   std_logic;
      usb_rd_n_o   : out   std_logic;
      usb_rxf_n_i  : in    std_logic;
      usb_siwua_i  : in    std_logic;
      usb_txe_n_i  : in    std_logic;
      usb_wr_n_o   : out   std_logic;
      usb_d_b      : inout std_logic_vector(7 downto 0);
      io7_i        : in    std_logic;

      ------------------------------------------
      -- VME P2
      ------------------------------------------
      p2_data_p_b : inout std_logic_vector(19 downto 0);
      p2_data_n_b : inout std_logic_vector(19 downto 0);

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
      ddr_a_o       : out   std_logic_vector(14 downto 0);

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
      ddr_2_a_o       : out   std_logic_vector(14 downto 0);

      ------------------------------------------
      -- FMC slot 1
      ------------------------------------------
      fmc1_gbtclk0m2c_p_i : in  std_logic;
      fmc1_gbtclk0m2c_n_i : in  std_logic;
      fmc1_dp0m2c_p_i     : in  std_logic;
      fmc1_dp0m2c_n_i     : in  std_logic;
      fmc1_dp0c2m_p_o     : out std_logic;
      fmc1_dp0c2m_n_o     : out std_logic;

      fmc1_pg_c2m_o     : out   std_logic;
      fmc1_prsntm2c_n_i : in    std_logic;
      fmc1_scl_o        : out   std_logic;
      fmc1_sda_b        : inout std_logic;
      fmc1_tck_o        : out   std_logic;
      fmc1_tdi_i        : in    std_logic;
      fmc1_tdo_o        : out   std_logic;
      fmc1_tms_o        : out   std_logic;
      fmc1_clk1m2c_p_i  : in    std_logic;
      fmc1_clk1m2c_n_i  : in    std_logic;
      fmc1_clk0m2c_p_i  : in    std_logic;
      fmc1_clk0m2c_n_I  : in    std_logic;
      fmc1_la_p_b       : inout std_logic_vector(33 downto 0);
      fmc1_la_n_b       : inout std_logic_vector(33 downto 0);

      ------------------------------------------
      -- FMC slot 2
      ------------------------------------------
      fmc2_gbtclk0m2c_p_i : in  std_logic;
      fmc2_gbtclk0m2c_n_i : in  std_logic;
      fmc2_dp0m2c_p_i     : in  std_logic;
      fmc2_dp0m2c_n_i     : in  std_logic;
      fmc2_dp0c2m_p_o     : out std_logic;
      fmc2_dp0c2m_n_o     : out std_logic;

      fmc2_pg_c2m_o     : out   std_logic;
      fmc2_prsntm2c_n_i : in    std_logic;
      fmc2_scl_o        : out   std_logic;
      fmc2_sda_b        : inout std_logic;
      fmc2_tck_o        : out   std_logic;
      fmc2_tdi_i        : in    std_logic;
      fmc2_tdo_o        : out   std_logic;
      fmc2_tms_o        : out   std_logic;
      fmc2_clk1m2c_p_i  : in    std_logic;
      fmc2_clk1m2c_n_i  : in    std_logic;
      fmc2_clk0m2c_p_i  : in    std_logic;
      fmc2_clk0m2c_n_i  : in    std_logic;
      fmc2_la_p_b       : inout std_logic_vector(33 downto 0);
      fmc2_la_n_b       : inout std_logic_vector(33 downto 0);

      ------------------------------------------
      -- I2C EEPROM
      ------------------------------------------
      scl_afpga_o : out   std_logic;
      sda_afpga_b : inout std_logic;

      ------------------------------------------
      -- Front panel IO and LEDs
      ------------------------------------------
      fp_gpio_b : inout std_logic_vector(4 downto 1);

      fpgpio1_a2b_o  : out std_logic;
      fpgpio2_a2b_o  : out std_logic;
      fpgpio34_a2b_o : out std_logic;

      term_en_o : out std_logic_vector(4 downto 1);

      fp_ledn_o : out std_logic_vector(7 downto 0);

      ------------------------------------------
      -- 1-wire thermoeter + unique ID
      ------------------------------------------
      tempid_dq_b : inout std_logic;

      ------------------------------------------
      -- Debug LEDs
      ------------------------------------------
      dbg_led_n_o : out std_logic_vector(4 downto 1)

      );
end svec_v0_afpga_top;


architecture rtl of svec_v0_afpga_top is

  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------

begin



end rtl;
