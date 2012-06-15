--------------------------------------------------------------------------------
-- CERN (BE-CO-HT)
-- Top level entity for Simple VME FMC Carrier (SVEC) System FPGA
-- http://www.ohwr.org/projects/svec
--------------------------------------------------------------------------------
--
-- unit name: svec_v0_sfpga_top
--
-- author: Matthieu Cattin (matthieu.cattin@cern.ch)
--
-- date: 14-06-2012
--
-- version: 1.0
--
-- description: Generic top level entity for the system FPGA of the
--              Simple VME FMC Carrier (SVEC)
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


entity svec_v0_sfpga_top is
  generic(
    g_GENERIC : string := "FALSE");
  port
    (

      ----------------------------------------
      -- VME interface
      ----------------------------------------
      vme_write_n_i    : in    std_logic;
      vme_trst_i       : in    std_logic;
      vme_tms_i        : in    std_logic;
      vme_tdo_oe_o     : out   std_logic;
      vme_tdo_o        : out   std_logic;
      vme_tdi_i        : in    std_logic;
      vme_tck_i        : in    std_logic;
      vme_sysreset_n_i : in    std_logic;
      vme_sysclk_i     : in    std_logic;
      vme_retry_oe_o   : out   std_logic;
      vme_retry_n_o    : out   std_logic;
      vme_lword_n_b    : inout std_logic;
      vme_iackout_n_o  : out   std_logic;
      vme_iackin_n_i   : in    std_logic;
      vme_iack_n_o     : out   std_logic;
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

      ----------------------------------------
      -- Application FPGA boot control
      ----------------------------------------
      boot_clk_o    : out std_logic;
      boot_config_o : out std_logic;
      boot_done_i   : in  std_logic;
      boot_dout_o   : out std_logic;
      boot_status_i : in  std_logic;

      ----------------------------------------
      -- Clock and reset inputs
      ----------------------------------------
      rst_n_i        : in  std_logic;
      lclk_n_i       : in  std_logic;
      pll_2sfpga_n_i : in  std_logic;
      pll_2sfpga_p_i : in  std_logic;
      pll_ce_o       : out std_logic;

      ----------------------------------------
      -- Switches and button
      ----------------------------------------
      pushbutton_i : in std_logic;
      noga_i       : in std_logic_vector(4 downto 0);
      switch_i     : in std_logic_vector(1 downto 0);
      usega_i      : in std_logic;

      ----------------------------------------
      -- Inter-FPGA lines
      ----------------------------------------
      rsvd_b : inout std_logic_vector(7 downto 0);

      ----------------------------------------
      -- LEDs
      ----------------------------------------
      debugled_o : out std_logic_vector(2 downto 1);

      ----------------------------------------
      -- Boot interface
      ----------------------------------------
      sfpga_cclk_o  : out std_logic;
      sfpga_cso_b_o : out std_logic;
      sfpga_miso_i  : in  std_logic;
      sfpga_mosi_o  : out std_logic
      );
end svec_v0_sfpga_top;


architecture rtl of svec_v0_sfpga_top is

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
