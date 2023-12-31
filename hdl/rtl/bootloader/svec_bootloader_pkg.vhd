-- SPDX-FileCopyrightText: 2022 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+

-------------------------------------------------------------------------------
-- Title      : SVEC FPGA Bootloader main package
-- Project    : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File       : svec_bootloader_pkg.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-01-24
-- Last update: 2022-11-09
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Contains definitions of the bootloader's parameters (base
-- addresses and timing).
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package svec_bootloader_pkg is

  type t_byte_array is array(integer range <>) of std_logic_vector(7 downto 0);

-- SDB descriptor magic ID. Used to check for presence of valid filesystem
-- in the flash memory
  constant c_SDB_SIGNATURE : t_byte_array(0 to 3) := (x"53", x"44", x"42", x"2D");

-- Filesystem root offset (i.e. the location of the SDB record table)
  constant c_SDB_ROOT_OFFSET : std_logic_vector(23 downto 0) := x"600000";

-- Offset of the file containing our bitstream (afpga.bin)
  constant c_SDB_BITSTREAM_OFFSET : std_logic_vector(23 downto 0) := x"100000";

-- Size of our bitstream (maximum possible value). Used to limit download time
-- when the bitstream is invalid or the FPGA is not responding.
  constant c_BITSTREAM_SIZE : std_logic_vector(23 downto 0) := x"408000";

-- Signature of the bootloader in the card's CSR space. Used by the software
-- for probing the bootloader core.
  constant c_CSR_SIGNATURE : std_logic_vector(31 downto 0) := x"53564543";

end svec_bootloader_pkg;
