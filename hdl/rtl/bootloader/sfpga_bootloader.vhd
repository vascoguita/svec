-------------------------------------------------------------------------------
-- Title        : SVEC Bootloader Core
-- Project      : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File         : sfpga_bootloader.vhd
-- Author       : Tomasz Włostowski
-- Company      : CERN BE-CO-HT
-- Created      : 2013-01-24
-- Last update  : 2013-01-25
-- Platform     : FPGA-generic
-- Standard     : VHDL '93
-------------------------------------------------------------------------------
-- Description: The main Application FPGA bootloader core:
-- - attepmpts to boot up the AFPGA from the Flash memory (immediately after
--   reset
-- - allows the host to boot up the AFPGA directly (via Wishbone/VME)
-- - provides raw access to the Flash SPI controller from the host (for
--   in-system reprogramming of the Flash)
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
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.sxldr_wbgen2_pkg.all;

entity sfpga_bootloader is
  generic(
    g_interface_mode      : t_wishbone_interface_mode      := CLASSIC;
    g_address_granularity : t_wishbone_address_granularity := WORD;
    g_idr_value           : std_logic_vector(31 downto 0)  := x"626f6f74"
    );
  port (
-- system clock
    clk_sys_i : in std_logic;
-- synchronous reset, active LOW
    rst_n_i   : in std_logic;

-- Wishbone bus
    wb_cyc_i   : in  std_logic;
    wb_stb_i   : in  std_logic;
    wb_we_i    : in  std_logic;
    wb_adr_i   : in  std_logic_vector(c_wishbone_address_width - 1 downto 0);
    wb_sel_i   : in  std_logic_vector((c_wishbone_data_width + 7) / 8 - 1 downto 0);
    wb_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_ack_o   : out std_logic;
    wb_stall_o : out std_logic;

-- Configuration clock (to pin CCLK)
    xlx_cclk_o      : out std_logic := '0';
-- Data output (to pin D0/DIN)
    xlx_din_o       : out std_logic;
-- Program enable pin (active low, to pin PROG_B)
    xlx_program_b_o : out std_logic := '1';
-- Init ready pin (active low, to pin INIT_B)
    xlx_init_b_i    : in  std_logic;
-- Configuration done pin (to pin DONE)
    xlx_done_i      : in  std_logic;
-- FPGA suspend pin
    xlx_suspend_o   : out std_logic;

-- FPGA mode select pin. Connect to M1..M0 pins of the FPGA or leave open if
-- the pins are hardwired on the PCB
    xlx_m_o : out std_logic_vector(1 downto 0);

-- Trigger sequence detector output:
-- 1-pulse: boot trigger sequence detected
    boot_trig_p1_o : out std_logic := '0';

-- Exit bootloader mode, 1-pulse on write 1 to CSR.EXIT
    boot_exit_p1_o : out std_logic := '0';

-- Bootloader enable. When disabled, all WB writes except for the trigger register are
-- ignored.
    boot_en_i : in std_logic;

-- Bitstream flash interface (SPI)
    spi_cs_n_o : out std_logic;
    spi_sclk_o : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic
    );

end sfpga_bootloader;

architecture behavioral of sfpga_bootloader is


  -- Some helper structures to make multiplexing easier.
  type t_xilinx_boot_in is record
    swrst   : std_logic;
    start   : std_logic;
    data    : std_logic_vector(31 downto 0);
    dsize   : std_logic_vector(1 downto 0);
    dlast   : std_logic;
    msbf    : std_logic;
    empty   : std_logic;
    startup : std_logic;
    clk_div : std_logic_vector(6 downto 0);
  end record;

  type t_xilinx_boot_out is record
    rd    : std_logic;
    done  : std_logic;
    error : std_logic;
    busy  : std_logic;
  end record;

  component svec_xloader_wb
    port (
      rst_n_i    : in  std_logic;
      clk_sys_i  : in  std_logic;
      wb_adr_i   : in  std_logic_vector(2 downto 0);
      wb_dat_i   : in  std_logic_vector(31 downto 0);
      wb_dat_o   : out std_logic_vector(31 downto 0);
      wb_cyc_i   : in  std_logic;
      wb_sel_i   : in  std_logic_vector(3 downto 0);
      wb_stb_i   : in  std_logic;
      wb_we_i    : in  std_logic;
      wb_ack_o   : out std_logic;
      wb_stall_o : out std_logic;
      regs_i     : in  t_sxldr_in_registers;
      regs_o     : out t_sxldr_out_registers);
  end component;

  component flash_boot
    port (
      clk_sys_i      : in  std_logic;
      rst_n_i        : in  std_logic;
      regs_i         : in  t_sxldr_out_registers;
      regs_o         : out t_sxldr_in_registers;
      enable_i       : in  std_logic;
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
      spi_cs_n_o     : out std_logic;
      spi_sclk_o     : out std_logic;
      spi_mosi_o     : out std_logic;
      spi_miso_i     : in  std_logic);
  end component;

  component xilinx_loader
    port (
      clk_sys_i       : in  std_logic;
      rst_n_i         : in  std_logic;
      csr_swrst_i     : in  std_logic;
      csr_start_i     : in  std_logic;
      csr_clk_div_i   : in  std_logic_vector(6 downto 0);
      csr_data_i      : in  std_logic_vector(31 downto 0);
      csr_dsize_i     : in  std_logic_vector(1 downto 0);
      csr_msbf_i      : in  std_logic;
      csr_dlast_i     : in  std_logic;
      csr_error_o     : out std_logic;
      csr_done_o      : out std_logic;
      csr_rd_o        : out std_logic;
      csr_empty_i     : in  std_logic;
      csr_startup_i   : in  std_logic;
      csr_busy_o      : out std_logic;
      xlx_cclk_o      : out std_logic := '0';
      xlx_din_o       : out std_logic;
      xlx_program_b_o : out std_logic := '1';
      xlx_init_b_i    : in  std_logic;
      xlx_done_i      : in  std_logic);
  end component;

  type t_bootseq_state is (TWORD0, TWORD1, TWORD2, TWORD3, TWORD4, TWORD5, TWORD6, TWORD7, BOOT_READY);

  type t_boot_source is (FLASH, HOST);

  signal wb_in  : t_wishbone_master_out;
  signal wb_out : t_wishbone_master_in;

  signal regs_in                                  : t_sxldr_out_registers;
  signal regs_out, regs_out_local, regs_out_flash : t_sxldr_in_registers;

  signal from_flash_ldr, from_host_ldr, to_xilinx_boot : t_xilinx_boot_in;
  signal to_flash_ldr, to_host_ldr, from_xilinx_boot   : t_xilinx_boot_out;

  signal boot_state       : t_bootseq_state;
  signal boot_source      : t_boot_source;
  signal boot_trig_p1_int : std_logic;
  signal flash_enable     : std_logic;

  -- Trivial helper for boot sequence detection. Advances the state machine if
  -- a matching byte has been detected or goes back to the starting point.
  procedure f_bootseq_step(signal st : out t_bootseq_state; nstate : t_bootseq_state; match_val : std_logic_vector; regs : t_sxldr_out_registers) is
  begin
    if(regs.btrigr_wr_o = '1') then
      if(regs.btrigr_o = match_val) then
        st <= nstate;
      else
        st <= TWORD0;
      end if;
    end if;
  end f_bootseq_step;


begin  -- behavioral

-- Selects the boot source: upon reset, we try to boot up from flash.
-- Host bootloader is activated by writing a magic trigger sequence.
  p_select_boot_mode : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        boot_source <= FLASH;
      elsif(boot_trig_p1_int = '1') then
        boot_source <= HOST;
      end if;
    end if;
  end process;


-- Flash bootloader engine: finds an SDB file containing the AFPGA bitstream in
-- the flash, and if present, loads it to the SFPGA via U_Xilinx_Loader

  flash_enable <= '1' when boot_source = FLASH else '0';

  U_Flash_Boot_Engine : flash_boot
    port map (
      clk_sys_i      => clk_sys_i,
      rst_n_i        => rst_n_i,
      regs_i         => regs_in,
      regs_o         => regs_out_flash,
      enable_i       => flash_enable,
      xldr_start_o   => from_flash_ldr.start,
      xldr_data_o    => from_flash_ldr.data,
      xldr_dsize_o   => from_flash_ldr.dsize,
      xldr_dlast_o   => from_flash_ldr.dlast,
      xldr_msbf_o    => from_flash_ldr.msbf,
      xldr_done_i    => to_flash_ldr.done,
      xldr_rd_i      => to_flash_ldr.rd,
      xldr_empty_o   => from_flash_ldr.empty,
      xldr_startup_o => from_flash_ldr.startup,
      xldr_clk_div_o => from_flash_ldr.clk_div,
      spi_cs_n_o     => spi_cs_n_o,
      spi_sclk_o     => spi_sclk_o,
      spi_mosi_o     => spi_mosi_o,
      spi_miso_i     => spi_miso_i);

  -- Route host registers to the boot source multiplexer (p_select_boot_source).
  from_host_ldr.start          <= regs_in.csr_start_o and boot_en_i;
  from_host_ldr.data           <= regs_in.fifo_xdata_o;
  from_host_ldr.dsize          <= regs_in.fifo_xsize_o;
  from_host_ldr.dlast          <= regs_in.fifo_xlast_o;
  from_host_ldr.msbf           <= regs_in.csr_msbf_o;
  from_host_ldr.startup        <= regs_in.csr_exit_o;
  from_host_ldr.clk_div        <= '0' & regs_in.csr_clkdiv_o;
  from_host_ldr.swrst          <= regs_in.csr_swrst_o;
  from_host_ldr.empty          <= regs_in.fifo_rd_empty_o;
  regs_out_local.csr_done_i    <= to_host_ldr.done;
  regs_out_local.csr_error_i   <= to_host_ldr.error;
  regs_out_local.csr_busy_i    <= to_host_ldr.busy;
  regs_out_local.fifo_rd_req_i <= to_host_ldr.rd;
  regs_out_local.idr_i         <= g_idr_value;

  -- Multiplexes the access to the Xilinx Serial Bootloader module between
  -- the host (accessed via Wishbine registers) and the internal Flash loader
  p_select_boot_source : process(from_host_ldr, from_flash_ldr, from_xilinx_boot)
  begin
    case boot_source is
      when FLASH =>
        to_xilinx_boot    <= from_flash_ldr;
        to_flash_ldr      <= from_xilinx_boot;
        to_host_ldr.rd    <= '0';
        to_host_ldr.done  <= '0';
        to_host_ldr.error <= '0';
        to_host_ldr.busy  <= '1';
      when HOST =>
        to_xilinx_boot     <= from_host_ldr;
        to_host_ldr        <= from_xilinx_boot;
        to_flash_ldr.rd    <= '0';
        to_flash_ldr.done  <= '0';
        to_flash_ldr.error <= '0';
        to_flash_ldr.busy  <= '1';
    end case;
  end process;

  -- The Xilinx bootloader. Takes a bitstream and loads it into a Xilinx FPGA 
  -- configured in Passive Serial mode (signals: CCLK, DIN, PROG_B, INIT_B, DONE).
  U_Xilinx_Loader : xilinx_loader
    port map (
      clk_sys_i       => clk_sys_i,
      rst_n_i         => rst_n_i,
      csr_swrst_i     => to_xilinx_boot.swrst,
      csr_start_i     => to_xilinx_boot.start,
      csr_clk_div_i   => to_xilinx_boot.clk_div,
      csr_data_i      => to_xilinx_boot.data,
      csr_dsize_i     => to_xilinx_boot.dsize,
      csr_msbf_i      => to_xilinx_boot.msbf,
      csr_dlast_i     => to_xilinx_boot.dlast,
      csr_error_o     => from_xilinx_boot.error,
      csr_done_o      => from_xilinx_boot.done,
      csr_rd_o        => from_xilinx_boot.rd,
      csr_empty_i     => to_xilinx_boot.empty,
      csr_startup_i   => to_xilinx_boot.startup,
      csr_busy_o      => from_xilinx_boot.busy,
      xlx_cclk_o      => xlx_cclk_o,
      xlx_din_o       => xlx_din_o,
      xlx_program_b_o => xlx_program_b_o,
      xlx_init_b_i    => xlx_init_b_i,
      xlx_done_i      => xlx_done_i);

  -- Bootloader trigger sequence detection.
  -- Write of 0xde, 0xad, 0xbe, 0xef, 0xca, 0xfe, 0xba, 0xbe to BTRIGR
  -- produces a pulse on boot_trig_p1_o.
  p_detect_boot_trigger : process(clk_sys_i)
  begin
    if rising_edge(clk_sys_i) then
      if rst_n_i = '0' then
        boot_trig_p1_int <= '0';
        boot_state       <= TWORD0;
      else
        case boot_state is
          when TWORD0 =>
            boot_trig_p1_int <= '0';
            f_bootseq_step(boot_state, TWORD1, x"de", regs_in);
          when TWORD1     => f_bootseq_step(boot_state, TWORD2, x"ad", regs_in);
          when TWORD2     => f_bootseq_step(boot_state, TWORD3, x"be", regs_in);
          when TWORD3     => f_bootseq_step(boot_state, TWORD4, x"ef", regs_in);
          when TWORD4     => f_bootseq_step(boot_state, TWORD5, x"ca", regs_in);
          when TWORD5     => f_bootseq_step(boot_state, TWORD6, x"fe", regs_in);
          when TWORD6     => f_bootseq_step(boot_state, TWORD7, x"ba", regs_in);
          when TWORD7     => f_bootseq_step(boot_state, BOOT_READY, x"be", regs_in);
          when BOOT_READY =>
            boot_trig_p1_int <= '1';
            boot_state       <= TWORD0;
        end case;
      end if;
    end if;
  end process;

  boot_trig_p1_o <= boot_trig_p1_int;
  boot_exit_p1_o <= regs_in.csr_exit_o;

  xlx_m_o       <= "11";                -- permamently select Passive serial
  -- boot mode
  xlx_suspend_o <= '0';                 -- suspend feature is not used

-- Pipelined-classic adapter/converter
  U_Adapter : wb_slave_adapter
    generic map (
      g_master_use_struct  => true,
      g_master_mode        => CLASSIC,
      g_master_granularity => WORD,
      g_slave_use_struct   => false,
      g_slave_mode         => g_interface_mode,
      g_slave_granularity  => g_address_granularity)
    port map (
      clk_sys_i => clk_sys_i,
      rst_n_i   => rst_n_i,

      sl_cyc_i   => wb_cyc_i,
      sl_stb_i   => wb_stb_i,
      sl_we_i    => wb_we_i,
      sl_adr_i   => wb_adr_i,
      sl_sel_i   => wb_sel_i,
      sl_dat_i   => wb_dat_i,
      sl_dat_o   => wb_dat_o,
      sl_ack_o   => wb_ack_o,
      sl_stall_o => wb_stall_o,

      master_i => wb_out,
      master_o => wb_in);

  wb_out.err   <= '0';
  wb_out.rty   <= '0';
  wb_out.stall <= '0';
  wb_out.int   <= '0';
  regs_out     <= regs_out_local or regs_out_flash;

  U_WB_SLAVE : svec_xloader_wb
    port map (
      rst_n_i   => rst_n_i,
      clk_sys_i => clk_sys_i,
      wb_adr_i  => wb_in.adr(2 downto 0),
      wb_dat_i  => wb_in.dat(31 downto 0),
      wb_dat_o  => wb_out.dat(31 downto 0),
      wb_cyc_i  => wb_in.cyc,
      wb_sel_i  => wb_in.sel(3 downto 0),
      wb_stb_i  => wb_in.stb,
      wb_we_i   => wb_in.we,
      wb_ack_o  => wb_out.ack,
      regs_o    => regs_in,
      regs_i    => regs_out);

end behavioral;
