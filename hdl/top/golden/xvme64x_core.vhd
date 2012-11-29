library ieee;
use ieee.STD_LOGIC_1164.all;
use WORK.wishbone_pkg.all;
use work.vme64x_pack.all;

entity xvme64x_core is
  
  port (
    clk_i   : in std_logic;
    rst_n_i : in std_logic;

    rst_n_o : out std_logic;

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

    master_o : out t_wishbone_master_out;
    master_i : in  t_wishbone_master_in;

    irq_i     : in  std_logic;
    irq_ack_o : out std_logic

    );

end xvme64x_core;

architecture wrapper of xvme64x_core is

  component VME64xCore_Top
    generic (
      g_wb_data_width      : integer := 32;
      g_wb_addr_width : integer := 64;
      g_CRAM_SIZE  : integer := 1024);
    port (
      clk_i           : in  std_logic;
      reset_o         : out std_logic;
      VME_AS_n_i      : in  std_logic;
      VME_RST_n_i     : in  std_logic;
      VME_WRITE_n_i   : in  std_logic;
      VME_AM_i        : in  std_logic_vector(5 downto 0);
      VME_DS_n_i      : in  std_logic_vector(1 downto 0);
      VME_GA_i        : in  std_logic_vector(5 downto 0);
      VME_BERR_o      : out std_logic;
      VME_DTACK_n_o   : out std_logic;
      VME_RETRY_n_o   : out std_logic;
      VME_LWORD_n_i   : in  std_logic;
      VME_LWORD_n_o   : out std_logic;
      VME_ADDR_i      : in  std_logic_vector(31 downto 1);
      VME_ADDR_o      : out std_logic_vector(31 downto 1);
      VME_DATA_i      : in  std_logic_vector(31 downto 0);
      VME_DATA_o      : out std_logic_vector(31 downto 0);
      VME_IRQ_o       : out std_logic_vector(6 downto 0);
      VME_IACKIN_n_i  : in  std_logic;
      VME_IACK_n_i    : in  std_logic;
      VME_IACKOUT_n_o : out std_logic;
      VME_DTACK_OE_o  : out std_logic;
      VME_DATA_DIR_o  : out std_logic;
      VME_DATA_OE_N_o : out std_logic;
      VME_ADDR_DIR_o  : out std_logic;
      VME_ADDR_OE_N_o : out std_logic;
      VME_RETRY_OE_o  : out std_logic;
      DAT_i           : in  std_logic_vector(g_wb_data_width - 1 downto 0);
      DAT_o           : out std_logic_vector(g_wb_data_width - 1 downto 0);
      ADR_o           : out std_logic_vector(g_wb_addr_width - 1 downto 0);
      CYC_o           : out std_logic;
      ERR_i           : in  std_logic;
      RTY_i           : in  std_logic;
      SEL_o           : out std_logic_vector(f_div8(g_wb_addr_width) - 1 downto 0);
      STB_o           : out std_logic;
      ACK_i           : in  std_logic;
      WE_o            : out std_logic;
      STALL_i         : in  std_logic;
      INT_ack_o       : out std_logic;
      IRQ_i           : in  std_logic;
      debug           : out std_logic_vector(7 downto 0));
  end component;

  signal rst_in, rst_out          : std_logic;
  signal dat_out, dat_in : std_logic_vector(31 downto 0);
  signal adr_out : std_logic_vector(63 downto 0);
  
begin  -- wrapper

  rst_in  <= not rst_n_i;
  rst_n_o <= rst_n_i and (not rst_out);

  U_Wrapped_VME : VME64xCore_Top
    port map (
      clk_i           => clk_i,
      reset_o         => rst_out,
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
      VME_LWORD_n_i => VME_LWORD_n_b_i,
      VME_LWORD_n_o => VME_LWORD_n_b_o,
      VME_ADDR_i    => VME_ADDR_b_i,
      VME_ADDR_o    => VME_ADDR_b_o,
      VME_DATA_i    => VME_DATA_b_i,
      VME_DATA_o    => VME_DATA_b_o,
      VME_IRQ_o     => VME_IRQ_n_o,
      VME_IACKIN_n_i  => VME_IACKIN_n_i,
      VME_IACK_n_i    => VME_IACK_n_i,
      VME_IACKOUT_n_o => VME_IACKOUT_n_o,
      VME_DTACK_OE_o  => VME_DTACK_OE_o,
      VME_DATA_DIR_o  => VME_DATA_DIR_o,
      VME_DATA_OE_N_o => VME_DATA_OE_N_o,
      VME_ADDR_DIR_o  => VME_ADDR_DIR_o,
      VME_ADDR_OE_N_o => VME_ADDR_OE_N_o,

      DAT_i   => dat_in,
      DAT_o   => dat_out,
      ADR_o   => adr_out,
      CYC_o   => master_o.cyc,
      ERR_i   => master_i.err,
      RTY_i   => master_i.rty,
      SEL_o   => open,
      STB_o   => master_o.stb,
      ACK_i   => master_i.ack,
      WE_o    => master_o.we,
      STALL_i => master_i.stall,
      IRQ_i   => irq_i,
      INT_ack_o => irq_ack_o
      );

  master_o.dat <= dat_out(31 downto 0);
  master_o.sel <= (others => '1');
  master_o.adr <= adr_out(29 downto 0) & "00";
  dat_in       <= master_i.dat;

--  VME_IRQ_n_o <= (others => '0');
  
  
  
end wrapper;
