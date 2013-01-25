-------------------------------------------------------------------------------
-- Title      : Minimalistic VME64x Core
-- Project    : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File       : mini_vme.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2012-01-20
-- Last update: 2013-01-25
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: A stripped-down version of VME64x core. Supports only CR/CSR/D32
-- accesses to a range of addresses specified in g_user_csr_start/end. Matching
-- transactions are executed through a Wishbone master.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2012 - 2013 CERN / BE-CO-HT
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


library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.NUMERIC_STD.all;

use work.gencores_pkg.all;
use work.wishbone_pkg.all;

entity xmini_vme is
  generic (
    -- Start/end of our CSR space
    g_user_csr_start : unsigned(20 downto 0);
    g_user_csr_end   : unsigned(20 downto 0));
  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    -- Stripped-down VME bus. 
    VME_RST_n_i    : in  std_logic;
    VME_AS_n_i     : in  std_logic;
    VME_LWORD_n_i  : in  std_logic;
    VME_WRITE_n_i  : in  std_logic;
    VME_DS_n_i     : in  std_logic_vector(1 downto 0);

    -- Geographical Address. Bit 5 is GA parity.
    VME_GA_i       : in  std_logic_vector(5 downto 0);  
    VME_AM_i   : in std_logic_vector(5 downto 0);
    VME_ADDR_i : in std_logic_vector(31 downto 1);

    -- Bidirectional/tristate driver signals: please put the tristates in the
    -- top level entity of your design.
    VME_DTACK_n_o  : out std_logic;
    VME_DTACK_OE_o : out std_logic;
    VME_DATA_b_i    : in  std_logic_vector(31 downto 0);
    VME_DATA_b_o    : out std_logic_vector(31 downto 0);
    VME_DATA_DIR_o  : out std_logic;
    VME_DATA_OE_N_o : out std_logic;

    -- Wishbone master
    master_o : out t_wishbone_master_out;
    master_i : in  t_wishbone_master_in
    );

end xmini_vme;

architecture rtl of xmini_vme is

  -- We are only interested in CR/CSR transfers (AM = 0x2f)
  constant c_AM_CS_CSR    : std_logic_vector(5 downto 0) := "101111";

  -- How long (in clock cycles) is our DTACK. Useful for slower VME controllers.
  constant c_DTACK_LENGTH : integer                      := 20;

  signal as_synced, ds_synced                 : std_logic;
  signal ds_a, as_p1, ds_p1, write_n          : std_logic;
  signal lword_latched                        : std_logic;
  signal addr_latched                         : std_logic_vector(31 downto 1);
  signal readback_data, data_latched          : std_logic_vector(31 downto 0);
  signal am_latched                           : std_logic_vector(5 downto 0);
  signal ds_latched                           : std_logic_vector(1 downto 0);
  signal ga_latched                           : std_logic_vector(5 downto 0);
  signal addr_valid, data_valid, ga_parity_ok : std_logic;

  type t_fsm_state is (IDLE, DECODE_ADDR, EXEC_CYCLE, WAIT_ACK, DTACK);

  signal state : t_fsm_state;

  signal am_match, addr_match, dtype_match : std_logic;
  signal is_write                          : std_logic;

  signal dtack_counter : unsigned(7 downto 0);
  
begin  -- rtl

  U_Sync_AS : gc_sync_ffs
    port map (
      clk_i    => clk_sys_i,
      rst_n_i  => rst_n_i,
      data_i   => VME_AS_n_i,
      npulse_o => as_p1,
      synced_o => as_synced);

  ds_a <= VME_DS_n_i(0) and VME_DS_n_i(1);

  U_Sync_DS : gc_sync_ffs
    port map (
      clk_i    => clk_sys_i,
      rst_n_i  => rst_n_i,
      data_i   => ds_a,
      npulse_o => ds_p1,
      synced_o => ds_synced);

  U_Sync_Write : gc_sync_ffs
    port map (
      clk_i    => clk_sys_i,
      rst_n_i  => rst_n_i,
      data_i   => VME_WRITE_n_i,
      synced_o => write_n);


  ga_parity_ok <= ga_latched(5) xor ga_latched(4) xor ga_latched(3) xor ga_latched(2) xor ga_latched(1) xor ga_latched(0);

  p_latch_addr : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if(rst_n_i = '0') then
        addr_valid <= '0';
      elsif(as_p1 = '1') then
        addr_latched  <= VME_ADDR_i;
        addr_valid    <= '1';
        am_latched    <= VME_AM_i;
        ga_latched    <= VME_GA_i;
        lword_latched <= VME_LWORD_n_i;
      elsif(as_synced = '1') then
        addr_valid <= '0';
      end if;
    end if;
  end process;

  p_latch_data : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        data_valid <= '0';
      elsif(ds_p1 = '1') then
        data_latched <= VME_DATA_b_i;
        ds_latched   <= VME_DS_n_i;
        data_valid   <= '1';
      elsif(ds_synced = '1') then
        data_valid <= '0';
      end if;
    end if;
  end process;

  p_decode : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        am_match    <= '0';
        addr_match  <= '0';
        dtype_match <= '0';
      else
        -- we accept only CS/CSR accesses
        if(am_latched = c_AM_CS_CSR) then
          am_match <= '1';
        else
          am_match <= '0';
        end if;

        -- ... D32 data type
        if(ds_latched = "00" and lword_latched = '0' and addr_latched(1) = '0') then
          dtype_match <= '1';
        else
          dtype_match <= '0';
        end if;

        -- ... and address matches our supported range
        if(ga_parity_ok = '1' and addr_latched(23 downto 19) = not ga_latched(4 downto 0) and addr_latched(31 downto 24) = x"00") then
          addr_match <= '1';
        else
          addr_match <= '0';
        end if;
        
      end if;
    end if;
  end process;

  p_fsm : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        state <= IDLE;

        VME_DATA_DIR_o  <= '0';
        VME_DATA_OE_N_o <= '0';
        VME_DTACK_n_o   <= '0';
        VME_DTACK_OE_o  <= '0';
      else
        case state is
          when IDLE =>
            VME_DATA_DIR_o  <= '0';
            VME_DTACK_n_o  <= '1';
            VME_DTACK_OE_o <= '0';
            dtack_counter  <= (others => '0');

            if(addr_valid = '1' and data_valid = '1') then
              state <= DECODE_ADDR;
            end if;
            
          when DECODE_ADDR =>
            if(addr_valid = '1') then
              if(addr_match = '1' and am_match = '1' and dtype_match = '1') then
                if((unsigned(addr_latched(18 downto 2)) & "00") >= g_user_csr_start
                   and (unsigned(addr_latched(18 downto 2)) & "00") <= g_user_csr_end) then
                  state    <= EXEC_CYCLE;
                  is_write <= not write_n;
                end if;
              else
                state <= IDLE;
              end if;
            end if;

          when EXEC_CYCLE =>
            master_o.adr <= std_logic_vector(resize(((unsigned(addr_latched(18 downto 2)) & "00") - g_user_csr_start), c_wishbone_address_width));
            master_o.dat <= data_latched;
            master_o.cyc <= '1';
            master_o.sel <= "1111";
            master_o.stb <= '1';
            master_o.we  <= is_write;

            state <= WAIT_ACK;

          when WAIT_ACK =>
            if(master_i.stall = '0') then
              master_o.stb <= '0';
            end if;

            if(master_i.ack = '1') then
              state         <= DTACK;
              readback_data <= master_i.dat;
            elsif(ds_synced = '1') then
              state <= IDLE;
            end if;
            
          when DTACK =>
            VME_DATA_b_o <= readback_data;

            VME_DTACK_n_o  <= '0';
            VME_DTACK_OE_o <= '1';
            VME_DATA_DIR_o <= not is_write;

            dtack_counter <= dtack_counter + 1;

            if(ds_synced = '1') then
              state <= IDLE;
            end if;
            
        end case;
      end if;
    end if;
  end process;

end rtl;
