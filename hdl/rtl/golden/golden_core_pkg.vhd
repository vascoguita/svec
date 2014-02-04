library ieee;
use ieee.STD_LOGIC_1164.all;

use work.wishbone_pkg.all;

package golden_core_pkg is

  component golden_core
    generic (
      g_slot_count : integer range 1 to 4);
    port (
      clk_sys_i     : in  std_logic;
      rst_n_i       : in  std_logic;
      slave_i       : in  t_wishbone_slave_in;
      slave_o       : out t_wishbone_slave_out;
      fmc_scl_o     : out std_logic_vector(g_slot_count-1 downto 0);
      fmc_sda_o     : out std_logic_vector(g_slot_count-1 downto 0);
      fmc_scl_i     : in  std_logic_vector(g_slot_count-1 downto 0);
      fmc_sda_i     : in  std_logic_vector(g_slot_count-1 downto 0);
      fmc_prsnt_n_i : in  std_logic_vector(g_slot_count-1 downto 0));
  end component;

  constant c_xwb_golden_sdb : t_sdb_device := (
    abi_class     => x"0000",              -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"7",                 -- 8/16/32-bit port granularity
    sdb_component => (
      addr_first  => x"0000000000000000",
      addr_last   => x"00000000000000ff",
      product     => (
        vendor_id => x"000000000000CE42",  -- CERN
        device_id => x"676f6c64",
        version   => x"00000001",
        date      => x"20130516",
        name      => "WB-Golden-Core     ")));

end golden_core_pkg;
