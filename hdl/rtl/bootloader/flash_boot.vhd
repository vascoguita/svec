-----------------------------------------------------------------------------
-- Title      : Flash-to-Xilinx FPGA bitstream loader
-- Project    : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File       : flash_boot.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-01-24
-- Last update: 2014-01-15
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Searches for an Application FPGA bitstream in the flash memory
-- and uploads it to the FPGA through external xilinx_loader module. The bitstream
-- resides at a fixed location (defined in svec_bootloader_pkg) and the flash
-- is assumed to be formatted with SDB filesystem.
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
use work.svec_bootloader_pkg.all;

entity flash_boot is
  port (
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    -- Wbgen2 registers (for host access to the flash SPI controller via the
    -- FAR register)
    regs_i : in  t_sxldr_out_registers;
    regs_o : out t_sxldr_in_registers;

    -- 1: boot process is enabled (transition from 0 to 1 starts bootup sequence).
    -- It can be performed only once, re-booting AFPGA from the flash memory
    -- requires a reset of the System FPGA
    enable_i : in std_logic;

    -- Xilinx loader module interface (see xilinx_loader.vhd) for descriptions.
    xldr_start_o   : out std_logic;
    xldr_mode_o    : out std_logic;
    xldr_data_o    : out std_logic_vector(31 downto 0);
    xldr_dsize_o   : out std_logic_vector(1 downto 0);
    xldr_dlast_o   : out std_logic;
    xldr_msbf_o    : out std_logic;
    xldr_done_i    : in  std_logic;
    xldr_rd_i      : in  std_logic;
    xldr_empty_o   : out std_logic;
    xldr_startup_o : out std_logic;
    xldr_clk_div_o : out std_logic_vector(6 downto 0);

    -- SPI bus to the flash memory
    spi_cs_n_o : out std_logic;
    spi_sclk_o : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic;

    no_bitstream_p1_o : out std_logic
    );

end flash_boot;

architecture behavioral of flash_boot is

  component m25p_flash
    port (
      clk_sys_i  : in  std_logic;
      rst_n_i    : in  std_logic;
      regs_i     : in  t_sxldr_out_registers;
      regs_o     : out t_sxldr_in_registers;
      set_addr_i : in  std_logic;
      addr_i     : in  std_logic_vector(23 downto 0);
      read_i     : in  std_logic;
      data_o     : out std_logic_vector(7 downto 0);
      ready_o    : out std_logic;
      spi_cs_n_o : out std_logic;
      spi_sclk_o : out std_logic;
      spi_mosi_o : out std_logic;
      spi_miso_i : in  std_logic);
  end component;

  type t_boot_state is (STARTUP, SELECT_SDB, WAIT_SELECT_SDB, CHECK_SIG0, CHECK_SIG1, CHECK_SIG2, CHECK_SIG3, SELECT_BITSTREAM, WAIT_SELECT_BITSTREAM, FETCH_BS_BYTE, LOAD_BS_BYTE, NO_BITSTREAM, BOOT_DONE);

  -- helper procedure to eliminate redundant code in the main FSM. Compares
  -- subsequent bytes of the SDB filesystem magic ID and advances the FSM if it
  -- matches.
  procedure f_check_signature (
    signal ready : in  std_logic;
    signal data  : in  std_logic_vector(7 downto 0);
    byte_id      :     integer;
    signal state : out t_boot_state;
    next_state   :     t_boot_state;
    signal read  : out std_logic;
    read_next    :     std_logic) is
  begin
    if ready = '1' then
      if data = c_SDB_SIGNATURE(byte_id) then
        state <= next_state;
      else
        state <= NO_BITSTREAM;
      end if;
      read <= read_next;
    else
      read <= '0';
    end if;
  end f_check_signature;

  signal flash_set_addr : std_logic;
  signal flash_addr     : std_logic_vector(23 downto 0);
  signal flash_read     : std_logic;
  signal flash_data     : std_logic_vector(7 downto 0);
  signal flash_ready    : std_logic;

  signal byte_count : unsigned(23 downto 0);

  signal state                                 : t_boot_state;
  signal no_bitstream_int, no_bitstream_int_d0 : std_logic;
begin  -- rtl

  U_Flash_Controller : m25p_flash
    port map (
      clk_sys_i  => clk_sys_i,
      rst_n_i    => rst_n_i,
      regs_i     => regs_i,
      regs_o     => regs_o,
      set_addr_i => flash_set_addr,
      addr_i     => flash_addr,
      read_i     => flash_read,
      data_o     => flash_data,
      ready_o    => flash_ready,
      spi_cs_n_o => spi_cs_n_o,
      spi_sclk_o => spi_sclk_o,
      spi_mosi_o => spi_mosi_o,
      spi_miso_i => spi_miso_i);


  -- We know our endian
  xldr_msbf_o <= '0';

  -- We startup the FPGA immediately after loading the bitstream if
  -- booting from the flash (no need to mess around with VME buffer switching,
  -- since while we boot up from flash, the VME is in passive mode)
  xldr_startup_o <= '1';

  -- 32 MHz should be just fine.
  xldr_clk_div_o <= "0000001";

  process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' or enable_i = '0' then
        state            <= STARTUP;
        flash_set_addr   <= '0';
        flash_read       <= '0';
        xldr_start_o     <= '0';
        xldr_empty_o     <= '1';
        no_bitstream_int <= '0';
      else
        case state is
-- Wait until we are allowed to start flash boot sequence
          when STARTUP =>
            if enable_i = '1' then
              state      <= SELECT_SDB;
              byte_count <= (others => '0');
            end if;

-- Go to the SDB record location
          when SELECT_SDB =>
            flash_set_addr <= '1';
            flash_addr     <= c_SDB_ROOT_OFFSET;
            state          <= WAIT_SELECT_SDB;

-- Wait until the address is set
          when WAIT_SELECT_SDB =>
            if flash_ready = '1' then
              flash_read <= '1';
              state      <= CHECK_SIG0;
            else
              flash_set_addr <= '0';
            end if;

-- Read and check 4 subsequent bytes of the signature 'SDB-'. If OK, proceed
-- with loading the bitstream
          when CHECK_SIG0 =>
            f_check_signature(flash_ready, flash_data, 0, state, CHECK_SIG1, flash_read, '1');
          when CHECK_SIG1 =>
            f_check_signature(flash_ready, flash_data, 1, state, CHECK_SIG2, flash_read, '1');
          when CHECK_SIG2 =>
            f_check_signature(flash_ready, flash_data, 2, state, CHECK_SIG3, flash_read, '1');
          when CHECK_SIG3 =>
            f_check_signature(flash_ready, flash_data, 3, state, SELECT_BITSTREAM, flash_read, '0');

-- Go to the beginning of the 'afpga.bin' file in the filesystem (fixed location)
          when SELECT_BITSTREAM =>
            xldr_start_o   <= '1';
            flash_set_addr <= '1';
            flash_addr     <= c_SDB_BITSTREAM_OFFSET;
            state          <= WAIT_SELECT_BITSTREAM;

-- ... and wait until the flash address is set
          when WAIT_SELECT_BITSTREAM =>
            xldr_start_o   <= '0';
            flash_set_addr <= '0';

            if(flash_ready = '1') then
              state      <= FETCH_BS_BYTE;
              flash_read <= '1';
            else
              flash_read <= '0';
            end if;

-- Fetch another byte of the bitstream
          when FETCH_BS_BYTE =>
            if(flash_ready = '1') then
              xldr_empty_o            <= '0';
              xldr_data_o(7 downto 0) <= flash_data;
              xldr_dsize_o            <= "00";
              xldr_dlast_o            <= '0';
              state                   <= LOAD_BS_BYTE;
            else
              flash_read <= '0';
            end if;

-- And push it to the Xilinx Loader module
          when LOAD_BS_BYTE =>

            if(xldr_rd_i = '1') then
              flash_read   <= '1';
              xldr_empty_o <= '1';

-- AFPGA indicated finish of bitstream download?
              if(xldr_done_i = '1') then

                state <= BOOT_DONE;
-- ... or we exceeded maximum bitstream size (something is seriously wrong on board
-- or the BS is invalid)
              elsif byte_count = unsigned(c_BITSTREAM_SIZE) then
                state <= NO_BITSTREAM;
-- otherwise, just proceed with another byte of the BS
              else
                state <= FETCH_BS_BYTE;
              end if;

              byte_count <= byte_count + 1;
            else
              flash_read <= '0';
            end if;

-- We have no (or invalid) bitstream. Wait until reset
          when NO_BITSTREAM =>
            flash_read       <= '0';
            no_bitstream_int <= '1';
            if enable_i = '0' then
              state <= STARTUP;
            end if;

-- Bitstream was correctly loaded. Wait forever (or until reset).
          when BOOT_DONE =>
            flash_read <= '0';
            
        end case;
      end if;
    end if;
  end process;

  p_gen_no_bitstream_pulse : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        no_bitstream_p1_o   <= '0';
        no_bitstream_int_d0 <= '0';
      else
        no_bitstream_int_d0 <= no_bitstream_int;
        no_bitstream_p1_o   <= no_bitstream_int and not no_bitstream_int_d0;
      end if;
    end if;
  end process;
  
  
end behavioral;

