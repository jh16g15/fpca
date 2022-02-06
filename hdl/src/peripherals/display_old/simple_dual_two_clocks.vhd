-- UG901 (v2018.3), Synthesis pg121 December 19, 2018 www.xilinx.com
-- Simple Dual-Port Block RAM with Two Clocks
-- Correct Modelization with a Shared Variable
-- File: simple_dual_two_clocks.vhd
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_textio.all;

library std;
use std.textio.all;

entity simple_dual_two_clocks is
generic(
	ADDR_W         : integer   := 10;
	DATA_W         : integer   := 16;
	DEPTH          : integer   := 1024;
	USE_INIT_FILE  : boolean   := false;
	INIT_FILE_NAME : string    := "";
	INIT_FILE_IS_HEX : boolean  := true
);
port(
	clka   : in    std_logic;
	clkb   : in    std_logic;
	ena    : in    std_logic;
	enb    : in    std_logic;
	wea    : in    std_logic;
	addra  : in    std_logic_vector(ADDR_W-1 downto 0);
	addrb  : in    std_logic_vector(ADDR_W-1 downto 0);
	dia    : in    std_logic_vector(DATA_W-1 downto 0);
	dob    : out   std_logic_vector(DATA_W-1 downto 0)
);
end simple_dual_two_clocks;

architecture syn of simple_dual_two_clocks is
	type ram_type is array (0 to DEPTH-1) of std_logic_vector(DATA_W-1 downto 0);


	impure function InitRamFromFile (RamFileName : in string; is_hex : in boolean) return ram_type is
        FILE RamFile : text is in RamFileName;
        variable RamFileLine : line;
        variable RAM : ram_type;
    begin
        for I in ram_type'range loop
            readline (RamFile, RamFileLine);
			if is_hex then
            	hread (RamFileLine, RAM(I));
			else
				bread (RamFileLine, RAM(I));
			end if;
        end loop;
        return RAM;
    end function;

    -- Either initialise with 0s or from a provided file
    impure function InitRam return ram_type is
        variable RAM : ram_type;
    begin
        if USE_INIT_FILE = true then
            RAM := InitRamFromFile(INIT_FILE_NAME, INIT_FILE_IS_HEX);
        else
            RAM := (others => (others => '0'));
        end if;
        return RAM;
    end function;

	shared variable RAM : ram_type := InitRam; -- call function InitRam



begin
	process(clka)
	begin
		if clka'event and clka = '1' then
			if ena = '1' then
				if wea = '1' then
					RAM(conv_integer(addra)) := dia;
				end if;
			end if;
		end if;
	end process;

	process(clkb)
	begin
		if clkb'event and clkb = '1' then
			if enb = '1' then
				dob <= RAM(conv_integer(addrb));
			end if;
		end if;
	end process;
end syn;