-------------------------------------------------------------------------------
-- Title        : Xilinx FPGA Loader
-- Project      : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File         : xilinx_loader.vhd
-- Author       : Tomasz Włostowski
-- Company      : CERN BE-CO-HT
-- Created      : 2012-01-30
-- Last update  : 2013-01-24
-- Platform     : FPGA-generic
-- Standard     : VHDL '93
-- Dependencies : none
-------------------------------------------------------------------------------
-- Description: A stripped-down version of the Wishbone Xilinx serial port
-- bitstream loader from general-cores library. Does not have Wishbone interface,
-- but it is driven direclty by the flash booting FSM.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2012 - 2013 CERN
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
use ieee.numeric_std.all;

use work.gencores_pkg.all;

entity xilinx_loader is
  port (
-- system clock
    clk_sys_i : in std_logic;
-- synchronous reset, active LOW
    rst_n_i   : in std_logic;

    csr_swrst_i   : in  std_logic;
    csr_start_i   : in  std_logic;
    csr_clk_div_i : in  std_logic_vector(6 downto 0);
    csr_data_i    : in  std_logic_vector(31 downto 0);
    csr_dsize_i   : in  std_logic_vector(1 downto 0);
    csr_msbf_i    : in  std_logic;
    csr_dlast_i   : in  std_logic;
    csr_error_o   : out std_logic;
    csr_done_o    : out std_logic;
    csr_rd_o      : out std_logic;
    csr_empty_i   : in  std_logic;
    csr_startup_i : in  std_logic;
    csr_busy_o    : out std_logic;

-- Configuration clock (to pin CCLK)
    xlx_cclk_o      : out std_logic := '0';
-- Data output (to pin D0/DIN)
    xlx_din_o       : out std_logic;
-- Program enable pin (active low, to pin PROG_B)
    xlx_program_b_o : out std_logic := '1';
-- Init ready pin (active low, to pin INIT_B)
    xlx_init_b_i    : in  std_logic;
-- Configuration done pin (to pin DONE)
    xlx_done_i      : in  std_logic

    );

end xilinx_loader;

architecture behavioral of xilinx_loader is

  type t_xloader_state is (IDLE, WAIT_INIT, WAIT_INIT2, READ_FIFO, READ_FIFO2, OUTPUT_BIT, CLOCK_EDGE, WAIT_DONE, EXTEND_PROG, STARTUP_CCLK0, STARTUP_CCLK1, GOT_DONE);

  signal state           : t_xloader_state;
  signal clk_div         : unsigned(6 downto 0);
  signal tick            : std_logic;
  signal init_b_synced   : std_logic;
  signal done_synced     : std_logic;
  signal timeout_counter : unsigned(20 downto 0);

  -- PROG_B assertion duration
  constant c_MIN_PROG_DELAY : unsigned(timeout_counter'left downto 0) := to_unsigned(1000, timeout_counter'length);

  -- PROG_B active to INIT_B active timeout
  constant c_INIT_TIMEOUT : unsigned(timeout_counter'left downto 0) := to_unsigned(200000, timeout_counter'length);

  -- Last word written to DONE active timeout
  constant c_DONE_TIMEOUT : unsigned(timeout_counter'left downto 0) := to_unsigned(200000, timeout_counter'length);

  -- Number of CCLK cycles after assertion of DONE required to start up the FPGA.
  constant c_STARTUP_CYCLES : integer := 1024;

  signal d_data : std_logic_vector(31 downto 0);
  signal d_size : std_logic_vector(1 downto 0);
  signal d_last : std_logic;

  signal bit_counter : unsigned(4 downto 0);

  signal startup_count : unsigned(20 downto 0);
  
begin  -- behavioral

-- Synchronization chains for async INIT_B and DONE inputs
  U_Sync_INIT : gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_sys_i,
      rst_n_i  => rst_n_i,
      data_i   => xlx_init_b_i,
      synced_o => init_b_synced);

  U_Sync_DONE : gc_sync_ffs
    generic map (
      g_sync_edge => "positive")
    port map (
      clk_i    => clk_sys_i,
      rst_n_i  => rst_n_i,
      data_i   => xlx_done_i,
      synced_o => done_synced);

  -- Clock divider. Genrates a single-cycle pulse on "tick" signal every
  -- CSR.CLKDIV system clock cycles.
  p_divide_clock : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        clk_div <= (others => '0');
        tick    <= '0';
      else
        if(clk_div = unsigned(csr_clk_div_i)) then
          tick    <= '1';
          clk_div <= (others => '0');
        else
          tick    <= '0';
          clk_div <= clk_div + 1;
        end if;
      end if;
    end if;
  end process;


  p_main_fsm : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' or csr_swrst_i = '1' then
        state           <= IDLE;
        xlx_program_b_o <= '1';
        xlx_cclk_o      <= '0';
        xlx_din_o       <= '0';
        timeout_counter <= (others => '0');

        csr_done_o  <= '0';
        csr_error_o <= '0';
      else
        case state is
          when IDLE =>
            
            timeout_counter <= c_INIT_TIMEOUT;
            if(csr_start_i = '1') then
              xlx_program_b_o <= '0';
              csr_done_o      <= '0';
              csr_error_o     <= '0';
              state           <= EXTEND_PROG;
              timeout_counter <= c_MIN_PROG_DELAY;
            else
              xlx_program_b_o <= '1';
              xlx_cclk_o      <= '0';
              xlx_din_o       <= '0';
            end if;

          when EXTEND_PROG =>
            timeout_counter <= timeout_counter-1;

            if(timeout_counter = 0) then
              timeout_counter <= c_INIT_TIMEOUT;
              state           <= WAIT_INIT;
            end if;
            
          when WAIT_INIT =>
            timeout_counter <= timeout_counter - 1;

            if(timeout_counter = 0) then
              csr_done_o  <= '1';
              csr_error_o <= '1';
              state       <= IDLE;
            end if;

            if (init_b_synced = '0') then
              state           <= WAIT_INIT2;
              xlx_program_b_o <= '1';
            end if;

          when WAIT_INIT2 =>
            if (init_b_synced /= '0') then
              state <= READ_FIFO;
            end if;

          when READ_FIFO =>
            xlx_cclk_o <= '0';

            if(csr_empty_i = '0') then
              state <= READ_FIFO2;
            end if;

          when READ_FIFO2 =>

            if(csr_msbf_i = '0') then
              d_data(31 downto 24) <= csr_data_i(7 downto 0);
              d_data(23 downto 16) <= csr_data_i(15 downto 8);
              d_data(15 downto 8)  <= csr_data_i(23 downto 16);
              d_data(7 downto 0)   <= csr_data_i(31 downto 24);  -- little-endian
            else
              d_data <= csr_data_i;
            end if;

            d_size <= csr_dsize_i;
            d_last <= csr_dlast_i;

            if(tick = '1') then
              state       <= OUTPUT_BIT;
              bit_counter <= unsigned(csr_dsize_i) & "111";
            end if;

          when OUTPUT_BIT =>
            if(tick = '1') then
              xlx_din_o                    <= d_data(31);
              xlx_cclk_o                   <= '0';
              d_data(d_data'left downto 1) <= d_data(d_data'left-1 downto 0);
              if(done_synced = '1') then
                state <= GOT_DONE;
              else
                state <= CLOCK_EDGE;
              end if;
              
            end if;
            
          when CLOCK_EDGE =>
            if(tick = '1') then
              xlx_cclk_o <= '1';

              bit_counter <= bit_counter - 1;

              if(bit_counter = 0) then
                if(d_last = '1') then
                  state           <= WAIT_DONE;
                  timeout_counter <= c_DONE_TIMEOUT;
                else
                  state <= READ_FIFO;
                end if;
              else
                state <= OUTPUT_BIT;
              end if;
            end if;

          when WAIT_DONE =>
            if(done_synced = '1') then
              state       <= IDLE;
              csr_done_o  <= '1';
              csr_error_o <= '0';
            end if;

            timeout_counter <= timeout_counter - 1;
            if(timeout_counter = 0) then
              state       <= IDLE;
              csr_done_o  <= '1';
              csr_error_o <= '1';
            end if;

-- DONE pin has just been asserted high. Stop loading the bitstream and wait
-- for EXIT command.
            
          when GOT_DONE =>
            csr_done_o  <= '1';
            csr_error_o <= '0';

            if(csr_startup_i = '1') then
              state         <= STARTUP_CCLK0;
              startup_count <= (others => '0');
            end if;

-- After receiving EXIT command, pulse CCLK for several cycles to initiate the
-- FPGA startup. This is to ensure the freshly configured FPGA keeps all its
-- pins in hi-z mode until the host bootloader is done (for example in VME
-- carriers, where a small FPGA, implementing the bootloader shares the VME bus
-- with the main FPGA.
          when STARTUP_CCLK0 =>
            xlx_din_o <= '0';
            if(tick = '1') then
              xlx_cclk_o <= '0';
              state      <= STARTUP_CCLK1;
            end if;

          when STARTUP_CCLK1 =>

            if(tick = '1') then
              xlx_cclk_o <= '1';
              if(startup_count = c_STARTUP_CYCLES) then
                state <= IDLE;
              else
                state <= STARTUP_CCLK0;
              end if;

              startup_count <= startup_count + 1;
            end if;
        end case;
      end if;
    end if;
  end process;

  csr_rd_o   <= '1' when ((csr_empty_i = '0') and (state = IDLE or state = READ_FIFO)) else '0';
  csr_busy_o <= '0' when (state = IDLE)                                                else '1';

end behavioral;
