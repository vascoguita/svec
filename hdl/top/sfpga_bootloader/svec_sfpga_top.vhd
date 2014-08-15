-------------------------------------------------------------------------------
-- Title        : SVEC System FPGA top level
-- Project      : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File         : svec_sfpga_top.vhd
-- Author       : Tomasz Włostowski
-- Company      : CERN BE-CO-HT
-- Created      : 2012-03-20
-- Last update  : 2013-01-25
-- Platform     : FPGA-generic
-- Standard     : VHDL '93
-------------------------------------------------------------------------------
-- Description: Top level of the System FPGA. Contains a stripped-down VME64x
-- core and the Appliaction FPGA bootloader core. Used solely for booting up
-- the AFPGA. Possible boot configurations are: HOST -> AFPGA, FLASH -> AFPGA
-- and HOST -> FLASH.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2013 CERN / BE-CO-HT
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.svec_bootloader_pkg.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity svec_sfpga_top is
  port
    (

      -------------------------------------------------------------------------
      -- Standard SVEC ports (Clocks & Reset)
      -------------------------------------------------------------------------

      lclk_n_i : in std_logic;          -- 20 MHz VCXO clock
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
      VME_DTACK_n_o : inout std_logic;
      VME_LWORD_n_b : inout std_logic;
      VME_ADDR_b    : inout std_logic_vector(31 downto 1);

      VME_DATA_b      : inout std_logic_vector(31 downto 0);
      VME_DTACK_OE_o  : inout std_logic;
      VME_DATA_DIR_o  : inout std_logic;
      VME_DATA_OE_N_o : inout std_logic;

      -- unused pins, tied hi-impedance

      VME_ADDR_DIR_o  : inout std_logic := 'Z';
      VME_ADDR_OE_N_o : inout std_logic := 'Z';
      VME_BBSY_n_i    : in    std_logic;

      -------------------------------------------------------------------------
      -- AFPGA boot signals
      -------------------------------------------------------------------------

      boot_clk_o    : out std_logic;
      boot_config_o : out std_logic;
      boot_done_i   : in  std_logic;
      boot_dout_o   : out std_logic;
      boot_status_i : in  std_logic;

      -------------------------------------------------------------------------
      -- SPI Flash Interface
      -------------------------------------------------------------------------

      spi_cs_n_o : out std_logic;
      spi_mosi_o : out std_logic;
      spi_miso_i : in  std_logic;
      spi_sclk_o : out std_logic;

      debugled_n_o : out std_logic_vector(2 downto 1);

      -------------------------------------------------------------------------
      -- Slave SPI interface allowing the Application FPGA to access the SPI flash
      -------------------------------------------------------------------------

      afpga_flash_sck_i  : in  std_logic;
      afpga_flash_mosi_i : in  std_logic;
      afpga_flash_cs_n_i : in  std_logic;
      afpga_flash_miso_o : out std_logic;

      -- Onboard PLL enable signal. Must be one for the clock system to work.
      pll_ce_o : out std_logic

      );
end svec_sfpga_top;

architecture rtl of svec_sfpga_top is

  constant c_PLL_RESET_DURATION : integer := 300;

  component reset_gen
    port (
      clk_sys_i       : in  std_logic;
      rst_vme_n_a_i   : in  std_logic;
      rst_local_n_a_i : in  std_logic;
      rst_n_o         : out std_logic);
  end component;

  component xmini_vme
    generic (
      g_user_csr_start : unsigned(20 downto 0);
      g_user_csr_end   : unsigned(20 downto 0));
    port (
      clk_sys_i       : in  std_logic;
      rst_n_i         : in  std_logic;
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
      master_i        : in  t_wishbone_master_in;
      idle_o          : out std_logic);
  end component;

  component sfpga_bootloader
    generic (
      g_interface_mode      : t_wishbone_interface_mode;
      g_address_granularity : t_wishbone_address_granularity;
      g_idr_value           : std_logic_vector(31 downto 0));
    port (
      clk_sys_i       : in  std_logic;
      rst_n_i         : in  std_logic;
      wb_cyc_i        : in  std_logic;
      wb_stb_i        : in  std_logic;
      wb_we_i         : in  std_logic;
      wb_adr_i        : in  std_logic_vector(c_wishbone_address_width - 1 downto 0);
      wb_sel_i        : in  std_logic_vector((c_wishbone_data_width + 7) / 8 - 1 downto 0);
      wb_dat_i        : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
      wb_dat_o        : out std_logic_vector(c_wishbone_data_width-1 downto 0);
      wb_ack_o        : out std_logic;
      wb_stall_o      : out std_logic;
      xlx_cclk_o      : out std_logic := '0';
      xlx_din_o       : out std_logic;
      xlx_program_b_o : out std_logic := '1';
      xlx_init_b_i    : in  std_logic;
      xlx_done_i      : in  std_logic;
      xlx_suspend_o   : out std_logic;
      xlx_m_o         : out std_logic_vector(1 downto 0);
      boot_trig_p1_o  : out std_logic := '0';
      boot_exit_p1_o  : out std_logic := '0';
      boot_en_i       : in  std_logic;
      spi_cs_n_o      : out std_logic;
      spi_sclk_o      : out std_logic;
      spi_mosi_o      : out std_logic;
      spi_miso_i      : in  std_logic);
  end component;

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

  signal VME_DATA_o_int                    : std_logic_vector(31 downto 0);
  signal vme_dtack_oe_int, VME_DTACK_n_int : std_logic;
  signal vme_data_dir_int                  : std_logic;
  signal VME_DATA_OE_N_int                 : std_logic;

  signal wb_vme_in  : t_wishbone_master_out;
  signal wb_vme_out : t_wishbone_master_in;

  signal passive : std_logic;

-- VME bootloader is inactive by default

  signal boot_en                    : std_logic := '1';
  signal boot_trig_p1, boot_exit_p1 : std_logic;
  signal CONTROL                    : std_logic_vector(35 downto 0);
  signal CLK                        : std_logic;
  signal TRIG0                      : std_logic_vector(31 downto 0);
  signal TRIG1                      : std_logic_vector(31 downto 0);
  signal TRIG2                      : std_logic_vector(31 downto 0);
  signal TRIG3                      : std_logic_vector(31 downto 0);

  signal boot_config_int                 : std_logic;
  signal erase_afpga_n, erase_afpga_n_d0 : std_logic;

  signal pllout_clk_fb_sys, pllout_clk_sys, clk_sys : std_logic;
  signal rst_n_sys                                  : std_logic;
  signal go_passive                                 : std_logic;
  signal vme_idle                                   : std_logic;

  signal pll_reset_count : unsigned(15 downto 0);

  signal spi_cs_n_int, spi_mosi_int, spi_sclk_int : std_logic;
  signal pass_flash: std_logic;
  
begin

-- PLL for producing 83.3 MHz system clock (clk_sys) from a 20 MHz reference.
  U_Sys_clk_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 50,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 12,         -- 83.3 MHz
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

  U_clk_sys_buf : BUFG
    port map (
      O => clk_sys,
      I => pllout_clk_sys);

  U_Powerup_Reset : reset_gen
    port map (
      clk_sys_i       => clk_sys,
      rst_vme_n_a_i   => VME_RST_n_i,
      rst_local_n_a_i => rst_n_i,
      rst_n_o         => rst_n_sys);

-------------------------------------------------------------------------------
-- Chipscope instantiation (for VME bus monitoring, I sincerely hate VMetro)
-------------------------------------------------------------------------------

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
  trig2(27)          <= vme_idle;
  trig2(28)          <= rst_n_sys;

  U_MiniVME : xmini_vme
    generic map (
      g_user_csr_start => resize(x"70000", 21),
      g_user_csr_end   => resize(x"70020", 21))
    port map (
      clk_sys_i       => clk_sys,
      rst_n_i         => rst_n_sys,
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
      master_i        => wb_vme_out,
      idle_o          => vme_idle);

  U_Bootloader_Core : sfpga_bootloader
    generic map (
      g_interface_mode      => CLASSIC,
      g_address_granularity => BYTE,
      g_idr_value           => c_CSR_SIGNATURE)
    port map (
      clk_sys_i       => clk_sys,
      rst_n_i         => rst_n_sys,
      wb_cyc_i        => wb_vme_in.cyc,
      wb_stb_i        => wb_vme_in.stb,
      wb_we_i         => wb_vme_in.we,
      wb_adr_i        => wb_vme_in.adr,
      wb_sel_i        => wb_vme_in.sel,
      wb_dat_i        => wb_vme_in.dat,
      wb_dat_o        => wb_vme_out.dat,
      wb_ack_o        => wb_vme_out.ack,
      wb_stall_o      => wb_vme_out.stall,
      xlx_cclk_o      => boot_clk_o,
      xlx_din_o       => boot_dout_o,
      xlx_program_b_o => boot_config_int,
      xlx_init_b_i    => boot_status_i,
      xlx_done_i      => boot_done_i,
      boot_trig_p1_o  => boot_trig_p1,
      boot_exit_p1_o  => boot_exit_p1,
      boot_en_i       => boot_en,
      spi_cs_n_o      => spi_cs_n_int,
      spi_sclk_o      => spi_sclk_int,
      spi_mosi_o      => spi_mosi_int,
      spi_miso_i      => spi_miso_i);

  -- produces a longer pulse on PROGRAM_B pin of the Application FPGA when
  -- the VME bootloader mode is activated
  U_Extend_Erase_Pulse : gc_extend_pulse
    generic map (
      g_width => 100)
    port map (
      clk_i      => clk_sys,
      rst_n_i    => rst_n_sys,
      pulse_i    => boot_trig_p1,
      extended_o => erase_afpga_n);

  -- Erase the application FPGA as soon as we have received a bootloader
  -- trigger command - this is to prevent two VME cores from working simultaneously
  -- on a single bus.
  boot_config_o <= boot_config_int and (not erase_afpga_n);

  p_enable_disable_bootloader : process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      if(rst_n_sys = '0') then
        boot_en    <= '0';  -- VME bootloader is inactive after reset
        go_passive <= '0';
      else

        erase_afpga_n_d0 <= erase_afpga_n;

        -- VME activation occurs after erasing the AFPGA
        if(erase_afpga_n = '0' and erase_afpga_n_d0 = '1') then
          boot_en    <= '1';
          go_passive <= '0';
        elsif(boot_exit_p1 = '1') then
          go_passive <= '1';
        elsif (go_passive = '1' and vme_idle = '1') then
          go_passive <= '0';
          boot_en    <= '0';
        end if;
      end if;
    end if;
  end process;

  -- drive the PLL CE (powerup reset)

  p_reset_cdcm61004_pll : process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      if rst_n_sys = '0' then
        pll_reset_count <= (others => '0');
        pll_ce_o        <= '0';
      else
        if(pll_reset_count = c_PLL_RESET_DURATION) then
          pll_ce_o <= '1';
        else
          pll_reset_count <= pll_reset_count + 1;
        end if;
      end if;
    end if;
  end process;

  -- multiplex flash access between the AFPGA and SFPGA bootloader (if the
  -- AFPGA is programmed, it's wired to the SPI flash).
  spi_cs_n_o <= spi_cs_n_int when boot_done_i = '0' else afpga_flash_cs_n_i;
  spi_sclk_o <= spi_sclk_int when boot_done_i = '0' else afpga_flash_sck_i;
  spi_mosi_o <= spi_mosi_int when boot_done_i = '0' else afpga_flash_mosi_i;
  afpga_flash_miso_o <= spi_miso_i;
  
  -- When the VME bootloader is not active, do NOT drive any outputs and sit quiet.
  passive <= not boot_en;

  VME_ADDR_b <= (others => 'Z');

  VME_DTACK_n_o   <= VME_DTACK_n_int   when passive = '0'                                                          else 'Z';
  vme_dtack_oe_o  <= vme_dtack_oe_int  when passive = '0'                                                          else 'Z';
  VME_DATA_DIR_o  <= vme_data_dir_int  when passive = '0'                                                          else 'Z';
  VME_DATA_OE_N_o <= VME_DATA_OE_N_int when passive = '0'                                                          else 'Z';
  VME_DATA_b      <= VME_DATA_o_int    when (passive = '0' and VME_DATA_OE_N_int = '0' and vme_data_dir_int = '1') else (others => 'Z');
  VME_ADDR_OE_N_o <= '0'               when passive = '0'                                                          else 'Z';
  VME_ADDR_DIR_o  <= '0'               when passive = '0'                                                          else 'Z';
  VME_LWORD_n_b   <= 'Z';

  debugled_n_o(1) <= '1';
  debugled_n_o(2) <= not boot_en;

  
end rtl;


