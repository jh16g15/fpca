library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Simple re-implementation of IOBUF funcitonality
--! No generics supported, here for compatibility with the real Xilinx primitive model
entity IOBUF is
    generic (
       DRIVE : integer := 12;
       IBUF_LOW_PWR : boolean := TRUE;
       IOSTANDARD : string := "DEFAULT";
       SLEW : string := "SLOW"
    );
    port (
       O : out std_ulogic;
       IO : inout std_ulogic;
       I : in std_ulogic;
       T : in std_ulogic
    );
  end entity;

  architecture RTL of IOBUF is
    
  begin
    O <= IO; -- "input" pin of FPGA
    
    -- tristate output buffer 
    process (all) is
    begin
        case(T) is
            when '1' => IO <= I; 
            when 'X' => IO <= 'X'; -- allow X propagation
            when others => IO  <= 'Z'; 
        end case;
    end process;
    
  end architecture RTL;
  