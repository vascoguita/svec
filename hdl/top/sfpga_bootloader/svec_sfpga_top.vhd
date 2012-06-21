
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.gencores_pkg.all;
use work.wishbone_pkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity svec_sfpga_top is
  port
    (

      -------------------------------------------------------------------------
      -- Standard SVEC ports (Gennum bridge, LEDS, Etc. Do not modify
      -------------------------------------------------------------------------

      lclk_n_i : in std_logic;          -- 20MHz VCXO clock
      rst_n_i  : in std_logic;

      -------------------------------------------------------------------------
      -- VME Interface pins
      -------------------------------------------------------------------------

      VME_AS_n_i    : in    std_logic;
      VME_RST_n_i   : in    std_logic;
      VME_WRITE_n_i : in    std_logic;
      VME_AM_i      : in    std_logic_vector(5 downto 0);
      VME_DS_n_i    : in    std_logic_vector(1 downto 0);
      VME_GA_i      : in    std_logic_vector(5 downto 0);
      VME_BERR_o    : inout std_logic := 'Z';
      VME_DTACK_n_o : inout std_logic;
      VME_LWORD_n_b : inout std_logic;
      VME_ADDR_b    : inout std_logic_vector(31 downto 1);

      VME_DATA_b      : inout std_logic_vector(31 downto 0);
      VME_DTACK_OE_o  : inout std_logic;
      VME_DATA_DIR_o  : inout std_logic;
      VME_DATA_OE_N_o : inout std_logic;

      -- unused pins, tied hi-impedance

      VME_ADDR_DIR_o  : inout std_logic                    := 'Z';
      VME_ADDR_OE_N_o : inout std_logic                    := 'Z';
      VME_RETRY_n_o   : out   std_logic                    := 'Z';
      VME_RETRY_OE_o  : out   std_logic                    := 'Z';
      VME_BBSY_n_i    : in    std_logic;
      VME_IRQ_n_o     : out   std_logic_vector(6 downto 0) := "ZZZZZZZ";
      VME_IACK_n_i    : in    std_logic;
      VME_IACKIN_n_i  : in    std_logic;
      VME_IACKOUT_n_o : out   std_logic                    := 'Z';

      -------------------------------------------------------------------------
      -- AFPGA boot signals
      -------------------------------------------------------------------------

      boot_clk_o    : out std_logic;
      boot_config_o : out std_logic;
      boot_done_i   : in  std_logic;
      boot_dout_o   : out std_logic;
      boot_status_i : in  std_logic;

      debugled_o : out std_logic_vector(2 downto 1)
      );
end svec_sfpga_top;

architecture rtl of svec_sfpga_top is

  component xmini_vme
    generic (
      g_user_csr_start : unsigned(20 downto 0);
      g_user_csr_end   : unsigned(20 downto 0));
    port (
      clk_sys_i       : in  std_logic;
      rst_n_i         : in  std_logic;
      passive_i       : in  std_logic;
      VME_RST_n_i     : in  std_logic;
      VME_AS_n_i      : in  std_logic;
      VME_LWORD_n_i   : in  std_logic;
      VME_WRITE_n_i   : in  std_logic;
      VME_DS_n_i      : in  std_logic_vector(1 downto 0);
      VME_GA_i        : in  std_logic_vector(5 downto 0);
      VME_DTACK_n_o   : out std_logic;
      VME_DTACK_OE_o  : out std_logic;
      VME_AM_i        : in  std_logic_vector(5 downto 0);
      VME_ADDR_i      : in  std_logic_vector(31 downto 1);
      VME_DATA_b_i    : in  std_logic_vector(31 downto 0);
      VME_DATA_b_o    : out std_logic_vector(31 downto 0);
      VME_DATA_DIR_o  : out std_logic;
      VME_DATA_OE_N_o : out std_logic;
      master_o        : out t_wishbone_master_out;
      master_i        : in  t_wishbone_master_in);
  end component;

  component xwb_xilinx_fpga_loader
    generic (
      g_interface_mode      : t_wishbone_interface_mode;
      g_address_granularity : t_wishbone_address_granularity;
      g_idr_value           : std_logic_vector(31 downto 0));
    port (
      clk_sys_i       : in  std_logic;
      rst_n_i         : in  std_logic;
      slave_i         : in  t_wishbone_slave_in;
      slave_o         : out t_wishbone_slave_out;
      desc_o          : out t_wishbone_device_descriptor;
      xlx_cclk_o      : out std_logic := '0';
      xlx_din_o       : out std_logic;
      xlx_program_b_o : out std_logic := '1';
      xlx_init_b_i    : in  std_logic;
      xlx_done_i      : in  std_logic;
      xlx_suspend_o   : out std_logic;
      xlx_m_o         : out std_logic_vector(1 downto 0);
      boot_trig_p1_o  : out std_logic;
      boot_exit_p1_o  : out std_logic;
      boot_en_i       : in  std_logic;
      gpio_o          : out std_logic_vector(7 downto 0));
  end component;

  signal VME_DATA_o_int                    : std_logic_vector(31 downto 0);
  signal vme_dtack_oe_int, VME_DTACK_n_int : std_logic;
  signal vme_data_dir_int                  : std_logic;
  signal VME_DATA_OE_N_int                 : std_logic;

  signal wb_vme_in  : t_wishbone_master_out;
  signal wb_vme_out : t_wishbone_master_in;

  signal passive : std_logic := '1';
  signal gpio    : std_logic_vector(7 downto 0);


-- bootloader is active right after bootup
  signal boot_en                    : std_logic := '1';
  signal boot_trig_p1, boot_exit_p1 : std_logic;

  component chipscope_ila
    port (
      CONTROL : inout std_logic_vector(35 downto 0);
      CLK     : in    std_logic;
      TRIG0   : in    std_logic_vector(31 downto 0);
      TRIG1   : in    std_logic_vector(31 downto 0);
      TRIG2   : in    std_logic_vector(31 downto 0);
      TRIG3   : in    std_logic_vector(31 downto 0));
  end component;

  component chipscope_icon
    port (
      CONTROL0 : inout std_logic_vector (35 downto 0));
  end component;


  signal CONTROL : std_logic_vector(35 downto 0);
  signal CLK     : std_logic;
  signal TRIG0   : std_logic_vector(31 downto 0);
  signal TRIG1   : std_logic_vector(31 downto 0);
  signal TRIG2   : std_logic_vector(31 downto 0);
  signal TRIG3   : std_logic_vector(31 downto 0);

  signal boot_config_int                 : std_logic;
  signal erase_afpga_n, erase_afpga_n_d0 : std_logic;

  signal pllout_clk_fb_sys, pllout_clk_sys, clk_sys : std_logic;
  
begin

  cmp_dmtd_clk_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 50,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 12,         -- 62.5 MHz
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 16,         -- 62.5 MHz
      CLKOUT1_PHASE      => 0.000,
      CLKOUT1_DUTY_CYCLE => 0.500,
      CLKOUT2_DIVIDE     => 8,
      CLKOUT2_PHASE      => 0.000,
      CLKOUT2_DUTY_CYCLE => 0.500,
      CLKIN_PERIOD       => 50.0,
      REF_JITTER         => 0.016)
    port map (
      CLKFBOUT => pllout_clk_fb_sys,
      CLKOUT0  => pllout_clk_sys,
      CLKOUT1  => open,                 --pllout_clk_sys,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => open,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb_sys,
      CLKIN    => lclk_n_i);

  cmp_clk_sys_buf : BUFG
    port map (
      O => clk_sys,
      I => pllout_clk_sys);

  
  chipscope_ila_1 : chipscope_ila
    port map (
      CONTROL => CONTROL,
      CLK     => clk_sys,
      TRIG0   => TRIG0,
      TRIG1   => TRIG1,
      TRIG2   => TRIG2,
      TRIG3   => TRIG3);

  chipscope_icon_1 : chipscope_icon
    port map (
      CONTROL0 => CONTROL);

  TRIG0(31 downto 1) <= VME_ADDR_b;
  TRIG1(31 downto 0) <= VME_DATA_b;
  TRIG2(5 downto 0)  <= VME_AM_i;
  trig2(7 downto 6)  <= VME_DS_n_i;
  trig2(13 downto 8) <= VME_GA_i;
  trig2(14)          <= VME_DTACK_n_o;
  trig2(15)          <= VME_DTACK_oe_o;
  trig2(16)          <= VME_LWORD_n_b;
  trig2(17)          <= VME_WRITE_n_i;
  trig2(18)          <= VME_AS_n_i;
  trig2(19)          <= VME_DATA_DIR_o;
  trig2(20)          <= VME_DATA_OE_N_o;
  trig2(21)          <= VME_addr_DIR_o;
  trig2(22)          <= VME_addr_OE_N_o;
  trig2(23)          <= rst_n_i;
  trig2(24)          <= '1';
  trig2(25)          <= VME_RST_n_i;
  trig2(26)          <= passive;


  U_MiniVME : xmini_vme
    generic map (
      g_user_csr_start => resize(x"70000", 21),
      g_user_csr_end   => resize(x"70020", 21))
    port map (
      clk_sys_i       => clk_sys,
      rst_n_i         => rst_n_i,
      passive_i       => '0',
      VME_RST_n_i     => VME_RST_n_i,
      VME_AS_n_i      => VME_AS_n_i,
      VME_LWORD_n_i   => VME_LWORD_n_b,
      VME_WRITE_n_i   => VME_WRITE_n_i,
      VME_DS_n_i      => VME_DS_n_i,
      VME_GA_i        => VME_GA_i,
      VME_DTACK_n_o   => VME_DTACK_n_int,
      VME_DTACK_OE_o  => vme_dtack_oe_int,
      VME_AM_i        => VME_AM_i,
      VME_ADDR_i      => VME_ADDR_b,
      VME_DATA_b_i    => VME_DATA_b,
      VME_DATA_b_o    => VME_DATA_o_int,
      VME_DATA_DIR_o  => vme_data_dir_int,
      VME_DATA_OE_N_o => VME_DATA_OE_N_int,
      master_o        => wb_vme_in,
      master_i        => wb_vme_out);

  U_Xilinx_Loader : xwb_xilinx_fpga_loader
    generic map (
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_idr_value           => x"53564543")
    port map (
      clk_sys_i       => clk_sys,
      rst_n_i         => rst_n_i,
      slave_i         => wb_vme_in,
      slave_o         => wb_vme_out,
      xlx_cclk_o      => boot_clk_o,
      xlx_din_o       => boot_dout_o,
      xlx_program_b_o => boot_config_int,
      xlx_init_b_i    => boot_status_i,
      xlx_done_i      => boot_done_i,
      xlx_suspend_o   => open,
      xlx_m_o         => open,
      boot_trig_p1_o  => boot_trig_p1,
      boot_exit_p1_o  => boot_exit_p1,
      boot_en_i       => boot_en,
      gpio_o          => gpio);

  U_Extend_Erase_Pulse : gc_extend_pulse
    generic map (
      g_width => 100)
    port map (
      clk_i      => clk_sys,
      rst_n_i    => rst_n_i,
      pulse_i    => boot_trig_p1,
      extended_o => erase_afpga_n);

  boot_config_o <= boot_config_int and (not erase_afpga_n);

  p_enable_disable_bootloader : process(clk_sys)
  begin
    if rising_edge(clk_sys) then

      erase_afpga_n_d0 <= erase_afpga_n;

      if(erase_afpga_n = '0' and erase_afpga_n_d0 = '1') then
        boot_en <= '1';
      elsif(boot_exit_p1 = '1') then
        boot_en <= '0';
      end if;
    end if;
  end process;

  passive <= not boot_en;


  VME_ADDR_b <= (others => 'Z');

  VME_DTACK_n_o   <= VME_DTACK_n_int   when passive = '0'                                                          else 'Z';
  vme_dtack_oe_o  <= vme_dtack_oe_int  when passive = '0'                                                          else 'Z';
  VME_DATA_DIR_o  <= vme_data_dir_int  when passive = '0'                                                          else 'Z';
  VME_DATA_OE_N_o <= VME_DATA_OE_N_int when passive = '0'                                                          else 'Z';
  VME_DATA_b      <= VME_DATA_o_int    when (passive = '0' and VME_DATA_OE_N_int = '0' and vme_data_dir_int = '1') else (others => 'Z');
  VME_ADDR_OE_N_o <= '0'               when passive = '0'                                                          else 'Z';
  VME_ADDR_DIR_o  <= '0'               when passive = '0'                                                          else 'Z';
  VME_BERR_o      <= 'Z';
  VME_LWORD_n_b   <= 'Z';

  debugled_o(1) <= gpio(0);
  debugled_o(2) <= boot_en;

  
end rtl;


