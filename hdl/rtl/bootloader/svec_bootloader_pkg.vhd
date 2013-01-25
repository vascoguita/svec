-------------------------------------------------------------------------------
-- Title      : SVEC FPGA Bootloader main package
-- Project    : Simple VME64x FMC Carrier (SVEC)
-------------------------------------------------------------------------------
-- File       : svec_bootloader_pkg.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2011-01-24
-- Last update: 2013-01-25
-- Platform   : FPGA-generic
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Contains definitions of the bootloader's parameters (base
-- addresses and timing).
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

package svec_bootloader_pkg is

  type t_byte_array is array(integer range <>) of std_logic_vector(7 downto 0);

-- SDB descriptor magic ID. Used to check for presence of valid filesystem
-- in the flash memory
  constant c_SDB_SIGNATURE : t_byte_array(0 to 3) := (x"53", x"44", x"42", x"2D");

-- Filesystem root offset (i.e. the location of the SDB record table)
  constant c_SDB_ROOT_OFFSET : std_logic_vector(23 downto 0) := x"500000";

-- Offset of the file containing our bitstream (afpga.bin)
  constant c_SDB_BITSTREAM_OFFSET : std_logic_vector(23 downto 0) := x"100000";

-- Size of our bitstream (maximum possible value). Used to limit download time
-- when the bitstream is invalid or the FPGA is not responding.
  constant c_BITSTREAM_SIZE : std_logic_vector(23 downto 0) := x"400000";

-- Signature of the bootloader in the card's CSR space. Used by the software
-- for probing the bootloader core.
  constant c_CSR_SIGNATURE : std_logic_vector(31 downto 0) := x"53564543";

end svec_bootloader_pkg;
