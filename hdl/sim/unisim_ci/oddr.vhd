library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Simple re-implementation of ODDR funcitonality
--! No generics supported, here for compatibility with the real Xilinx primitive model
entity ODDR is
    generic (
        DDR_CLK_EDGE : string := "OPPOSITE_EDGE";
        INIT : bit := '0';
        IS_C_INVERTED : bit := '0';
        IS_D1_INVERTED : bit := '0';
        IS_D2_INVERTED : bit := '0';
        SRTYPE : string := "SYNC"
     );
     port (
        Q : out std_ulogic; -- DDR output
        C : in std_ulogic;  -- clock
        CE : in std_ulogic; -- clock enable
        D1 : in std_ulogic; -- data in (rising edge)
        D2 : in std_ulogic; -- data in (falling edge)
        R : in std_ulogic := 'L';   -- reset
        S : in std_ulogic := 'L'    -- set
     );
end entity ODDR;
 
architecture RTL of ODDR is
    
begin

    process (c, r, s) is
    begin
        if r = '1' then
            q <= '0';
        elsif s = '1' then
            q  <= '1';
        elsif rising_edge(c) and CE = '1' then
            q  <= D1;
        elsif falling_edge(c) and CE = '1' then
            q <= D2;
        end if;
    end process;
    
    
end architecture RTL;
