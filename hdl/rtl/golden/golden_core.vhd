library ieee;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.gld_wbgen2_pkg.all;

entity golden_core is

  generic(
    g_slot_count : integer range 1 to 4);
  port(
    clk_sys_i : in std_logic;
    rst_n_i   : in std_logic;

    slave_i : in  t_wishbone_slave_in;
    slave_o : out t_wishbone_slave_out;

    fmc_scl_o : out std_logic_vector(g_slot_count-1 downto 0);
    fmc_sda_o : out std_logic_vector(g_slot_count-1 downto 0);

    fmc_scl_i : in std_logic_vector(g_slot_count-1 downto 0);
    fmc_sda_i : in std_logic_vector(g_slot_count-1 downto 0);

    fmc_prsnt_n_i : in std_logic_vector(g_slot_count-1 downto 0)
    );

end golden_core;

architecture rtl of golden_core is

  component golden_wb
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
      regs_i     : in  t_gld_in_registers;
      regs_o     : out t_gld_out_registers);
  end component;

  signal regs_in  : t_gld_in_registers;
  signal regs_out : t_gld_out_registers;
  
begin  -- rtl

  regs_in.csr_slot_count_i <= std_logic_vector(to_unsigned(g_slot_count, 4));

  U_WB_Slave : golden_wb
    port map (
      rst_n_i    => rst_n_i,
      clk_sys_i  => clk_sys_i,
      wb_adr_i   => slave_i.adr(4 downto 2),
      wb_dat_i   => slave_i.dat,
      wb_dat_o   => slave_o.dat,
      wb_cyc_i   => slave_i.cyc,
      wb_sel_i   => slave_i.sel,
      wb_stb_i   => slave_i.stb,
      wb_we_i    => slave_i.we,
      wb_ack_o   => slave_o.ack,
      wb_stall_o => slave_o.stall,
      regs_i     => regs_in,
      regs_o     => regs_out);

  gen0 : if(g_slot_count >= 1) generate
    fmc_scl_o(0)                 <= regs_out.i2cr0_scl_out_o;
    fmc_sda_o(0)                 <= regs_out.i2cr0_sda_out_o;
    regs_in.i2cr0_scl_in_i       <= fmc_scl_i(0);
    regs_in.i2cr0_sda_in_i       <= fmc_sda_i(0);
    regs_in.csr_fmc_present_i(0) <= not fmc_prsnt_n_i(0);
  end generate gen0;

  gen1 : if(g_slot_count >= 2) generate
    fmc_scl_o(1)                 <= regs_out.i2cr1_scl_out_o;
    fmc_sda_o(1)                 <= regs_out.i2cr1_sda_out_o;
    regs_in.i2cr1_scl_in_i       <= fmc_scl_i(1);
    regs_in.i2cr1_sda_in_i       <= fmc_sda_i(1);
    regs_in.csr_fmc_present_i(1) <= not fmc_prsnt_n_i(1);
  end generate gen1;

  gen2 : if(g_slot_count >= 3) generate
    fmc_scl_o(2)                 <= regs_out.i2cr2_scl_out_o;
    fmc_sda_o(2)                 <= regs_out.i2cr2_sda_out_o;
    regs_in.i2cr2_scl_in_i       <= fmc_scl_i(2);
    regs_in.i2cr2_sda_in_i       <= fmc_sda_i(2);
    regs_in.csr_fmc_present_i(2) <= not fmc_prsnt_n_i(2);
  end generate gen2;

  gen3 : if(g_slot_count >= 4) generate
    fmc_scl_o(3)                 <= regs_out.i2cr3_scl_out_o;
    fmc_sda_o(3)                 <= regs_out.i2cr3_sda_out_o;
    regs_in.i2cr3_scl_in_i       <= fmc_scl_i(3);
    regs_in.i2cr3_sda_in_i       <= fmc_sda_i(3);
    regs_in.csr_fmc_present_i(3) <= not fmc_prsnt_n_i(3);
  end generate gen3;

end rtl;
