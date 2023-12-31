-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.NUMERIC_STD.all;

use work.gencores_pkg.all;

entity reset_gen is
  
  port (
    clk_sys_i : in std_logic;

    rst_vme_n_a_i   : in std_logic;
    rst_local_n_a_i : in std_logic;

    rst_n_o : out std_logic
    );

end reset_gen;

architecture behavioral of reset_gen is

  signal powerup_cnt     : unsigned(7 downto 0) := x"00";
  signal local_synced_n : std_logic;
  signal vme_synced_n   : std_logic;
  signal powerup_n       : std_logic            := '0';

begin  -- behavioral

  U_EdgeDet_PCIe : gc_sync_ffs port map (
    clk_i    => clk_sys_i,
    rst_n_i  => '1',
    data_i   => rst_vme_n_a_i,
    synced_o => vme_synced_n);

  U_Sync_Button : gc_sync_ffs port map (
    clk_i    => clk_sys_i,
    rst_n_i  => '1',
    data_i   => rst_local_n_a_i,
    synced_o => local_synced_n);

  p_powerup_reset : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if(powerup_cnt /= x"ff") then
        powerup_cnt <= powerup_cnt + 1;
        powerup_n   <= '0';
      else
        powerup_n <= '1';
      end if;
    end if;
  end process;

  rst_n_o <= powerup_n and local_synced_n and vme_synced_n;

end behavioral;
