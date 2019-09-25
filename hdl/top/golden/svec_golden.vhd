--------------------------------------------------------------------------------
-- CERN BE-CO-HT
-- SVEC
-- https://ohwr.org/projects/svec
--------------------------------------------------------------------------------
--
-- unit name:   svec_golden
--
-- description: SVEC carrier golden.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2019
--------------------------------------------------------------------------------
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 2.0 (the "License"); you may not use this file except
-- in compliance with the License. You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-2.0.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the specific language governing permissions
-- and limitations under the License.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;
use work.wishbone_pkg.all;

entity svec_golden is
  generic (
    --  WR PTP firmware.
    g_DPRAM_INITF   : string := "../../../../wr-cores/bin/wrpc/wrc_phy8.bram";
    -- Simulation-mode enable parameter. Set by default (synthesis) to 0, and
    -- changed to non-zero in the instantiation of the top level DUT in the testbench.
    -- Its purpose is to reduce some internal counters/timeouts to speed up simulations.
    g_SIMULATION : integer := 0;
    -- Increase information messages during simulation
    g_VERBOSE    : boolean := False
  );
  port (
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------

    -- Reset from system fpga
    rst_n_i : in std_logic;

    -- 125 MHz PLL reference
    clk_125m_pllref_p_i : in std_logic;
    clk_125m_pllref_n_i : in std_logic;

    ---------------------------------------------------------------------------
    -- VME interface
    ---------------------------------------------------------------------------

    vme_write_n_i    : in    std_logic;
    vme_sysreset_n_i : in    std_logic;
    vme_retry_oe_o   : out   std_logic;
    vme_retry_n_o    : out   std_logic;
    vme_lword_n_b    : inout std_logic;
    vme_iackout_n_o  : out   std_logic;
    vme_iackin_n_i   : in    std_logic;
    vme_iack_n_i     : in    std_logic;
    vme_gap_i        : in    std_logic;
    vme_dtack_oe_o   : out   std_logic;
    vme_dtack_n_o    : out   std_logic;
    vme_ds_n_i       : in    std_logic_vector(1 downto 0);
    vme_data_oe_n_o  : out   std_logic;
    vme_data_dir_o   : out   std_logic;
    vme_berr_o       : out   std_logic;
    vme_as_n_i       : in    std_logic;
    vme_addr_oe_n_o  : out   std_logic;
    vme_addr_dir_o   : out   std_logic;
    vme_irq_o        : out   std_logic_vector(7 downto 1);
    vme_ga_i         : in    std_logic_vector(4 downto 0);
    vme_data_b       : inout std_logic_vector(31 downto 0);
    vme_am_i         : in    std_logic_vector(5 downto 0);
    vme_addr_b       : inout std_logic_vector(31 downto 1);

    ---------------------------------------------------------------------------
    -- FMC interface
    ---------------------------------------------------------------------------

    -- I2C interface for accessing FMC EEPROM.
    fmc0_scl_b : inout std_logic;
    fmc0_sda_b : inout std_logic;
    fmc1_scl_b : inout std_logic;
    fmc1_sda_b : inout std_logic;

    -- Presence  (there is a pull-up)
    fmc0_prsnt_m2c_n_i: in std_logic;
    fmc1_prsnt_m2c_n_i: in std_logic;

    ---------------------------------------------------------------------------
    -- Carrier
    ---------------------------------------------------------------------------

    -- Onewire interface
    onewire_b : inout std_logic;

    -- Carrier I2C eeprom
    carrier_scl_b : inout std_logic;
    carrier_sda_b : inout std_logic;

    ---------------------------------------------------------------------------
    -- Flash memory SPI interface
    ---------------------------------------------------------------------------

    spi_sclk_o : out std_logic;
    spi_ncs_o  : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic;

    ------------------------------------------
    -- DDR (bank 4 & 5)
    ------------------------------------------
    ddr4_a_o       : out   std_logic_vector(13 downto 0);
    ddr4_ba_o      : out   std_logic_vector(2 downto 0);
    ddr4_cas_n_o   : out   std_logic;
    ddr4_ck_n_o    : out   std_logic;
    ddr4_ck_p_o    : out   std_logic;
    ddr4_cke_o     : out   std_logic;
    ddr4_dq_b      : inout std_logic_vector(15 downto 0);
    ddr4_ldm_o     : out   std_logic;
    ddr4_ldqs_n_b  : inout std_logic;
    ddr4_ldqs_p_b  : inout std_logic;
    ddr4_odt_o     : out   std_logic;
    ddr4_ras_n_o   : out   std_logic;
    ddr4_reset_n_o : out   std_logic;
    ddr4_rzq_b     : inout std_logic;
    ddr4_udm_o     : out   std_logic;
    ddr4_udqs_n_b  : inout std_logic;
    ddr4_udqs_p_b  : inout std_logic;
    ddr4_we_n_o    : out   std_logic;

    -- PCB revision
    pcbrev_i : in std_logic_vector(4 downto 0)
  );
end entity svec_golden;

architecture top of svec_golden is
  signal clk_sys_62m5  : std_logic;
  signal rst_sys_62m5_n  : std_logic;

  signal app_wb_out         : t_wishbone_master_out;
  signal app_wb_in          : t_wishbone_master_in;
begin
  inst_svec_base: entity work.svec_base_wr
    generic map (
      g_with_vic => True,
      g_with_onewire => True,
      g_with_spi => True,
      g_with_wr => False,
      g_with_ddr4 => False,
      g_with_ddr5 => False,
      g_app_offset => x"0000_0000",
      g_num_user_irq => 0,
      g_dpram_initf => g_dpram_initf,
      g_fabric_iface => open,
      g_streamers_op_mode => open,
      g_tx_streamer_params => open,
      g_rx_streamer_params => open,
      g_simulation => g_SIMULATION,
      g_verbose => g_VERBOSE
    )
    port map (
      rst_n_i => rst_n_i,
      clk_125m_pllref_p_i => clk_125m_pllref_p_i,
      clk_125m_pllref_n_i => clk_125m_pllref_n_i,
      clk_20m_vcxo_i => open,
      clk_125m_gtp_n_i => open,
      clk_125m_gtp_p_i => open,
      vme_write_n_i => vme_write_n_i,
      vme_sysreset_n_i => vme_sysreset_n_i,
      vme_retry_oe_o => vme_retry_oe_o,
      vme_retry_n_o => vme_retry_n_o,
      vme_lword_n_b => vme_lword_n_b,
      vme_iackout_n_o => vme_iackout_n_o,
      vme_iackin_n_i => vme_iackin_n_i,
      vme_iack_n_i => vme_iack_n_i,
      vme_gap_i => vme_gap_i,
      vme_dtack_oe_o => vme_dtack_oe_o,
      vme_dtack_n_o => vme_dtack_n_o,
      vme_ds_n_i => vme_ds_n_i,
      vme_data_oe_n_o => vme_data_oe_n_o,
      vme_data_dir_o => vme_data_dir_o,
      vme_berr_o => vme_berr_o,
      vme_as_n_i => vme_as_n_i,
      vme_addr_oe_n_o => vme_addr_oe_n_o,
      vme_addr_dir_o => vme_addr_dir_o,
      vme_irq_o => vme_irq_o,
      vme_ga_i => vme_ga_i,
      vme_data_b => vme_data_b,
      vme_am_i => vme_am_i,
      vme_addr_b => vme_addr_b,
      fmc0_scl_b => fmc0_scl_b,
      fmc0_sda_b => fmc0_sda_b,
      fmc1_scl_b => fmc1_scl_b,
      fmc1_sda_b => fmc1_sda_b,
      fmc0_prsnt_m2c_n_i => fmc0_prsnt_m2c_n_i,
      fmc1_prsnt_m2c_n_i => fmc1_prsnt_m2c_n_i,
      onewire_b => onewire_b,
      carrier_scl_b => carrier_scl_b,
      carrier_sda_b => carrier_sda_b,
      spi_sclk_o => spi_sclk_o,
      spi_ncs_o => spi_ncs_o,
      spi_mosi_o => spi_mosi_o,
      spi_miso_i => spi_miso_i,
      uart_rxd_i => open,
      uart_txd_o => open,
      plldac_sclk_o => open,
      plldac_din_o => open,
      pll20dac_din_o => open,
      pll20dac_sclk_o => open,
      pll20dac_sync_n_o => open,
      pll25dac_din_o => open,
      pll25dac_sclk_o => open,
      pll25dac_sync_n_o => open,
      sfp_txp_o => open,
      sfp_txn_o => open,
      sfp_rxp_i => open,
      sfp_rxn_i => open,
      sfp_mod_def0_i => open,
      sfp_mod_def1_b => open,
      sfp_mod_def2_b => open,
      sfp_rate_select_o => open,
      sfp_tx_fault_i => open,
      sfp_tx_disable_o => open,
      sfp_los_i => open,
      ddr4_a_o => ddr4_a_o,
      ddr4_ba_o => ddr4_ba_o,
      ddr4_cas_n_o => ddr4_cas_n_o,
      ddr4_ck_n_o => ddr4_ck_n_o,
      ddr4_ck_p_o => ddr4_ck_p_o,
      ddr4_cke_o => ddr4_cke_o,
      ddr4_dq_b => ddr4_dq_b,
      ddr4_ldm_o => ddr4_ldm_o,
      ddr4_ldqs_n_b => ddr4_ldqs_n_b,
      ddr4_ldqs_p_b => ddr4_ldqs_p_b,
      ddr4_odt_o => ddr4_odt_o,
      ddr4_ras_n_o => ddr4_ras_n_o,
      ddr4_reset_n_o => ddr4_reset_n_o,
      ddr4_rzq_b => ddr4_rzq_b,
      ddr4_udm_o => ddr4_udm_o,
      ddr4_udqs_n_b => ddr4_udqs_n_b,
      ddr4_udqs_p_b => ddr4_udqs_p_b,
      ddr4_we_n_o => ddr4_we_n_o,
      ddr5_a_o => open,
      ddr5_ba_o => open,
      ddr5_cas_n_o => open,
      ddr5_ck_n_o => open,
      ddr5_ck_p_o => open,
      ddr5_cke_o => open,
      ddr5_dq_b => open,
      ddr5_ldm_o => open,
      ddr5_ldqs_n_b => open,
      ddr5_ldqs_p_b => open,
      ddr5_odt_o => open,
      ddr5_ras_n_o => open,
      ddr5_reset_n_o => open,
      ddr5_rzq_b => open,
      ddr5_udm_o => open,
      ddr5_udqs_n_b => open,
      ddr5_udqs_p_b => open,
      ddr5_we_n_o => open,
      pcbrev_i => pcbrev_i,
      ddr4_clk_i => clk_sys_62m5,
      ddr4_rst_n_i => rst_sys_62m5_n,
      ddr4_wb_i.cyc => '0',
      ddr4_wb_i.stb => '0',
      ddr4_wb_i.adr => x"0000_0000",
      ddr4_wb_i.sel => x"00",
      ddr4_wb_i.we => '0',
      ddr4_wb_i.dat => (63 downto 0 => '0'),
      ddr4_wb_o => open,
      ddr5_clk_i => clk_sys_62m5,
      ddr5_rst_n_i => rst_sys_62m5_n,
      ddr5_wb_i.cyc => '0',
      ddr5_wb_i.stb => '0',
      ddr5_wb_i.adr => x"0000_0000",
      ddr5_wb_i.sel => x"00",
      ddr5_wb_i.we => '0',
      ddr5_wb_i.dat => (63 downto 0 => '0'),
      ddr5_wb_o => open,
      ddr4_wr_fifo_empty_o => open,
      ddr5_wr_fifo_empty_o => open,
      clk_sys_62m5_o => clk_sys_62m5,
      rst_sys_62m5_n_o => rst_sys_62m5_n,
      clk_ref_125m_o => open,
      rst_ref_125m_n_o => open,
      irq_user_i => "",
      app_wb_o => app_wb_out,
      app_wb_i => app_wb_in
    );
  app_wb_in <= (ack => '1', err | rty | stall => '0', dat => (others => '0'));
end architecture top;
