----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.06.2020 01:52:18
-- Design Name: 
-- Module Name: display_colour_ram - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity display_colour_ram is
    Port ( clk : in STD_LOGIC;
           colour_code : in STD_LOGIC_VECTOR (9 downto 0);
           fg_colour : out STD_LOGIC_VECTOR (11 downto 0);
           bg_colour : out STD_LOGIC_VECTOR (11 downto 0)
   );
end display_colour_ram;

architecture rtl of display_colour_ram is
    signal fg_colour_code : unsigned(5 downto 0);
    signal bg_colour_code : unsigned(3 downto 0);
    signal fg_colour_code_int : integer;
    signal bg_colour_code_int : integer;
    
begin
    fg_colour_code <= unsigned(colour_code(9 downto 4));
    bg_colour_code <= unsigned(colour_code(3 downto 0));
    fg_colour_code_int <= to_integer(fg_colour_code);
    bg_colour_code_int <= to_integer(bg_colour_code);
    
    colour_decode_proc : process(all) is
    begin
        if(rising_edge(clk)) then
            case fg_colour_code_int is -- max 2^6=64 colour
                when 0 => fg_colour <= x"000"; -- Black
                when 1 => fg_colour <= x"F00"; -- Red
                when 2 => fg_colour <= x"0F0"; -- Green
                when 3 => fg_colour <= x"00F"; -- Blue
                when 4 => fg_colour <= x"FF0"; -- Yellow
                when 5 => fg_colour <= x"F0F"; -- Magenta
                when 6 => fg_colour <= x"0FF"; -- Cyan
                when 7 => fg_colour <= x"FFF"; -- White
                when 8 => fg_colour <= x"777"; -- Grey
                when others => fg_colour <= x"000";
            end case;
            
            case bg_colour_code_int is -- max 2^4=16 colour
                when 0 => bg_colour <= x"000"; -- Black
                when 1 => bg_colour <= x"F00"; -- Red
                when 2 => bg_colour <= x"0F0"; -- Green
                when 3 => bg_colour <= x"00F"; -- Blue
                when 4 => bg_colour <= x"FF0"; -- Yellow
                when 5 => bg_colour <= x"F0F"; -- Magenta
                when 6 => bg_colour <= x"0FF"; -- Cyan
                when 7 => bg_colour <= x"FFF"; -- White
                when 8 => bg_colour <= x"777"; -- Grey
                when others => fg_colour <= x"000";
            end case;
        end if;
    end process colour_decode_proc;

end rtl;
