--------------------------------------------------------------------------------


library ieee;
library std;
library work;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use IEEE.numeric_std.unsigned;
use work.VME_CR_pack.all;
use work.VME_CSR_pack.all;
use work.VME64xSim.all;
use work.VME64x.all;
use work.wishbone_pkg.all;
use std.textio.all;
use work.vme64x_pack.all;

entity vme64x_ddr_tb is
end vme64x_ddr_tb;

architecture behavior of vme64x_ddr_tb is

  -- Component Declaration for the Unit Under Test (UUT)

  ------------------------------------------------------------------------------
  -- Top level
  ------------------------------------------------------------------------------
  component svec_afpga_top
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
        rst_n_i      : in std_logic;
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
        --ddr_we_n_o    : out   std_logic;
        --ddr_udqs_p_b  : inout std_logic;
        --ddr_udqs_n_b  : inout std_logic;
        --ddr_udm_o     : out   std_logic;
        --ddr_reset_n_o : out   std_logic;
        --ddr_ras_n_o   : out   std_logic;
        --ddr_odt_o     : out   std_logic;
        --ddr_ldqs_p_b  : inout std_logic;
        --ddr_ldqs_n_b  : inout std_logic;
        --ddr_ldm_o     : out   std_logic;
        --ddr_cke_o     : out   std_logic;
        --ddr_ck_p_o    : out   std_logic;
        --ddr_ck_n_o    : out   std_logic;
        --ddr_cas_n_o   : out   std_logic;
        --ddr_dq_b      : inout std_logic_vector(15 downto 0);
        --ddr_ba_o      : out   std_logic_vector(2 downto 0);
        --ddr_a_o       : out   std_logic_vector(13 downto 0);
        --ddr_zio_b     : inout std_logic;
        --ddr_rzq_b     : inout std_logic;

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
        fp_gpio_b      : inout std_logic_vector(4 downto 1);
        fpgpio1_a2b_o  : out   std_logic;
        fpgpio2_a2b_o  : out   std_logic;
        fpgpio34_a2b_o : out   std_logic;
        term_en_o      : out   std_logic_vector(4 downto 1);
        fp_led_n_o     : out   std_logic_vector(7 downto 0);

        ------------------------------------------
        -- 1-wire thermoeter + unique ID
        ------------------------------------------
        tempid_dq_b : inout std_logic;

        ------------------------------------------
        -- Debug LEDs
        ------------------------------------------
        dbg_led_n_o : out std_logic_vector(4 downto 1)

        );
  end component svec_afpga_top;

  ------------------------------------------------------------------------------
  -- DDR3 model
  ------------------------------------------------------------------------------
  component ddr3
    port (
      rst_n   : in    std_logic;
      ck      : in    std_logic;
      ck_n    : in    std_logic;
      cke     : in    std_logic;
      cs_n    : in    std_logic;
      ras_n   : in    std_logic;
      cas_n   : in    std_logic;
      we_n    : in    std_logic;
      dm_tdqs : inout std_logic_vector(1 downto 0);
      ba      : in    std_logic_vector(2 downto 0);
      addr    : in    std_logic_vector(13 downto 0);
      dq      : inout std_logic_vector(15 downto 0);
      dqs     : inout std_logic_vector(1 downto 0);
      dqs_n   : inout std_logic_vector(1 downto 0);
      tdqs_n  : out   std_logic_vector(1 downto 0);
      odt     : in    std_logic
      );
  end component;



  --Inputs
  signal clk_i          : std_logic                    := '0';
  signal VME_AS_n_i     : std_logic                    := '0';
  signal VME_RST_n_i    : std_logic                    := '0';
  signal VME_WRITE_n_i  : std_logic                    := '0';
  signal VME_AM_i       : std_logic_vector(5 downto 0) := (others => '0');
  signal VME_DS_n_i     : std_logic_vector(1 downto 0) := (others => '0');
  signal VME_GA_i       : std_logic_vector(5 downto 0) := (others => '0');
  signal VME_BBSY_n_i   : std_logic                    := '0';
  signal VME_IACKIN_n_i : std_logic                    := '1';
  signal VME_IACK_n_i   : std_logic                    := '1';
  signal Reset          : std_logic                    := '1';

  --BiDirs
  signal VME_LWORD_n_b : std_logic;
  signal VME_ADDR_b    : std_logic_vector(31 downto 1);
  signal VME_DATA_b    : std_logic_vector(31 downto 0);

  --Outputs
  signal VME_BERR_o      : std_logic;
  signal VME_DTACK_n_o   : std_logic;
  signal VME_RETRY_n_o   : std_logic;
  signal VME_RETRY_OE_o  : std_logic;
  signal VME_IRQ_n_o     : std_logic_vector(6 downto 0);
  signal VME_IACKOUT_n_o : std_logic;
  signal VME_DTACK_OE_o  : std_logic;
  signal VME_DATA_DIR_o  : std_logic;
  signal VME_DATA_OE_N_o : std_logic;
  signal VME_ADDR_DIR_o  : std_logic;
  signal VME_ADDR_OE_N_o : std_logic;

  -- Flags
  signal ReadInProgress  : std_logic := '0';
  signal WriteInProgress : std_logic := '0';

  signal s_Buffer_BLT       : t_Buffer_BLT;
  signal s_Buffer_MBLT      : t_Buffer_MBLT;
  signal s_dataTransferType : t_dataTransferType;
  signal s_AddressingType   : t_Addressing_Type;

  -- Control signals
  signal s_dataToSendOut : std_logic_vector(31 downto 0);
  signal s_dataToSend    : std_logic_vector(31 downto 0);
  signal s_dataToReceive : std_logic_vector(31 downto 0);
  signal s_address       : std_logic_vector(63 downto 0);
  signal localAddress    : std_logic_vector(19 downto 0);
  signal s_num           : std_logic_vector(8 downto 0);
  signal s_temp          : std_logic_vector(31 downto 0);
  signal s_beat_count    : std_logic_vector(7 downto 0);
  -- Records
  signal VME64xBus_out   : VME64xBusOut_Record;
  signal VME64xBus_in    : VME64xBusIn_Record;

  -- Power-ON reset
  signal rst_n_i : std_logic := '1';

  -- PCB revision ID
  signal pcbrev_i : std_logic_vector(4 downto 0) := "00001";

  -- DDR3 on bank 5
  signal ddr_2_we_n_o    : std_logic;
  signal ddr_2_dqs_p_b  : std_logic_vector(1 downto 0) := (others => 'Z');
  signal ddr_2_dqs_n_b  : std_logic_vector(1 downto 0) := (others => 'Z');
  signal ddr_2_dm_o     : std_logic_vector(1 downto 0) := (others => 'Z');
  signal ddr_2_reset_n_o : std_logic;
  signal ddr_2_ras_n_o   : std_logic;
  signal ddr_2_odt_o     : std_logic;
  signal ddr_2_cke_o     : std_logic;
  signal ddr_2_ck_p_o    : std_logic;
  signal ddr_2_ck_n_o    : std_logic;
  signal ddr_2_cas_n_o   : std_logic;
  signal ddr_2_dq_b      : std_logic_vector(15 downto 0) := (others => 'Z');
  signal ddr_2_ba_o      : std_logic_vector(2 downto 0);
  signal ddr_2_a_o       : std_logic_vector(13 downto 0);
  signal ddr_2_zio_b     : std_logic := 'Z';
  signal ddr_2_rzq_b     : std_logic;

  -- FMC slots
  signal fmc1_prsntm2c_n_i : std_logic := '1';
  signal fmc2_prsntm2c_n_i : std_logic := '1';

  -- Front panel
  signal fp_gpio_b      : std_logic_vector(4 downto 1) := (others => 'Z');
  signal fpgpio1_a2b_o  : std_logic;
  signal fpgpio2_a2b_o  : std_logic;
  signal fpgpio34_a2b_o : std_logic;
  signal term_en_o      : std_logic_vector(4 downto 1);
  signal fp_led_n_o     : std_logic_vector(7 downto 0);

  -- Temperature sensor
  signal tempid_dq_b : std_logic := 'Z';

  -- Debug LEDs
  signal dbg_led_n_o : std_logic_vector(4 downto 1);

  -- Clock period definitions
  constant clk_i_period : time := 50 ns;

begin

  -- Instantiate the Unit Under Test (UUT)
  uut : svec_afpga_top
    generic map(
      g_CARRIER_TYPE   => X"0002",
      g_BITSTREAM_TYPE => X"00002222",
      g_BITSTREAM_DATE => X"4FE9BABD",
      g_SIMULATION     => "TRUE",
      g_CALIB_SOFT_IP  => "TRUE")
    port map(
      vme_write_n_i    => VME_WRITE_n_i,
      vme_sysreset_n_i => VME_RST_n_i,
      vme_retry_oe_o   => VME_RETRY_OE_o,
      vme_retry_n_o    => VME_RETRY_n_o,
      vme_lword_n_b    => VME_LWORD_n_b,
      vme_iackout_n_o  => VME_IACKOUT_n_o,
      vme_iackin_n_i   => VME_IACKIN_n_i,
      vme_iack_n_i     => VME_IACK_n_i,
      vme_gap_n_i      => VME_GA_i(5),
      vme_dtack_oe_o   => VME_DTACK_OE_o,
      vme_dtack_n_o    => VME_DTACK_n_o,
      vme_ds_n_i       => VME_DS_n_i,
      vme_d_oe_n_o     => VME_DATA_OE_N_o,
      vme_d_dir_o      => VME_DATA_DIR_o,
      vme_berr_o       => VME_BERR_o,
      vme_as_n_i       => VME_AS_n_i,
      vme_a_oe_n_o     => VME_ADDR_OE_N_o,
      vme_a_dir_o      => VME_ADDR_DIR_o,
      vme_irq_n_o      => VME_IRQ_n_o,
      vme_ga_i         => VME_GA_i(4 downto 0),
      vme_d_b          => VME_DATA_b,
      vme_am_i         => VME_AM_i,
      vme_a_b          => VME_ADDR_b,

      rst_n_i      => rst_n_i,
      clk20_vcxo_i => clk_i,

      pcbrev_i => pcbrev_i,

      ddr_2_we_n_o    => ddr_2_we_n_o,
      ddr_2_udqs_p_b  => ddr_2_dqs_p_b(1),
      ddr_2_udqs_n_b  => ddr_2_dqs_n_b(1),
      ddr_2_udm_o     => ddr_2_dm_o(1),
      ddr_2_reset_n_o => ddr_2_reset_n_o,
      ddr_2_ras_n_o   => ddr_2_ras_n_o,
      ddr_2_odt_o     => ddr_2_odt_o,
      ddr_2_ldqs_p_b  => ddr_2_dqs_p_b(0),
      ddr_2_ldqs_n_b  => ddr_2_dqs_n_b(0),
      ddr_2_ldm_o     => ddr_2_dm_o(0),
      ddr_2_cke_o     => ddr_2_cke_o,
      ddr_2_ck_p_o    => ddr_2_ck_p_o,
      ddr_2_ck_n_o    => ddr_2_ck_n_o,
      ddr_2_cas_n_o   => ddr_2_cas_n_o,
      ddr_2_dq_b      => ddr_2_dq_b,
      ddr_2_ba_o      => ddr_2_ba_o,
      ddr_2_a_o       => ddr_2_a_o,
      ddr_2_zio_b     => ddr_2_zio_b,
      ddr_2_rzq_b     => ddr_2_rzq_b,

      fmc1_prsntm2c_n_i => fmc1_prsntm2c_n_i,
      fmc2_prsntm2c_n_i => fmc2_prsntm2c_n_i,

      fp_gpio_b      => fp_gpio_b,
      fpgpio1_a2b_o  => fpgpio1_a2b_o,
      fpgpio2_a2b_o  => fpgpio2_a2b_o,
      fpgpio34_a2b_o => fpgpio34_a2b_o,
      term_en_o      => term_en_o,
      fp_led_n_o     => fp_led_n_o,

      tempid_dq_b => tempid_dq_b,

      dbg_led_n_o => dbg_led_n_o
      );

  cmp_ddr3_bank5 : ddr3
    port map(
      rst_n   => ddr_2_reset_n_o,
      ck      => ddr_2_ck_p_o,
      ck_n    => ddr_2_ck_n_o,
      cke     => ddr_2_cke_o,
      cs_n    => '0',                   -- Pulled down on PCB
      ras_n   => ddr_2_ras_n_o,
      cas_n   => ddr_2_cas_n_o,
      we_n    => ddr_2_we_n_o,
      dm_tdqs => ddr_2_dm_o,
      ba      => ddr_2_ba_o,
      addr    => ddr_2_a_o,
      dq      => ddr_2_dq_b,
      dqs     => ddr_2_dqs_p_b,
      dqs_n   => ddr_2_dqs_n_b,
      tdqs_n  => open,                  -- dqs outputs for chaining
      odt     => ddr_2_odt_o
      );


  VME_IACKIN_n_i             <= VME64xBus_out.Vme64xIACKIN;
  VME_IACK_n_i               <= VME64xBus_out.Vme64xIACK;
  VME_AS_n_i                 <= VME64xBus_out.Vme64xAsN;
  VME_WRITE_n_i              <= VME64xBus_out.Vme64xWRITEN;
  VME_AM_i                   <= VME64xBus_out.Vme64xAM;
  VME_DS_n_i(1)              <= VME64xBus_out.Vme64xDs1N;
  VME_DS_n_i(0)              <= VME64xBus_out.Vme64xDs0N;
  VME_LWORD_n_b              <= VME64xBus_out.Vme64xLWORDN when VME_ADDR_DIR_o = '0' else 'Z';
  VME64xBus_in.Vme64xLWORDN  <= VME_LWORD_n_b;
  VME_ADDR_b                 <= VME64xBus_out.Vme64xADDR   when VME_ADDR_DIR_o = '0' else (others => 'Z');
  VME64xBus_in.Vme64xADDR    <= VME_ADDR_b;
  VME_DATA_b                 <= VME64xBus_out.Vme64xDATA   when VME_DATA_DIR_o = '0' else (others => 'Z');
  VME64xBus_in.Vme64xDATA    <= VME_DATA_b;
  VME64xBus_in.Vme64xDtackN  <= VME_DTACK_n_o;
  VME64xBus_in.Vme64xBerrN   <= VME_BERR_o;
  VME64xBus_in.Vme64xRetryN  <= VME_RETRY_n_o;
  VME64xBus_in.Vme64xIRQ     <= VME_IRQ_n_o;
  VME64xBus_in.Vme64xIACKOUT <= VME_IACKOUT_n_o;

  -- Clock process definitions
  p_clk : process
  begin
    clk_i <= '0';
    wait for clk_i_period/2;
    clk_i <= '1';
    wait for clk_i_period/2;
  end process p_clk;


  -- Actual test process
  p_vme64x_ddr : process
  begin

    wait for 8800 ns;                   -- wait until the initialization finish (wait more than 8705 ns)
    -- Write in CSR:
    VME64xBus_Out.Vme64xIACK   <= '1';
    VME64xBus_Out.Vme64xIACKIN <= '1';

    ------------------------------------------------------------------------------
    -- Configure CSR space
    ------------------------------------------------------------------------------
    report "START WRITE CSR";

    s_dataTransferType <= D08Byte3;
    s_AddressingType <= CR_CSR;

    s_dataToSend <= x"00000000";        -- Put the data to send in the 8 lsb.
    WriteCSR(c_address        => c_BIT_CLR_REG , s_dataToSend => s_dataToSend, s_dataTransferType => s_dataTransferType,
             s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_in,
             VME64xBus_Out    => VME64xBus_Out);
    report "END WRITE CSR";
    wait for 10 ns;


    report "START READ CSR";
    s_dataTransferType <= D08Byte3;
    s_AddressingType   <= CR_CSR;

    -- Put the data to receive in the 8 lsb also if you are using D08Byte1 or D08Byte2 ecc..
    s_dataToReceive <= x"00000000";
    ReadCR_CSR(c_address        => c_USR_BIT_SET_REG, s_dataToReceive => s_dataToReceive, s_dataTransferType => s_dataTransferType,
               s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_in,
               VME64xBus_Out    => VME64xBus_Out);


    report "END READ CSR";
    wait for 10 ns;
    s_dataToReceive <= (others => '0');
    wait for 10 ns;



    ------------------------------------------------------------------------------
    -- Configure window to access WB bus (ADER)
    ------------------------------------------------------------------------------

    wait for 50 ns;
    report "START WRITE ADER";
    -- Before the Master has to write the ADERs.


    -- start write ADER0
    s_dataTransferType <= D08Byte3;
    s_AddressingType <= CR_CSR;

    s_dataToSend <= x"000000" & ADER0_A32(31 downto 24);
    WriteCSR(c_address        => c_FUNC0_ADER_3 , s_dataToSend => s_dataToSend, s_dataTransferType => s_dataTransferType,
             s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_in,
             VME64xBus_Out    => VME64xBus_Out);

    wait for 20 ns;

    s_dataTransferType <= D08Byte3;
    s_AddressingType <= CR_CSR;

    s_dataToSend <= x"000000" & ADER0_A32(23 downto 16);
    WriteCSR(c_address        => c_FUNC0_ADER_2 , s_dataToSend => s_dataToSend, s_dataTransferType => s_dataTransferType,
             s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_in,
             VME64xBus_Out    => VME64xBus_Out);

    wait for 20 ns;

    s_dataTransferType <= D08Byte3;
    s_AddressingType   <= CR_CSR;

    s_dataToSend <= x"000000" & ADER0_A32(15 downto 8);
    WriteCSR(c_address        => c_FUNC0_ADER_1 , s_dataToSend => s_dataToSend, s_dataTransferType => s_dataTransferType,
             s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_in,
             VME64xBus_Out    => VME64xBus_Out);

    wait for 20 ns;

    s_dataTransferType <= D08Byte3;
    s_AddressingType <= CR_CSR;

    s_dataToSend <= x"000000" & ADER0_A32(7 downto 0);
    WriteCSR(c_address        => c_FUNC0_ADER_0 , s_dataToSend => s_dataToSend, s_dataTransferType => s_dataTransferType,
             s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_in,
             VME64xBus_Out    => VME64xBus_Out);

    wait for 20 ns;
    report "THE MASTER HAS WRITTEN CORRECTLY ALL THE ADERs";
    wait for 20 ns;


    ------------------------------------------------------------------------------
    -- Enables the VME64x core
    ------------------------------------------------------------------------------
    -- Module Enabled:

    s_dataTransferType <= D08Byte3;
    s_AddressingType <= CR_CSR;

    s_dataToSend <= x"00000010";
    WriteCSR(c_address        => c_BIT_SET_REG , s_dataToSend => s_dataToSend, s_dataTransferType => s_dataTransferType,
             s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_in,
             VME64xBus_Out    => VME64xBus_Out);

    wait for 20 ns;


    ------------------------------------------------------------------------------
    -- Access to WB registers and memories
    ------------------------------------------------------------------------------
    report "START WRITE AND READ WB REG/MEMORY";

    -- Write RAM address 0x0
    s_dataTransferType <= D32;
    s_AddressingType <= A32;
    s_dataToSend <= x"AAAA1234";
    s_address    <= x"0000000000002000";
    S_Write(v_address        => s_address , s_dataToSend => s_dataToSend, s_dataTransferType => s_dataTransferType,
            s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_In,
            VME64xBus_Out    => VME64xBus_Out);
    wait for 100 ns;

    -- Write DDR bank5 address 0x0
    s_dataTransferType <= D32;
    s_AddressingType <= A32;
    s_dataToSend <= x"55559876";
    s_address    <= x"0000000000003000";
    S_Write(v_address        => s_address , s_dataToSend => s_dataToSend, s_dataTransferType => s_dataTransferType,
            s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_In,
            VME64xBus_Out    => VME64xBus_Out);
    wait for 100 ns;

    -- Read RAM address 0x0
    s_dataTransferType <= D32;
    s_AddressingType   <= A32;
    s_address          <= x"0000000000002000";
    s_dataToReceive    <= x"AAAA1234";
    S_Read(v_address        => s_address, s_dataToReceive => s_dataToReceive, s_dataTransferType => s_dataTransferType,
           s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_In,
           VME64xBus_Out    => VME64xBus_Out);
    wait for 100 ns;

    -- Read DDR bank5 address 0x0
    s_dataTransferType <= D32;
    s_AddressingType   <= A32;
    s_address          <= x"0000000000003000";
    s_dataToReceive    <= x"55559876";
    S_Read(v_address        => s_address, s_dataToReceive => s_dataToReceive, s_dataTransferType => s_dataTransferType,
           s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_In,
           VME64xBus_Out    => VME64xBus_Out);
    wait for 100 ns;

    -- Read DDR bank5 address 0x0
    s_dataTransferType <= D32;
    s_AddressingType   <= A32;
    s_address          <= x"0000000000003000";
    s_dataToReceive    <= x"55559876";
    S_Read(v_address        => s_address, s_dataToReceive => s_dataToReceive, s_dataTransferType => s_dataTransferType,
           s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_In,
           VME64xBus_Out    => VME64xBus_Out);
    wait for 100 ns;

    -- Read DDR bank5 address 0x0
    s_dataTransferType <= D32;
    s_AddressingType   <= A32;
    s_address          <= x"0000000000003000";
    s_dataToReceive    <= x"55559876";
    S_Read(v_address        => s_address, s_dataToReceive => s_dataToReceive, s_dataTransferType => s_dataTransferType,
           s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_In,
           VME64xBus_Out    => VME64xBus_Out);
    wait for 100 ns;
    assert false report "Got here!" severity failure;

    wait;
  end process p_vme64x_ddr;



  -- Stimulus process------------RESET, BBSY, IACKIN, VME_GA
  p_rst : process
  begin
    -- hold reset state for 100 ns.
    VME_RST_n_i <= '0';
    VME_GA_i    <= VME_GA;

    wait for 200 ns;
    VME_RST_n_i <= '1';

    wait;
  end process p_rst;

end;
