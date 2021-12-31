--! Top level module of the FPCA CPU (RV32I)
--! Instantiates all of the other 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all;

entity cpu_top is
    port (
        clk   : in std_logic;
        reset : in std_logic;

        -- Instruction Fetch Wishbone Master
        if_wb_mosi_out : out t_wb_mosi;
        if_wb_miso_in : in t_wb_miso;
        
        -- Memory Wishbone Master
        mem_wb_mosi_out : out t_wb_mosi;
        mem_wb_miso_in : in t_wb_miso

    );
end entity cpu_top;

architecture rtl of cpu_top is

begin

    

end architecture;