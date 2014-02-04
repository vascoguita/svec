-------------------------------------------------------------------------------
-- Title      : SVEC Golden Bistream
-- Project    : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File       : svec_top.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-08-24
-- Last update: 2014-02-03
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Golden bitstream for the SVEC.
-- Allows for:
-- - detecting types and presence of the FMCs (by checking present lines and
--   accessing serial EEPROMs)
-- - reading out the board's serial number from the 1-wire temperature sensor
-------------------------------------------------------------------------------
--
-- Copyright (c) 2012 CERN / BE-CO-HT
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
use work.golden_core_pkg.all;
use work.synthesis_descriptor.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity svec_top is
  port
    (

      -------------------------------------------------------------------------
      -- Standard SVEC ports (Gennum bridge, LEDS, Etc. Do not modify
      -------------------------------------------------------------------------

      clk_20m_vcxo_i : in std_logic;    -- 20MHz VCXO clock

      rst_n_i : in std_logic;

      -------------------------------------------------------------------------
      -- VME Interface pins
      -------------------------------------------------------------------------

      VME_AS_n_i     : in    std_logic;
      VME_RST_n_i    : in    std_logic;
      VME_WRITE_n_i  : in    std_logic;
      VME_AM_i       : in    std_logic_vector(5 downto 0);
      VME_DS_n_i     : in    std_logic_vector(1 downto 0);
      VME_GA_i       : in    std_logic_vector(5 downto 0);
      VME_BERR_o     : inout std_logic;
      VME_DTACK_n_o  : inout std_logic;
      VME_RETRY_n_o  : out   std_logic;
      VME_RETRY_OE_o : out   std_logic;

      VME_LWORD_n_b   : inout std_logic;
      VME_ADDR_b      : inout std_logic_vector(31 downto 1);
      VME_DATA_b      : inout std_logic_vector(31 downto 0);
      VME_BBSY_n_i    : in    std_logic;
      VME_IRQ_n_o     : inout std_logic_vector(6 downto 0);
      VME_IACK_n_i    : in    std_logic;
      VME_IACKIN_n_i  : in    std_logic;
      VME_IACKOUT_n_o : inout std_logic;
      VME_DTACK_OE_o  : inout std_logic;
      VME_DATA_DIR_o  : inout std_logic;
      VME_DATA_OE_N_o : inout std_logic;
      VME_ADDR_DIR_o  : inout std_logic;
      VME_ADDR_OE_N_o : inout std_logic;

      -------------------------------------------------------------------------
      -- FMC Present flags & I2C
      -------------------------------------------------------------------------

      fmc0_prsntm2c_n_i : in std_logic;
      fmc1_prsntm2c_n_i : in std_logic;

      fmc0_scl_b : inout std_logic;
      fmc0_sda_b : inout std_logic;

      fmc1_scl_b : inout std_logic;
      fmc1_sda_b : inout std_logic;

      tempid_dq_b : inout std_logic
      );

end svec_top;

architecture rtl of svec_top is

  component xvme64x_core
    port (
      clk_i           : in  std_logic;
      rst_n_i         : in  std_logic;
      VME_AS_n_i      : in  std_logic;
      VME_RST_n_i     : in  std_logic;
      VME_WRITE_n_i   : in  std_logic;
      VME_AM_i        : in  std_logic_vector(5 downto 0);
      VME_DS_n_i      : in  std_logic_vector(1 downto 0);
      VME_GA_i        : in  std_logic_vector(5 downto 0);
      VME_BERR_o      : out std_logic;
      VME_DTACK_n_o   : out std_logic;
      VME_RETRY_n_o   : out std_logic;
      VME_RETRY_OE_o  : out std_logic;
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
      master_o        : out t_wishbone_master_out;
      master_i        : in  t_wishbone_master_in;
      irq_i           : in  std_logic;
      irq_ack_o       : out std_logic);
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

  signal CONTROL : std_logic_vector(35 downto 0);
  signal CLK     : std_logic;
  signal TRIG0   : std_logic_vector(31 downto 0);
  signal TRIG1   : std_logic_vector(31 downto 0);
  signal TRIG2   : std_logic_vector(31 downto 0);
  signal TRIG3   : std_logic_vector(31 downto 0);


  signal VME_DATA_b_out                                        : std_logic_vector(31 downto 0);
  signal VME_ADDR_b_out                                        : std_logic_vector(31 downto 1);
  signal VME_LWORD_n_b_out, VME_DATA_DIR_int, VME_ADDR_DIR_int : std_logic;

  constant c_NUM_WB_MASTERS : integer := 2;
  constant c_NUM_WB_SLAVES  : integer := 1;

  constant c_MASTER_VME : integer := 0;

  constant c_SLAVE_GOLDEN   : integer := 0;
  constant c_SLAVE_ONEWIRE  : integer := 1;
  constant c_DESC_SYNTHESIS : integer := 2;
  constant c_DESC_REPO_URL  : integer := 3;

  constant c_INTERCONNECT_LAYOUT : t_sdb_record_array(c_NUM_WB_MASTERS + 1 downto 0) :=
    (c_SLAVE_GOLDEN   => f_sdb_embed_device(c_xwb_golden_sdb, x"00010000"),
     c_SLAVE_ONEWIRE  => f_sdb_embed_device(c_xwb_onewire_master_sdb, x"00012000"),
     c_DESC_SYNTHESIS => f_sdb_embed_synthesis(c_sdb_synthesis_info),
     c_DESC_REPO_URL  => f_sdb_embed_repo_url(c_sdb_repo_url)
     );

  constant c_SDB_ADDRESS : t_wishbone_address := x"00000000";

  signal cnx_master_out : t_wishbone_master_out_array(c_NUM_WB_MASTERS-1 downto 0);
  signal cnx_master_in  : t_wishbone_master_in_array(c_NUM_WB_MASTERS-1 downto 0);

  signal cnx_slave_out : t_wishbone_slave_out_array(c_NUM_WB_SLAVES-1 downto 0);
  signal cnx_slave_in  : t_wishbone_slave_in_array(c_NUM_WB_SLAVES-1 downto 0);

  signal fd0_scl_out, fd0_scl_in, fd0_sda_out, fd0_sda_in : std_logic;
  signal fd1_scl_out, fd1_scl_in, fd1_sda_out, fd1_sda_in : std_logic;
  signal wrc_owr_en, wrc_owr_in                           : std_logic_vector(1 downto 0);

  signal pllout_clk_fb_sys, pllout_clk_sys : std_logic;
  signal clk_20m_vcxo_buf                  : std_logic;
  signal clk_sys                           : std_logic;
  signal local_reset_n                     : std_logic;

  signal vme_master_out : t_wishbone_master_out;
  signal vme_master_in  : t_wishbone_master_in;


  signal powerup_reset_cnt : unsigned(7 downto 0) := "00000000";
  signal powerup_rst_n     : std_logic            := '0';
  signal sys_locked        : std_logic;
  
begin

  p_powerup_reset : process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      if(VME_RST_n_i = '0' or rst_n_i = '0') then
        powerup_rst_n <= '0';
      elsif sys_locked = '1' then
        if(powerup_reset_cnt = "11111111") then
          powerup_rst_n <= '1';
        else
          powerup_rst_n     <= '0';
          powerup_reset_cnt <= powerup_reset_cnt + 1;
        end if;
      else
        powerup_rst_n     <= '0';
        powerup_reset_cnt <= "00000000";
      end if;
    end if;
  end process;


-------------------------------------------------------------------------------
-- Clock distribution/PLL and reset 
-------------------------------------------------------------------------------

  U_cmp_sys_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 50,
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 16,         -- 62.5 MHz
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
      LOCKED   => sys_locked,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb_sys,
      CLKIN    => clk_20m_vcxo_buf);


  U_Sync_Reset : gc_sync_ffs
    port map (
      clk_i    => clk_sys,
      rst_n_i  => '1',
      data_i   => powerup_rst_n,
      synced_o => local_reset_n);

  U_cmp_clk_vcxo_buf : BUFG
    port map (
      O => clk_20m_vcxo_buf,
      I => clk_20m_vcxo_i);

  U_cmp_clk_sys_buf : BUFG
    port map (
      O => clk_sys,
      I => pllout_clk_sys);

-------------------------------------------------------------------------------
-- VME64x Core and buffers
-------------------------------------------------------------------------------
  
  U_VME_Core : xvme64x_core
    port map (
      clk_i           => clk_sys,
      rst_n_i         => local_reset_n,
      VME_AS_n_i      => VME_AS_n_i,
      VME_RST_n_i     => VME_RST_n_i,
      VME_WRITE_n_i   => VME_WRITE_n_i,
      VME_AM_i        => VME_AM_i,
      VME_DS_n_i      => VME_DS_n_i,
      VME_GA_i        => VME_GA_i,
      VME_BERR_o      => VME_BERR_o,
      VME_DTACK_n_o   => VME_DTACK_n_o,
      VME_RETRY_n_o   => VME_RETRY_n_o,
      VME_RETRY_OE_o  => VME_RETRY_OE_o,
      VME_LWORD_n_b_i => VME_LWORD_n_b,
      VME_LWORD_n_b_o => VME_LWORD_n_b_out,
      VME_ADDR_b_i    => VME_ADDR_b,
      VME_DATA_b_o    => VME_DATA_b_out,
      VME_ADDR_b_o    => VME_ADDR_b_out,
      VME_DATA_b_i    => VME_DATA_b,
      VME_IRQ_n_o     => VME_IRQ_n_o,
      VME_IACK_n_i    => VME_IACK_n_i,
      VME_IACKIN_n_i  => VME_IACKIN_n_i,
      VME_IACKOUT_n_o => VME_IACKOUT_n_o,
      VME_DTACK_OE_o  => VME_DTACK_OE_o,
      VME_DATA_DIR_o  => VME_DATA_DIR_int,
      VME_DATA_OE_N_o => VME_DATA_OE_N_o,
      VME_ADDR_DIR_o  => VME_ADDR_DIR_int,
      VME_ADDR_OE_N_o => VME_ADDR_OE_N_o,
      master_o        => vme_master_out,
      master_i        => vme_master_in,
      irq_i           => '0');

  TRIG0(0)            <= VME_AS_n_i;
  trig0(1)            <= VME_WRITE_n_i;
  trig0(3 downto 2)   <= VME_DS_n_i;
  trig0(9 downto 4)   <= VME_AM_i;
  trig0(10)           <= VME_DTACK_n_o;
  trig0(11)           <= VME_DTACK_OE_o;
  trig0(12)           <= VME_LWORD_n_b;
  trig0(19 downto 13) <= VME_IRQ_n_o;
  trig0(20)           <= VME_IACKIN_n_i;
  trig0(21)           <= VME_IACKOUT_n_o;
  trig0(22)           <= VME_IACK_n_i;
  trig0(23)           <= VME_BERR_o;
  trig0(24)           <= VME_DATA_DIR_int;
  trig0(25)           <= VME_addr_DIR_int;
  trig0(31 downto 26) <= VME_GA_i;

  trig1(30 downto 0) <= VME_ADDR_b;
  trig2(31 downto 0) <= VME_DATA_b;



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


  --VME_IRQ_n_o <= (others => 'Z');
  --VME_DTACK_OE_o <= '0';
  --VME_DATA_OE_N_o <= '1';
  --VME_ADDR_OE_N_o <= '1';
  --VME_RETRY_OE_o <= '0';
  --VME_RETRY_n_o <= '0';

  --VME_IACKOUT_n_o <= VME_IACKIN_n_i;

  VME_DATA_b    <= VME_DATA_b_out    when VME_DATA_DIR_int = '1' else (others => 'Z');
  VME_ADDR_b    <= VME_ADDR_b_out    when VME_ADDR_DIR_int = '1' else (others => 'Z');
  VME_LWORD_n_b <= VME_LWORD_n_b_out when VME_ADDR_DIR_int = '1' else 'Z';

  VME_ADDR_DIR_o <= VME_ADDR_DIR_int;
  VME_DATA_DIR_o <= VME_DATA_DIR_int;

-------------------------------------------------------------------------------
-- Wishbone interconnect
-------------------------------------------------------------------------------

  cnx_slave_in(c_MASTER_VME) <= vme_master_out;
  vme_master_in              <= cnx_slave_out(c_MASTER_VME);

  -- Tristates for FMC0 EEPROM: fixme: wire to WRCore
  fmc0_scl_b <= '0' when (fd0_scl_out = '0') else 'Z';
  fmc0_sda_b <= '0' when (fd0_sda_out = '0') else 'Z';
--  wrc_scl_in <= fmc_scl_b;
--  wrc_sda_in <= fmc_sda_b;
  fd0_scl_in <= fmc0_scl_b;
  fd0_sda_in <= fmc0_sda_b;

  -- Tristates for FMC0 EEPROM: fixme: wire to WRCore
  fmc1_scl_b <= '0' when (fd1_scl_out = '0') else 'Z';
  fmc1_sda_b <= '0' when (fd1_sda_out = '0') else 'Z';
--  wrc_scl_in <= fmc_scl_b;
--  wrc_sda_in <= fmc_sda_b;
  fd1_scl_in <= fmc1_scl_b;
  fd1_sda_in <= fmc1_sda_b;

  tempid_dq_b   <= '0' when wrc_owr_en(0) = '1' else 'Z';
  wrc_owr_in(0) <= tempid_dq_b;

  U_Intercon : xwb_sdb_crossbar
    generic map (
      g_num_masters => c_NUM_WB_SLAVES,
      g_num_slaves  => c_NUM_WB_MASTERS,
      g_registered  => true,
      g_wraparound  => true,
      g_layout      => c_INTERCONNECT_LAYOUT,
      g_sdb_addr    => c_SDB_ADDRESS)
    port map (
      clk_sys_i => clk_sys,
      rst_n_i   => local_reset_n,
      slave_i   => cnx_slave_in,
      slave_o   => cnx_slave_out,
      master_i  => cnx_master_in,
      master_o  => cnx_master_out);


  U_Onewire : xwb_onewire_master
    generic map (
      g_interface_mode      => PIPELINED,
      g_address_granularity => BYTE,
      g_num_ports           => 1)
    port map (
      clk_sys_i   => clk_sys,
      rst_n_i     => local_reset_n,
      slave_i     => cnx_master_out(c_SLAVE_ONEWIRE),
      slave_o     => cnx_master_in(c_SLAVE_ONEWIRE),
      owr_en_o(0) => wrc_owr_en(0),
      owr_i(0)    => wrc_owr_in(0));

  U_Golden_Core : golden_core
    generic map (
      g_slot_count => 2)
    port map (
      clk_sys_i    => clk_sys,
      rst_n_i      => local_reset_n,
      slave_i      => cnx_master_out(c_SLAVE_GOLDEN),
      slave_o      => cnx_master_in(c_SLAVE_GOLDEN),
      fmc_scl_o(0) => fd0_scl_out,
      fmc_scl_o(1) => fd1_scl_out,
      fmc_sda_o(0) => fd0_sda_out,
      fmc_sda_o(1) => fd1_sda_out,

      fmc_scl_i(0) => fd0_scl_in,
      fmc_scl_i(1) => fd1_scl_in,
      fmc_sda_i(0) => fd0_sda_in,
      fmc_sda_i(1) => fd1_sda_in,

      fmc_prsnt_n_i(0) => fmc0_prsntm2c_n_i,
      fmc_prsnt_n_i(1) => fmc1_prsntm2c_n_i
      );

end rtl;


