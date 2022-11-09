-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

--------------------------------------------------------------------------------
-- CERN (BE-CO-HT)
-- Bi-color LED controller package
-- http://www.ohwr.org/projects/svec
--------------------------------------------------------------------------------
--
-- unit name: bicolor_led_ctrl_pkg
--
-- author: Matthieu Cattin (matthieu.cattin@cern.ch)
--
-- date: 11-07-2012
--
-- version: 1.0
--
-- description: Package for Bi-color LED controller.
--
-- dependencies:
--
--------------------------------------------------------------------------------
-- last changes: see log.
--------------------------------------------------------------------------------
-- TODO: - 
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


package bicolor_led_ctrl_pkg is

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  constant c_LED_RED       : std_logic_vector(1 downto 0) := "10";
  constant c_LED_GREEN     : std_logic_vector(1 downto 0) := "01";
  constant c_LED_RED_GREEN : std_logic_vector(1 downto 0) := "11";
  constant c_LED_OFF       : std_logic_vector(1 downto 0) := "00";

  ------------------------------------------------------------------------------
  -- Functions declaration
  ------------------------------------------------------------------------------
  function log2_ceil(N : natural) return positive;

  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------
  component bicolor_led_ctrl
    generic(
      g_NB_COLUMN    : natural := 4;
      g_NB_LINE      : natural := 2;
      g_CLK_FREQ     : natural := 125000000;  -- in Hz
      g_REFRESH_RATE : natural := 250         -- in Hz
      );
    port
      (
        rst_n_i         : in  std_logic;
        clk_i           : in  std_logic;
        led_intensity_i : in  std_logic_vector(6 downto 0);
        led_state_i     : in  std_logic_vector((g_NB_LINE * g_NB_COLUMN * 2) - 1 downto 0);
        column_o        : out std_logic_vector(g_NB_COLUMN - 1 downto 0);
        line_o          : out std_logic_vector(g_NB_LINE - 1 downto 0);
        line_oen_o      : out std_logic_vector(g_NB_LINE - 1 downto 0)
        );
  end component;

end bicolor_led_ctrl_pkg;


package body bicolor_led_ctrl_pkg is

  ------------------------------------------------------------------------------
  -- Function : Returns log of 2 of a natural number
  ------------------------------------------------------------------------------
  function log2_ceil(N : natural) return positive is
  begin
    if N <= 2 then
      return 1;
    elsif N mod 2 = 0 then
      return 1 + log2_ceil(N/2);
    else
      return 1 + log2_ceil((N+1)/2);
    end if;
  end;

end bicolor_led_ctrl_pkg;
