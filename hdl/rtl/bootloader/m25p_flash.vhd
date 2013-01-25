-----------------------------------------------------------------------------
-- Title      : M25Pxxx Flash Controller
-- Project    : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File       : m25p_flash.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2013-01-24
-- Last update: 2013-01-25
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Simple controller for M25Pxxx series of SPI flash memories.
-- Provides two interfaces: host interface (accessible via FAR register), which
-- can execute any kind of operations, and a simple memory bus which can only read
-- blocks of bytes starting at a given address.
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sxldr_wbgen2_pkg.all;

entity m25p_flash is
  
  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    -- Wishbone registers (FAR register access)
    regs_i : in  t_sxldr_out_registers;
    regs_o : out t_sxldr_in_registers;

    -- Data readout interface. 

    -- 1: sets flash read address to addr_i
    set_addr_i : in std_logic;

    -- start address for read operations
    addr_i : in std_logic_vector(23 downto 0);

    -- data request: when 1, the controller reads subsequent bytes from
    -- the flash, starting from addr_i address.
    read_i : in std_logic;

    -- read data output
    data_o : out std_logic_vector(7 downto 0);

    -- when 1, data_o contains a valid byte and the controller is ready to accept
    -- another command
    ready_o : out std_logic;

    -- SPI bus, connect to the flash memory.
    spi_cs_n_o : out std_logic;
    spi_sclk_o : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic
    );

end m25p_flash;

architecture behavioral of m25p_flash is

  component spi_master
    generic (
      g_div_ratio_log2 : integer;
      g_num_data_bits  : integer);
    port (
      clk_sys_i  : in  std_logic;
      rst_n_i    : in  std_logic;
      cs_i       : in  std_logic;
      start_i    : in  std_logic;
      cpol_i     : in  std_logic;
      data_i     : in  std_logic_vector(g_num_data_bits - 1 downto 0);
      ready_o    : out std_logic;
      data_o     : out std_logic_vector(g_num_data_bits - 1 downto 0);
      spi_cs_n_o : out std_logic;
      spi_sclk_o : out std_logic;
      spi_mosi_o : out std_logic;
      spi_miso_i : in  std_logic);
  end component;

  signal spi_cs, spi_cs_muxed                       : std_logic;
  signal spi_start, spi_start_host, spi_start_muxed : std_logic;
  signal spi_wdata, spi_wdata_host, spi_wdata_muxed : std_logic_vector(7 downto 0);
  signal spi_rdata                                  : std_logic_vector(7 downto 0);
  signal spi_ready                                  : std_logic;

  type   t_read_state is (IDLE, CSEL, COMMAND, ADDR0, ADDR1, ADDR2, DUMMY_XFER, DATA);
  signal state     : t_read_state;
  signal ready_int : std_logic;
  
begin  -- rtl

  -- Host flash data register (bidirectional), updated by writing to FAR.DATA
  p_host_spi_registers : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        spi_start_host <= '0';
        spi_wdata_host <= (others => '0');
      elsif regs_i.far_data_load_o = '1' then
        spi_wdata_host <= regs_i.far_data_o;
        spi_start_host <= regs_i.far_xfer_o;
      else
        spi_start_host <= '0';
      end if;
    end if;
  end process;


  -- Multplexes the access between to the flash SPI controller between
  -- the bootloader host (through FAR register) and the flash readout
  -- FSM. 
  p_mux_spi_access : process(spi_cs, spi_start, spi_wdata, spi_start_host, spi_wdata, spi_ready, regs_i, state)
  begin
    spi_cs_muxed       <= regs_i.far_cs_o or spi_cs;
    spi_wdata_muxed    <= spi_wdata_host or spi_wdata;
    spi_start_muxed    <= spi_start_host or spi_start;
  end process;

  regs_o.far_ready_i <= spi_ready;
  regs_o.far_data_i <= spi_rdata;
  
  -- SPI Master: executes SPI read/write transactions.
  U_SPI_Master : spi_master
    generic map (
      g_div_ratio_log2 => 0,
      g_num_data_bits  => 8)
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_i,
      cs_i       => spi_cs_muxed,
      start_i    => spi_start_muxed,
      cpol_i     => '0',
      data_i     => spi_wdata_muxed,
      ready_o    => spi_ready,
      data_o     => spi_rdata,
      spi_cs_n_o => spi_cs_n_o,
      spi_sclk_o => spi_sclk_o,
      spi_mosi_o => spi_mosi_o,
      spi_miso_i => spi_miso_i);

  -- Main State machine
  p_main_fsm : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        state     <= IDLE;
        spi_start <= '0';
        spi_cs    <= '0';
        spi_wdata <= (others => '0');
        ready_int <= '1';
        -- any access to FAR register stops internal bus request
      elsif(regs_i.far_data_load_o = '1') then
        spi_start <= '0';
        spi_cs    <= '0';
        spi_wdata <= (others => '0');
        state <= IDLE;
      else
        case state is
          -- Idle: wait for "Set Address" or "Read" commands
          when IDLE =>
            if set_addr_i = '1' then
              spi_cs    <= '0';
              spi_start <= '1';
              ready_int <= '0';
              state     <= CSEL;
            elsif read_i = '1' then
              spi_start <= '1';
              ready_int <= '0';
              state     <= DATA;
            else
              spi_start <= '0';
              ready_int <= '1';
            end if;

            -- executes a dummy SPI cycle with the SPI chip disabled (CS = 0), to
            -- make sure it will correctly interpret the next transfer as a READ
            -- command
          when CSEL =>
            if(spi_ready = '1') then
              state     <= COMMAND;
              spi_wdata <= x"0b";
              spi_cs    <= '1';
              spi_start <= '1';
            else
              spi_start <= '0';
            end if;

            -- Send command 0x3 (FAST READ DATA)
          when COMMAND =>
            if(spi_ready = '1') then
              state     <= ADDR0;
              spi_wdata <= addr_i(23 downto 16);
              spi_start <= '1';
            else
              spi_start <= '0';
            end if;

            -- Send 1st byte of read address
          when ADDR0 =>
            if(spi_ready = '1') then
              state     <= ADDR1;
              spi_wdata <= addr_i(15 downto 8);
              spi_start <= '1';
            else
              spi_start <= '0';
            end if;

            -- Send 2nd byte of read address
          when ADDR1 =>
            if(spi_ready = '1') then
              state     <= ADDR2;
              spi_wdata <= addr_i(7 downto 0);
              spi_start <= '1';
            else
              spi_start <= '0';
            end if;

            -- Send 3nd byte of read address
          when ADDR2 =>
            if(spi_ready = '1') then
              state     <= DUMMY_XFER;
              spi_wdata <= "XXXXXXXX";
              spi_start <= '1';
            else
              spi_start <= '0';
            end if;

            -- dummy transfer (necessary for fast read mode)
          when DUMMY_XFER =>
            spi_start <= '0';
            if(spi_ready = '1') then
              state <= IDLE;
            end if;

            -- Data readout: waits for completion of read transaction initiated
            -- upon assertion of read_i and returns the byte read data_o.
          when DATA =>
            spi_start <= '0';
            if(spi_ready = '1')then
              data_o    <= spi_rdata;
              ready_int <= '1';
              state     <= IDLE;
            else
              ready_int <= '0';
            end if;
        end case;
      end if;
    end if;
  end process;

  -- De-assert ready flag early
  ready_o <= ready_int and not (set_addr_i or read_i);
  
end behavioral;

