--------------------------------------------------------------------------------
-- CERN BE-CO-HT
-- SVEC
-- https://ohwr.org/projects/svec
--------------------------------------------------------------------------------
--
-- unit name:   svec_base_wr
--
-- description: SVEC carrier base, with WR.
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
use work.ddr3_ctrl_pkg.all;
use work.vme64x_pkg.all;
use work.wr_xilinx_pkg.all;
use work.wr_board_pkg.all;
use work.wr_svec_pkg.all;
use work.buildinfo_pkg.all;
use work.wr_fabric_pkg.all;
use work.streamers_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity svec_base_wr is
  generic (
    --  If true, instantiate a VIC/ONEWIRE/SPI/WR/DDRAM+DMA.
    g_WITH_VIC      : boolean := True;
    g_WITH_ONEWIRE  : boolean := True;
    g_WITH_SPI      : boolean := True;
    g_WITH_WR       : boolean := False;
    g_WITH_DDR4     : boolean := True;
    g_WITH_DDR5     : boolean := True;
    --  Address of the application meta-data.  0 if none.
    g_APP_OFFSET    : std_logic_vector(31 downto 0) := x"0000_0000";
    --  Number of user interrupts
    g_NUM_USER_IRQ  : natural := 1;
    --  WR PTP firmware.
    g_DPRAM_INITF   : string := "../../../../wr-cores/bin/wrpc/wrc_phy8.bram";
    -- Number of aux clocks syntonized by WRPC to WR timebase
    g_AUX_CLKS : integer := 0;
    -- Fabric interface selection for WR Core:
    -- plain     = expose WRC fabric interface
    -- streamers = attach WRC streamers to fabric interface
    -- etherbone = attach Etherbone slave to fabric interface
    g_FABRIC_IFACE  : t_board_fabric_iface := plain;
    -- parameters configuration when g_fabric_iface = "streamers" (otherwise ignored)
    g_STREAMERS_OP_MODE  : t_streamers_op_mode  := TX_AND_RX;
    g_TX_STREAMER_PARAMS : t_tx_streamer_params := c_TX_STREAMER_PARAMS_DEFAUT;
    g_RX_STREAMER_PARAMS : t_rx_streamer_params := c_RX_STREAMER_PARAMS_DEFAUT;
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

    -- 20MHz VCXO clock (for WR)
    clk_20m_vcxo_i : in std_logic := '0';

    -- 125 MHz GTP reference
    clk_125m_gtp_n_i : in std_logic := '0';
    clk_125m_gtp_p_i : in std_logic := '0';

    -- Aux clocks, which can be disciplined by the WR Core
    clk_aux_i : in  std_logic_vector(g_AUX_CLKS-1 downto 0) := (others => '0');

    -- 10MHz ext ref clock input
    clk_10m_ext_i : in std_logic := '0';
    -- External PPS input
    pps_ext_i     : in std_logic := '0';

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

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------

    uart_rxd_i : in  std_logic := '1';
    uart_txd_o : out std_logic;

    ---------------------------------------------------------------------------
    -- SPI interface to DACs
    ---------------------------------------------------------------------------

    plldac_sclk_o     : out std_logic;
    plldac_din_o      : out std_logic;
    pll20dac_din_o    : out std_logic;
    pll20dac_sclk_o   : out std_logic;
    pll20dac_sync_n_o : out std_logic;
    pll25dac_din_o    : out std_logic;
    pll25dac_sclk_o   : out std_logic;
    pll25dac_sync_n_o : out std_logic;

    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver
    ---------------------------------------------------------------------------

    sfp_txp_o         : out   std_logic;
    sfp_txn_o         : out   std_logic;
    sfp_rxp_i         : in    std_logic := '0';
    sfp_rxn_i         : in    std_logic := '0';
    sfp_mod_def0_i    : in    std_logic := '0';          -- sfp detect
    sfp_mod_def1_b    : inout std_logic;          -- scl
    sfp_mod_def2_b    : inout std_logic;          -- sda
    sfp_rate_select_o : out   std_logic;
    sfp_tx_fault_i    : in    std_logic := '0';
    sfp_tx_disable_o  : out   std_logic;
    sfp_los_i         : in    std_logic := '0';

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

    ddr5_a_o       : out   std_logic_vector(13 downto 0);
    ddr5_ba_o      : out   std_logic_vector(2 downto 0);
    ddr5_cas_n_o   : out   std_logic;
    ddr5_ck_n_o    : out   std_logic;
    ddr5_ck_p_o    : out   std_logic;
    ddr5_cke_o     : out   std_logic;
    ddr5_dq_b      : inout std_logic_vector(15 downto 0);
    ddr5_ldm_o     : out   std_logic;
    ddr5_ldqs_n_b  : inout std_logic;
    ddr5_ldqs_p_b  : inout std_logic;
    ddr5_odt_o     : out   std_logic;
    ddr5_ras_n_o   : out   std_logic;
    ddr5_reset_n_o : out   std_logic;
    ddr5_rzq_b     : inout std_logic;
    ddr5_udm_o     : out   std_logic;
    ddr5_udqs_n_b  : inout std_logic;
    ddr5_udqs_p_b  : inout std_logic;
    ddr5_we_n_o    : out   std_logic;

    -- PCB revision
    pcbrev_i : in std_logic_vector(4 downto 0);

    ------------------------------------------
    --  User part
    ------------------------------------------

    --  Direct access to the DDR-3
    --  Classic wishbone
    ddr4_clk_i   : in  std_logic := '0';
    ddr4_rst_n_i : in  std_logic := '1';
    ddr4_wb_i    : in  t_wishbone_slave_data64_in := c_DUMMY_WB_SLAVE_D64_IN;
    ddr4_wb_o    : out t_wishbone_slave_data64_out;

    ddr5_clk_i   : in  std_logic := '0';
    ddr5_rst_n_i : in  std_logic := '1';
    ddr5_wb_i    : in  t_wishbone_slave_data64_in := c_DUMMY_WB_SLAVE_D64_IN;
    ddr5_wb_o    : out t_wishbone_slave_data64_out;

    -- DDR FIFO empty flag
    ddr4_wr_fifo_empty_o : out std_logic;
    ddr5_wr_fifo_empty_o : out std_logic;

    --  Clocks and reset.
    clk_sys_62m5_o    : out std_logic;
    rst_sys_62m5_n_o  : out std_logic;
    clk_ref_125m_o    : out std_logic;
    rst_ref_125m_n_o  : out std_logic;

    --  Interrupts
    irq_user_i : in std_logic_vector(g_NUM_USER_IRQ + 5 downto 6) := (others => '0');

    -- WR fabric interface (when g_fabric_iface = "plain")
    wrf_src_o : out t_wrf_source_out;
    wrf_src_i : in  t_wrf_source_in := c_DUMMY_SRC_IN;
    wrf_snk_o : out t_wrf_sink_out;
    wrf_snk_i : in  t_wrf_sink_in   := c_DUMMY_SNK_IN;

    -- WR streamers (when g_fabric_iface = "streamers")
    wrs_tx_data_i  : in  std_logic_vector(g_TX_STREAMER_PARAMS.DATA_WIDTH-1 downto 0) := (others => '0');
    wrs_tx_valid_i : in  std_logic := '0';
    wrs_tx_dreq_o  : out std_logic;
    wrs_tx_last_i  : in  std_logic := '1';
    wrs_tx_flush_i : in  std_logic := '0';
    wrs_tx_cfg_i   : in  t_tx_streamer_cfg := c_TX_STREAMER_CFG_DEFAULT;
    wrs_rx_first_o : out std_logic;
    wrs_rx_last_o  : out std_logic;
    wrs_rx_data_o  : out std_logic_vector(g_rx_streamer_params.data_width-1 downto 0);
    wrs_rx_valid_o : out std_logic;
    wrs_rx_dreq_i  : in  std_logic := '0';
    wrs_rx_cfg_i   : in  t_rx_streamer_cfg := c_RX_STREAMER_CFG_DEFAULT;

    -- Etherbone WB master interface (when g_fabric_iface = "etherbone")
    wb_eth_master_o : out t_wishbone_master_out;
    wb_eth_master_i : in  t_wishbone_master_in := cc_dummy_master_in;

    -- Timecode I/F
    tm_link_up_o    : out std_logic;
    tm_time_valid_o : out std_logic;
    tm_tai_o        : out std_logic_vector(39 downto 0);
    tm_cycles_o     : out std_logic_vector(27 downto 0);

    -- Aux clocks control
    tm_dac_value_o       : out std_logic_vector(23 downto 0);
    tm_dac_wr_o          : out std_logic_vector(g_AUX_CLKS-1 downto 0);
    tm_clk_aux_lock_en_i : in  std_logic_vector(g_AUX_CLKS-1 downto 0) := (others => '0');
    tm_clk_aux_locked_o  : out std_logic_vector(g_AUX_CLKS-1 downto 0);

    -- PPS output
    pps_p_o    : out std_logic;
    pps_led_o  : out std_logic;

    -- Link ok indication
    link_ok_o  : out std_logic;

    -- WR leds
    led_link_o : out std_logic;
    led_act_o : out std_logic;

    -- The wishbone bus from the gennum/host to the application
    -- Addresses 0-0x1fff are not available (used by the carrier).
    -- This is a pipelined wishbone with byte granularity.
    app_wb_o           : out t_wishbone_master_out;
    app_wb_i           : in  t_wishbone_master_in
  );
end entity svec_base_wr;

architecture top of svec_base_wr is
  -- WRPC Xilinx platform auxiliary clock configuration, used for DDR clock
  constant c_WRPC_PLL_CONFIG : t_auxpll_cfg_array := (
    0      => (enabled => TRUE, bufg_en => TRUE, divide => 3),
    others => c_AUXPLL_CFG_DEFAULT);

  signal clk_sys_62m5    : std_logic;  -- 62.5Mhz

  signal clk_pll_aux     : std_logic_vector(3 downto 0);
  signal rst_pll_aux_n   : std_logic_vector(3 downto 0) := (others => '0');

  --  DDR
  signal clk_ddr_333m       : std_logic;
  signal rst_ddr_333m_n  : std_logic := '0';
  signal ddr_rst         : std_logic := '1';
  signal ddr4_status     : std_logic_vector(31 downto 0);
  signal ddr4_calib_done : std_logic;
  signal ddr5_calib_done : std_logic;

  --  Address for ddr4.
  signal csr_ddr4_addr_out    :    std_logic_vector(31 downto 0);
  signal csr_ddr4_addr_wr     :    std_logic;
  signal csr_ddr4_addr        :    std_logic_vector(31 downto 0);

  -- data to read or to write in ddr4
  signal csr_ddr4_data_in   :    std_logic_vector(31 downto 0);
  signal csr_ddr4_data_out  :    std_logic_vector(31 downto 0);
  signal csr_ddr4_data_wr   :    std_logic;
  signal csr_ddr4_data_rd   :    std_logic;
  signal csr_ddr4_data_wack :    std_logic;
  signal csr_ddr4_data_rack :    std_logic;

  -- 
  signal ddr4_read_ip  : std_logic;
  signal ddr4_write_ip : std_logic;

  signal ddr4_wb_out     : t_wishbone_master_out;
  signal ddr4_wb_in      : t_wishbone_master_in;

  signal ddr5_wb_out     : t_wishbone_master_out;
  signal ddr5_wb_in      : t_wishbone_master_in;

  signal vme_wb_out     : t_wishbone_master_out;
  signal vme_wb_in      : t_wishbone_master_in;

  -- VME
  signal vme_data_b_out    : std_logic_vector(31 downto 0);
  signal vme_addr_b_out    : std_logic_vector(31 downto 1);
  signal vme_lword_n_b_out : std_logic;
  signal vme_data_dir_int  : std_logic;
  signal vme_addr_dir_int  : std_logic;
  signal vme_ga            : std_logic_vector(5 downto 0);
  signal vme_berr_n        : std_logic;
  signal vme_irq_n         : std_logic_vector(7 downto 1);
  
  --  The wishbone bus to the carrier part.
  signal carrier_wb_out : t_wishbone_slave_out;
  signal carrier_wb_in  : t_wishbone_slave_in;

  signal metadata_addr : std_logic_vector(5 downto 2);
  signal metadata_data : std_logic_vector(31 downto 0);

  signal buildinfo_addr : std_logic_vector(7 downto 2);
  signal buildinfo_data : std_logic_vector(31 downto 0);

  signal therm_id_in          : t_wishbone_master_in;
  signal therm_id_out         : t_wishbone_master_out;

  -- i2c controllers to the fmcs
  signal fmc_i2c_in           : t_wishbone_master_in;
  signal fmc_i2c_out          : t_wishbone_master_out;

  -- spi controller to the flash
  signal flash_spi_in         : t_wishbone_master_in;
  signal flash_spi_out        : t_wishbone_master_out;

  -- vector interrupt controller
  signal vic_in               : t_wishbone_master_in;
  signal vic_out              : t_wishbone_master_out;

  -- white-rabbit core
  signal wrc_in               : t_wishbone_master_in;
  signal wrc_out              : t_wishbone_master_out;
  signal wrc_out_sh           : t_wishbone_master_out;

  signal csr_rst_gbl : std_logic;
  signal csr_rst_app : std_logic;

  signal rst_csr_app_n      : std_logic;
  signal rst_csr_app_sync_n : std_logic;

  signal rst_gbl_n : std_logic;

  signal fmc0_scl_out, fmc0_sda_out : std_logic;
  signal fmc0_scl_oen, fmc0_sda_oen : std_logic;
  signal fmc1_scl_out, fmc1_sda_out : std_logic;
  signal fmc1_scl_oen, fmc1_sda_oen : std_logic;

  signal fmc_presence : std_logic_vector(31 downto 0);

  signal irq_master : std_logic;

  constant num_interrupts : natural := 6 + g_NUM_USER_IRQ;
  signal irqs : std_logic_vector(num_interrupts - 1 downto 0);

  -- clock and reset
  signal rst_sys_62m5_n : std_logic;
  signal rst_ref_125m_n : std_logic;
  signal clk_ref_125m   : std_logic;

  -- I2C EEPROM
  signal eeprom_sda_in  : std_logic;
  signal eeprom_sda_out : std_logic;
  signal eeprom_scl_in  : std_logic;
  signal eeprom_scl_out : std_logic;

  -- SFP
  signal sfp_sda_in  : std_logic;
  signal sfp_sda_out : std_logic;
  signal sfp_scl_in  : std_logic;
  signal sfp_scl_out : std_logic;

  attribute keep                 : string;
  attribute keep of clk_sys_62m5 : signal is "TRUE";
  attribute keep of clk_ref_125m : signal is "TRUE";
  attribute keep of clk_ddr_333m : signal is "TRUE";
  attribute keep of ddr_rst      : signal is "TRUE";

begin  -- architecture top

  ------------------------------------------------------------------------------
  -- VME interface
  ------------------------------------------------------------------------------

  cmp_vme_core : entity work.xvme64x_core
    generic map (
      g_CLOCK_PERIOD    => 16,
      g_DECODE_AM       => TRUE,
      g_USER_CSR_EXT    => FALSE,
      g_WB_GRANULARITY  => BYTE,
      g_WB_MODE         => PIPELINED,
      g_MANUFACTURER_ID => c_CERN_ID,
      g_BOARD_ID        => c_SVEC_ID,
      g_REVISION_ID     => c_SVEC_REVISION_ID,
      g_PROGRAM_ID      => c_SVEC_PROGRAM_ID)
    port map (
      clk_i           => clk_sys_62m5,
      rst_n_i         => rst_sys_62m5_n,
      vme_i.as_n      => vme_as_n_i,
      vme_i.rst_n     => vme_sysreset_n_i,
      vme_i.write_n   => vme_write_n_i,
      vme_i.am        => vme_am_i,
      vme_i.ds_n      => vme_ds_n_i,
      vme_i.ga        => vme_ga,
      vme_i.lword_n   => vme_lword_n_b,
      vme_i.addr      => vme_addr_b,
      vme_i.data      => vme_data_b,
      vme_i.iack_n    => vme_iack_n_i,
      vme_i.iackin_n  => vme_iackin_n_i,
      vme_o.berr_n    => vme_berr_n,
      vme_o.dtack_n   => vme_dtack_n_o,
      vme_o.retry_n   => vme_retry_n_o,
      vme_o.retry_oe  => vme_retry_oe_o,
      vme_o.lword_n   => vme_lword_n_b_out,
      vme_o.data      => vme_data_b_out,
      vme_o.addr      => vme_addr_b_out,
      vme_o.irq_n     => vme_irq_n,
      vme_o.iackout_n => vme_iackout_n_o,
      vme_o.dtack_oe  => vme_dtack_oe_o,
      vme_o.data_dir  => vme_data_dir_int,
      vme_o.data_oe_n => vme_data_oe_n_o,
      vme_o.addr_dir  => vme_addr_dir_int,
      vme_o.addr_oe_n => vme_addr_oe_n_o,
      wb_o            => vme_wb_out,
      wb_i            => vme_wb_in,
      int_i           => irq_master);

  vme_ga     <= vme_gap_i & vme_ga_i;
  vme_berr_o <= not vme_berr_n;
  vme_irq_o  <= not vme_irq_n;

  -- VME tri-state buffers
  vme_data_b <= vme_data_b_out when vme_data_dir_int = '1' else (others => 'Z');
  vme_addr_b <= vme_addr_b_out when vme_addr_dir_int = '1' else (others => 'Z');
  vme_lword_n_b <= vme_lword_n_b_out when vme_addr_dir_int = '1' else 'Z';

  vme_addr_dir_o <= vme_addr_dir_int;
  vme_data_dir_o <= vme_data_dir_int;

  --  Mini-crossbar from vme to carrier and application bus.
  inst_split: entity work.xwb_split
    generic map (
      g_mask => x"ffff_e000"
    )
    port map (
      clk_sys_i => clk_sys_62m5,
      rst_n_i => rst_sys_62m5_n,
      slave_i => vme_wb_out,
      slave_o => vme_wb_in,
      master_i (0) => carrier_wb_out,
      master_i (1) => app_wb_i,
      master_o (0) => carrier_wb_in,
      master_o (1) => app_wb_o
    );

  inst_carrier: entity work.svec_base_regs
    port map (
      rst_n_i    => rst_sys_62m5_n,
      clk_i      => clk_sys_62m5,
      wb_cyc_i   => carrier_wb_in.cyc,
      wb_stb_i   => carrier_wb_in.stb,
      wb_adr_i   => carrier_wb_in.adr (12 downto 2),  -- Bytes address from vme64x core
      wb_sel_i   => carrier_wb_in.sel,
      wb_we_i    => carrier_wb_in.we,
      wb_dat_i   => carrier_wb_in.dat,
      wb_ack_o   => carrier_wb_out.ack,
      wb_err_o   => carrier_wb_out.err,
      wb_rty_o   => carrier_wb_out.rty,
      wb_stall_o => carrier_wb_out.stall,
      wb_dat_o   => carrier_wb_out.dat,

      -- a ROM containing the carrier metadata
      metadata_addr_o => metadata_addr,
      metadata_data_i => metadata_data,
      metadata_data_o => open,

      -- offset to the application metadata
      csr_app_offset_i    => g_APP_OFFSET,
      csr_resets_global_o => csr_rst_gbl,
      csr_resets_appl_o   => csr_rst_app,

      -- presence lines for the fmcs
      csr_fmc_presence_i  => fmc_presence,

      csr_ddr_status_ddr4_calib_done_i    => ddr4_calib_done,
      csr_ddr_status_ddr5_calib_done_i    => ddr5_calib_done,
      csr_pcb_rev_rev_i   => pcbrev_i,

      csr_ddr4_addr_i      => csr_ddr4_addr,
      csr_ddr4_addr_o      => csr_ddr4_addr_out,
      csr_ddr4_addr_wr_o   => csr_ddr4_addr_wr,
  
      -- data to read or to write in ddr4
      csr_ddr4_data_i      => csr_ddr4_data_in,
      csr_ddr4_data_o      => csr_ddr4_data_out,
      csr_ddr4_data_wr_o   => csr_ddr4_data_wr,
      csr_ddr4_data_rd_o   => csr_ddr4_data_rd,
      csr_ddr4_data_wack_i => csr_ddr4_data_wack,
      csr_ddr4_data_rack_i => csr_ddr4_data_rack,
  
      -- Thermometer and unique id
      therm_id_i          => therm_id_in,
      therm_id_o          => therm_id_out,

      -- i2c controllers to the fmcs
      fmc_i2c_i           => fmc_i2c_in,
      fmc_i2c_o           => fmc_i2c_out,

      -- spi controller to the flash
      flash_spi_i         => flash_spi_in,
      flash_spi_o         => flash_spi_out,

      -- vector interrupt controller
      vic_i               => vic_in,
      vic_o               => vic_out,

      -- a ROM containing build info
      buildinfo_addr_o => buildinfo_addr,
      buildinfo_data_i => buildinfo_data,
      buildinfo_data_o => open,

      -- white-rabbit core
      wrc_regs_i          => wrc_in,
      wrc_regs_o          => wrc_out
    );

  fmc_presence (0) <= not fmc0_prsnt_m2c_n_i;
  fmc_presence (1) <= not fmc1_prsnt_m2c_n_i;
  fmc_presence (31 downto 2) <= (others => '0');

  --  Metadata
  p_metadata: process (clk_sys_62m5) is
  begin
    if rising_edge(clk_sys_62m5) then
      case metadata_addr is
        when x"0" =>
          -- Vendor ID
          metadata_data <= x"000010dc";
        when x"1" =>
          -- Device ID
          metadata_data <= x"53564543";
        when x"2" =>
          -- Version
          metadata_data <= x"01040000";
        when x"3" =>
          -- BOM
          metadata_data <= x"fffe0000";
        when x"4" | x"5" | x"6" | x"7" =>
          -- source id
          metadata_data <= x"00000000";
        when x"8" =>
          -- capability mask
          metadata_data <= x"00000000";
          if g_WITH_VIC then
            metadata_data(0) <= '1';
          end if;
          if g_WITH_ONEWIRE and not g_WITH_WR then
            metadata_data(1) <= '1';
          end if;
          if g_WITH_SPI then
            metadata_data(2) <= '1';
          end if;
          if g_WITH_WR then
            metadata_data(3) <= '1';
          end if;
          --  Buildinfo
          metadata_data(4) <= '1';
          if g_WITH_DDR4 then
            metadata_data(5) <= '1';
          end if;
          if g_WITH_DDR5 then
            metadata_data(6) <= '1';
          end if;
        when others =>
          metadata_data <= x"00000000";
      end case;
    end if;
  end process;

  --  Build information
  p_buildinfo: process (clk_sys_62m5) is
    variable addr : natural;
    variable b : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk_sys_62m5) then
      addr := to_integer(unsigned(buildinfo_addr)) * 4;
      for i in 0 to 3 loop
        if addr + i < buildinfo'length then
           b := std_logic_vector(to_unsigned(character'pos(
             buildinfo(buildinfo'left + addr + i)), 8));
        else
           b := x"00";
        end if;
        buildinfo_data (7 + i * 8 downto i * 8) <= b;
      end loop;
    end if;
  end process;

  rst_gbl_n <= rst_sys_62m5_n and (not csr_rst_gbl);

  -- reset for DDR including soft reset.
  -- This is treated as async and will be re-synced by the DDR controller
  ddr_rst <= not rst_ddr_333m_n or csr_rst_gbl;

  rst_csr_app_n <= not (csr_rst_gbl or csr_rst_app);

  rst_sys_62m5_n_o <= rst_sys_62m5_n and rst_csr_app_n;
  clk_sys_62m5_o <= clk_sys_62m5;

  i_rst_csr_app_sync : gc_sync_ffs
    port map (
      clk_i    => clk_ref_125m,
      rst_n_i  => '1',
      data_i   => rst_csr_app_n,
      synced_o => rst_csr_app_sync_n);

  rst_ref_125m_n_o <= rst_ref_125m_n and rst_csr_app_sync_n;
  clk_ref_125m_o   <= clk_ref_125m;

  inst_i2c: entity work.xwb_i2c_master
    generic map (
      g_interface_mode      => CLASSIC,
      g_address_granularity => BYTE,
      g_num_interfaces      => 2)
    port map (
      clk_sys_i => clk_sys_62m5,
      rst_n_i   => rst_gbl_n,

      slave_i => fmc_i2c_out,
      slave_o => fmc_i2c_in,
      desc_o  => open,

      int_o   => irqs(0),

      scl_pad_i (0)    => fmc0_scl_b,
      scl_pad_i (1)    => fmc1_scl_b,
      scl_pad_o (0)    => fmc0_scl_out,
      scl_pad_o (1)    => fmc1_scl_out,
      scl_padoen_o (0) => fmc0_scl_oen,
      scl_padoen_o (1) => fmc1_scl_oen,
      sda_pad_i (0)    => fmc0_sda_b,
      sda_pad_i (1)    => fmc1_sda_b,
      sda_pad_o (0)    => fmc0_sda_out,
      sda_pad_o (1)    => fmc1_sda_out,
      sda_padoen_o (0) => fmc0_sda_oen,
      sda_padoen_o (1) => fmc1_sda_oen
    );

  fmc0_scl_b <= fmc0_scl_out when fmc0_scl_oen = '0' else 'Z';
  fmc0_sda_b <= fmc0_sda_out when fmc0_sda_oen = '0' else 'Z';

  fmc1_scl_b <= fmc1_scl_out when fmc1_scl_oen = '0' else 'Z';
  fmc1_sda_b <= fmc1_sda_out when fmc1_sda_oen = '0' else 'Z';

  gen_user_irq: if g_NUM_USER_IRQ > 0 generate
    irqs(irq_user_i'range) <= irq_user_i;
  end generate gen_user_irq;

  gen_vic: if g_with_vic generate
    i_vic: entity work.xwb_vic
      generic map (
        g_address_granularity => BYTE,
        g_num_interrupts => num_interrupts
      )
      port map (
        clk_sys_i => clk_sys_62m5,
        rst_n_i => rst_gbl_n,
        slave_i => vic_out,
        slave_o => vic_in,
        irqs_i => irqs,
        irq_master_o => irq_master
      );
  end generate;

  gen_no_vic: if not g_with_vic generate
    vic_in <= (ack => '1', err => '0', rty => '0', stall => '0', dat => x"00000000");
    irq_master <= '0';
  end generate;

  irqs(4) <= '0';
  irqs(5) <= '0';

  -----------------------------------------------------------------------------
  -- The WR PTP core board package (WB Slave + WB Master #2 (Etherbone))
  -----------------------------------------------------------------------------

  gen_wr: if g_WITH_WR generate
    -- OneWire
    signal onewire_data : std_logic;
    signal onewire_oe   : std_logic;
  begin
    --  Remap WR registers.
    wrc_out_sh <= (cyc => wrc_out.cyc, stb => wrc_out.stb,
                   adr => wrc_out.adr or x"00020000",
                   sel => wrc_out.sel, we => wrc_out.we, dat => wrc_out.dat);

    cmp_xwrc_board_svec : xwrc_board_svec
      generic map (
        g_simulation                => g_SIMULATION,
        g_VERBOSE                   => g_VERBOSE,
        g_with_external_clock_input => TRUE,
        g_dpram_initf               => g_DPRAM_INITF,
        g_AUX_CLKS                  => g_AUX_CLKS,
        g_AUX_PLL_CFG               => c_WRPC_PLL_CONFIG,
        g_STREAMERS_OP_MODE         => g_STREAMERS_OP_MODE,
        g_TX_STREAMER_PARAMS        => g_TX_STREAMER_PARAMS,
        g_RX_STREAMER_PARAMS        => g_RX_STREAMER_PARAMS,
        g_FABRIC_IFACE              => g_FABRIC_IFACE)
      port map (
        areset_n_i          => rst_n_i,
        clk_20m_vcxo_i      => clk_20m_vcxo_i,
        clk_125m_pllref_p_i => clk_125m_pllref_p_i,
        clk_125m_pllref_n_i => clk_125m_pllref_n_i,
        clk_125m_gtp_n_i    => clk_125m_gtp_n_i,
        clk_125m_gtp_p_i    => clk_125m_gtp_p_i,
        clk_aux_i           => clk_aux_i,
        clk_10m_ext_i       => clk_10m_ext_i,
        pps_ext_i           => pps_ext_i,

        clk_sys_62m5_o      => clk_sys_62m5,
        clk_ref_125m_o      => clk_ref_125m,
        clk_pll_aux_o       => clk_pll_aux,
        rst_sys_62m5_n_o    => rst_sys_62m5_n,
        rst_ref_125m_n_o    => rst_ref_125m_n,
        rst_pll_aux_n_o     => rst_pll_aux_n,

        pll20dac_din_o      => pll20dac_din_o,
        pll20dac_sclk_o     => pll20dac_sclk_o,
        pll20dac_sync_n_o   => pll20dac_sync_n_o,
        pll25dac_din_o      => pll25dac_din_o,
        pll25dac_sclk_o     => pll25dac_sclk_o,
        pll25dac_sync_n_o   => pll25dac_sync_n_o,

        sfp_txp_o           => sfp_txp_o,
        sfp_txn_o           => sfp_txn_o,
        sfp_rxp_i           => sfp_rxp_i,
        sfp_rxn_i           => sfp_rxn_i,
        sfp_det_i           => sfp_mod_def0_i,
        sfp_sda_i           => sfp_sda_in,
        sfp_sda_o           => sfp_sda_out,
        sfp_scl_i           => sfp_scl_in,
        sfp_scl_o           => sfp_scl_out,
        sfp_rate_select_o   => sfp_rate_select_o,
        sfp_tx_fault_i      => sfp_tx_fault_i,
        sfp_tx_disable_o    => sfp_tx_disable_o,
        sfp_los_i           => sfp_los_i,

        eeprom_sda_i        => eeprom_sda_in,
        eeprom_sda_o        => eeprom_sda_out,
        eeprom_scl_i        => eeprom_scl_in,
        eeprom_scl_o        => eeprom_scl_out,

        onewire_i           => onewire_data,
        onewire_oen_o       => onewire_oe,
        -- Uart
        uart_rxd_i          => uart_rxd_i,
        uart_txd_o          => uart_txd_o,
        -- SPI Flash (not used)
        spi_sclk_o          => open,
        spi_ncs_o           => open,
        spi_mosi_o          => open,
        spi_miso_i          => '0',

        wb_slave_o          => wrc_in,
        wb_slave_i          => wrc_out_sh,

        wrf_src_o           => wrf_src_o,
        wrf_src_i           => wrf_src_i,
        wrf_snk_o           => wrf_snk_o,
        wrf_snk_i           => wrf_snk_i,
        wrs_tx_data_i       => wrs_tx_data_i,
        wrs_tx_valid_i      => wrs_tx_valid_i,
        wrs_tx_dreq_o       => wrs_tx_dreq_o,
        wrs_tx_last_i       => wrs_tx_last_i,
        wrs_tx_flush_i      => wrs_tx_flush_i,
        wrs_tx_cfg_i        => wrs_tx_cfg_i,
        wrs_rx_first_o      => wrs_rx_first_o,
        wrs_rx_last_o       => wrs_rx_last_o,
        wrs_rx_data_o       => wrs_rx_data_o,
        wrs_rx_valid_o      => wrs_rx_valid_o,
        wrs_rx_dreq_i       => wrs_rx_dreq_i,
        wrs_rx_cfg_i        => wrs_rx_cfg_i,
        wb_eth_master_o     => wb_eth_master_o,
        wb_eth_master_i     => wb_eth_master_i,

        tm_link_up_o        => tm_link_up_o,
        tm_time_valid_o     => tm_time_valid_o,
        tm_tai_o            => tm_tai_o,
        tm_cycles_o         => tm_cycles_o,

        tm_dac_value_o       => tm_dac_value_o,
        tm_dac_wr_o          => tm_dac_wr_o,
        tm_clk_aux_lock_en_i => tm_clk_aux_lock_en_i,
        tm_clk_aux_locked_o  => tm_clk_aux_locked_o,

        pps_p_o             => pps_p_o,
        pps_led_o           => pps_led_o,
        link_ok_o           => link_ok_o,
        led_link_o          => led_link_o,
        led_act_o           => led_act_o);

    clk_ddr_333m   <= clk_pll_aux(0);
    rst_ddr_333m_n <= rst_pll_aux_n(0);

    -- Tristates for SFP EEPROM
    sfp_mod_def1_b <= '0' when sfp_scl_out = '0' else 'Z';
    sfp_mod_def2_b <= '0' when sfp_sda_out = '0' else 'Z';
    sfp_scl_in     <= sfp_mod_def1_b;
    sfp_sda_in     <= sfp_mod_def2_b;

    -- Tristates for Carrier EEPROM
    carrier_scl_b <= '0' when (eeprom_scl_out = '0') else 'Z';
    carrier_sda_b <= '0' when (eeprom_sda_out = '0') else 'Z';
    eeprom_scl_in <= carrier_scl_b;
    eeprom_sda_in <= carrier_sda_b;

    -- tri-state onewire access
    onewire_b    <= '0' when (onewire_oe = '1') else 'Z';
    onewire_data <= onewire_b;

    --  WR means neither onewire nor spi.
    assert not g_WITH_ONEWIRE report "WR is not yet compatible with ONEWIRE"
      severity failure;
    therm_id_in <= (ack => '1', err => '0', rty => '0', stall => '0',
      dat => (others => '0'));
  end generate;

  gen_no_wr: if not g_WITH_WR generate
    signal clk_125m_pllref : std_logic;
    signal pllout_clk_fb_pllref : std_logic;
    signal pllout_clk_62m5 : std_logic;
    signal pllout_clk_125m : std_logic;
    signal pllout_clk_333m : std_logic;
    signal pllout_locked : std_logic;
    signal rstlogic_arst : std_logic;
  begin
    -- Input clock
    cmp_pllrefclk_buf : IBUFGDS
      generic map (
        DIFF_TERM    => true,             -- Differential Termination
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O  => clk_125m_pllref,            -- Buffer output
        I  => clk_125m_pllref_p_i,  -- Diff_p buffer input (connect directly to top-level port)
        IB => clk_125m_pllref_n_i  -- Diff_n buffer input (connect directly to top-level port)
      );

    cmp_sys_clk_pll : PLL_BASE
      generic map (
        BANDWIDTH          => "OPTIMIZED",
        CLK_FEEDBACK       => "CLKFBOUT",
        COMPENSATION       => "INTERNAL",
        DIVCLK_DIVIDE      => 1,
        CLKFBOUT_MULT      => 8,
        CLKFBOUT_PHASE     => 0.000,
        CLKOUT0_DIVIDE     => 16,        -- 62.5 MHz
        CLKOUT0_PHASE      => 0.000,
        CLKOUT0_DUTY_CYCLE => 0.500,
        CLKOUT1_DIVIDE     => 8,         -- 125 MHz
        CLKOUT1_PHASE      => 0.000,
        CLKOUT1_DUTY_CYCLE => 0.500,
        CLKOUT2_DIVIDE     => 3,         -- 333 MHz
        CLKOUT2_PHASE      => 0.000,
        CLKOUT2_DUTY_CYCLE => 0.500,
        CLKIN_PERIOD       => 8.0,
        REF_JITTER         => 0.016)
      port map (
        CLKFBOUT => pllout_clk_fb_pllref,
        CLKOUT0  => pllout_clk_62m5,
        CLKOUT1  => pllout_clk_125m,
        CLKOUT2  => pllout_clk_333m,
        CLKOUT3  => open,
        CLKOUT4  => open,
        CLKOUT5  => open,
        LOCKED   => pllout_locked,
        RST      => '0',
        CLKFBIN  => pllout_clk_fb_pllref,
        CLKIN    => clk_125m_pllref);

    cmp_clk_62m5_buf : BUFG
      port map (
        O => clk_sys_62m5,
        I => pllout_clk_62m5);

    cmp_clk_125m_buf : BUFG
      port map (
        O => clk_ref_125m,
        I => pllout_clk_125m);

    cmp_clk_333m_buf : BUFG
      port map (
        O => clk_ddr_333m,
        I => pllout_clk_333m);

    -- logic AND of all async reset sources (active high)
    rstlogic_arst <= (not pllout_locked) and (not rst_n_i);

    -- Clocks required to have synced resets
    cmp_rstlogic_reset : gc_reset_multi_aasd
      generic map (
        g_CLOCKS  => 3,
        g_RST_LEN => 16)  -- 16 clock cycles
      port map (
        arst_i  => rstlogic_arst,
        clks_i (0)  => clk_sys_62m5,
        clks_i (1)  => clk_ref_125m,
        clks_i (2)  => clk_ddr_333m,
        rst_n_o (0) => rst_sys_62m5_n,
        rst_n_o (1) => rst_ref_125m_n,
        rst_n_o (2) => rst_ddr_333m_n);

    --  Not used.
    wrc_in <= (ack => '1', err => '0', rty => '0', stall => '0', dat => x"00000000");
  end generate;

  gen_onewire: if g_WITH_ONEWIRE and not g_WITH_WR generate
    i_onewire: entity work.xwb_ds182x_readout
      generic map (
        g_CLOCK_FREQ_KHZ => 62_500,
        g_USE_INTERNAL_PPS => True)
      port map (
        clk_i => clk_sys_62m5,
        rst_n_i => rst_gbl_n,

        wb_i => therm_id_out,
        wb_o => therm_id_in,

        pps_p_i => '0',
        onewire_b => onewire_b
      );
  end generate;

  gen_no_onewire: if not g_WITH_ONEWIRE and not g_WITH_WR generate
    therm_id_in <= (ack => '1', err => '0', rty => '0', stall => '0', dat => x"00000000");
    onewire_b <= 'Z';
  end generate;

  gen_spi: if g_WITH_SPI generate
    i_spi: entity work.xwb_spi
      generic map (
        g_interface_mode => CLASSIC,
        g_address_granularity => BYTE,
        g_divider_len => open,
        g_max_char_len => open,
        g_num_slaves => 1
      )
      port map (
        clk_sys_i => clk_sys_62m5,
        rst_n_i => rst_gbl_n,
        slave_i => flash_spi_out,
        slave_o => flash_spi_in,
        desc_o => open,
        int_o => irqs(1),
        pad_cs_o(0) => spi_ncs_o,
        pad_sclk_o => spi_sclk_o,
        pad_mosi_o => spi_mosi_o,
        pad_miso_i => spi_miso_i
      );
  end generate;

  gen_no_spi : if not g_WITH_SPI generate
    flash_spi_in <= (ack => '1', err => '0', rty => '0', stall => '0', dat => x"00000000");
    irqs(1)      <= '0';
    spi_ncs_o    <= '1';
    spi_sclk_o   <= '0';
    spi_mosi_o   <= '0';
  end generate;

  --  DDR3 controller
  gen_with_ddr4: if g_WITH_DDR4 generate
    cmp_ddr_ctrl_bank : entity work.ddr3_ctrl
      generic map(
        g_RST_ACT_LOW         => 0, -- active high reset (simpler internal logic)
        g_BANK_PORT_SELECT    => "SVEC_BANK4_64B_32B",
        g_MEMCLK_PERIOD       => 3000,
        g_SIMULATION          => to_upper(boolean'image(g_SIMULATION /= 0)),
        g_CALIB_SOFT_IP       => to_upper(boolean'image(g_SIMULATION = 0)),
        g_P0_MASK_SIZE        => 8,
        g_P0_DATA_PORT_SIZE   => 64,
        g_P0_BYTE_ADDR_WIDTH  => 30,
        g_P0_ADDR_GRANULARITY => WORD,
        g_P1_MASK_SIZE        => 4,
        g_P1_DATA_PORT_SIZE   => 32,
        g_P1_BYTE_ADDR_WIDTH  => 30,
        g_P1_ADDR_GRANULARITY => BYTE)
      port map (
        clk_i   => clk_ddr_333m,
        rst_n_i => ddr_rst,

        status_o => ddr4_status,

        ddr3_dq_b     => ddr4_dq_b,
        ddr3_a_o      => ddr4_a_o,
        ddr3_ba_o     => ddr4_ba_o(2 downto 0),
        ddr3_ras_n_o  => ddr4_ras_n_o,
        ddr3_cas_n_o  => ddr4_cas_n_o,
        ddr3_we_n_o   => ddr4_we_n_o,
        ddr3_odt_o    => ddr4_odt_o,
        ddr3_rst_n_o  => ddr4_reset_n_o,
        ddr3_cke_o    => ddr4_cke_o,
        ddr3_dm_o     => ddr4_ldm_o,
        ddr3_udm_o    => ddr4_udm_o,
        ddr3_dqs_p_b  => ddr4_ldqs_p_b,
        ddr3_dqs_n_b  => ddr4_ldqs_n_b,
        ddr3_udqs_p_b => ddr4_udqs_p_b,
        ddr3_udqs_n_b => ddr4_udqs_n_b,
        ddr3_clk_p_o  => ddr4_ck_p_o,
        ddr3_clk_n_o  => ddr4_ck_n_o,
        ddr3_rzq_b    => ddr4_rzq_b,

        wb0_rst_n_i => ddr4_rst_n_i,
        wb0_clk_i   => ddr4_clk_i,
        wb0_sel_i   => ddr4_wb_i.sel,
        wb0_cyc_i   => ddr4_wb_i.cyc,
        wb0_stb_i   => ddr4_wb_i.stb,
        wb0_we_i    => ddr4_wb_i.we,
        wb0_addr_i  => ddr4_wb_i.adr,
        wb0_data_i  => ddr4_wb_i.dat,
        wb0_data_o  => ddr4_wb_o.dat,
        wb0_ack_o   => ddr4_wb_o.ack,
        wb0_stall_o => ddr4_wb_o.stall,

        p0_cmd_empty_o   => open,
        p0_cmd_full_o    => open,
        p0_rd_full_o     => open,
        p0_rd_empty_o    => open,
        p0_rd_count_o    => open,
        p0_rd_overflow_o => open,
        p0_rd_error_o    => open,
        p0_wr_full_o     => open,
        p0_wr_empty_o    => ddr4_wr_fifo_empty_o,
        p0_wr_count_o    => open,
        p0_wr_underrun_o => open,
        p0_wr_error_o    => open,

        wb1_rst_n_i => rst_gbl_n,
        wb1_clk_i   => clk_sys_62m5,
        wb1_sel_i   => ddr4_wb_out.sel,
        wb1_cyc_i   => ddr4_wb_out.cyc,
        wb1_stb_i   => ddr4_wb_out.stb,
        wb1_we_i    => ddr4_wb_out.we,
        wb1_addr_i  => ddr4_wb_out.adr,
        wb1_data_i  => ddr4_wb_out.dat,
        wb1_data_o  => ddr4_wb_in.dat,
        wb1_ack_o   => ddr4_wb_in.ack,
        wb1_stall_o => ddr4_wb_in.stall,

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

    ddr4_calib_done <= ddr4_status(0);

    -- unused Wishbone signals
    ddr4_wb_in.err <= '0';
    ddr4_wb_in.rty <= '0';

    p_ddr4_addr: process (clk_sys_62m5)
    begin
      if rising_edge(clk_sys_62m5) then
        if rst_sys_62m5_n = '0' then
          csr_ddr4_addr <= x"0000_0000";
        elsif csr_ddr4_addr_wr = '1' then
          csr_ddr4_addr <= csr_ddr4_addr_out;
        elsif ddr4_wb_in.ack = '1' then
          csr_ddr4_addr <= std_logic_vector(unsigned(csr_ddr4_addr) + 4);
        end if;
      end if;
    end process;

    p_ddr4_ack: process (clk_sys_62m5)
    begin
      if rising_edge(clk_sys_62m5) then
        if rst_sys_62m5_n = '0' then
          ddr4_read_ip <= '0';
          ddr4_write_ip <= '0';
        else
          ddr4_read_ip <= csr_ddr4_data_rd or (ddr4_read_ip and not ddr4_wb_in.ack);
          ddr4_write_ip <= csr_ddr4_data_wr or (ddr4_write_ip and not ddr4_wb_in.ack);
        end if;
      end if;
    end process;

    ddr4_wb_out <= (adr => csr_ddr4_addr,
                    cyc => csr_ddr4_data_rd or csr_ddr4_data_wr or ddr4_read_ip or ddr4_write_ip,
                    stb => csr_ddr4_data_rd or csr_ddr4_data_wr,
                    sel => x"f",
                    we => csr_ddr4_data_wr,
                    dat => csr_ddr4_data_out);
    csr_ddr4_data_in <= ddr4_wb_in.dat;
    csr_ddr4_data_rack <= ddr4_read_ip and ddr4_wb_in.ack;
    csr_ddr4_data_wack <= ddr4_write_ip and ddr4_wb_in.ack;
 end generate gen_with_ddr4;

  gen_without_ddr4 : if not g_WITH_DDR4 generate
    ddr4_calib_done      <= '0';
    ddr4_wb_in           <= c_DUMMY_WB_MASTER_IN;
    ddr4_a_o             <= (others => '0');
    ddr4_ba_o            <= (others => '0');
    ddr4_dq_b            <= (others => 'Z');
    ddr4_cas_n_o         <= '0';
    ddr4_ck_p_o          <= '0';
    ddr4_ck_n_o          <= '0';
    ddr4_cke_o           <= '0';
    ddr4_ldm_o           <= '0';
    ddr4_ldqs_n_b        <= 'Z';
    ddr4_ldqs_p_b        <= 'Z';
    ddr4_udqs_n_b        <= 'Z';
    ddr4_udqs_p_b        <= 'Z';
    ddr4_odt_o           <= '0';
    ddr4_udm_o           <= '0';
    ddr4_ras_n_o         <= '0';
    ddr4_reset_n_o       <= '0';
    ddr4_we_n_o          <= '0';
    ddr4_rzq_b           <= 'Z';
    ddr4_wb_o.dat    <= (others => '0');
    ddr4_wb_o.ack    <= '1';
    ddr4_wb_o.stall  <= '0';
    ddr4_wr_fifo_empty_o <= '0';

    csr_ddr4_addr <= x"0000_0000";
    ddr4_wb_out <= (adr => (others => 'X'), cyc => '0', stb => '0', sel => x"0", we => '0',
      dat => (others => 'X'));
    csr_ddr4_data_in <= x"0000_0000";
    csr_ddr4_data_rack <= csr_ddr4_data_wr;
    csr_ddr4_data_wack <= csr_ddr4_data_wr;
  end generate gen_without_ddr4;

  ddr4_wb_o.err <= '0';
  ddr4_wb_o.rty <= '0';

  --  TODO
  ddr5_wb_out <= (adr => (others => 'X'), cyc => '0', stb => '0', sel => x"0", we => '0',
     dat => (others => 'X'));
end architecture top;
