library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;

--! Simple wishbone read-only "memory" that has the data in each word echo it's 32-bit aligned address
entity sim_wb_ro_mem is
    port(
        clk : in std_logic;
        wb_mosi : in t_wb_mosi;
	    wb_miso : out t_wb_miso := C_WB_MISO_INIT
    );
end entity sim_wb_ro_mem;

architecture RTL of sim_wb_ro_mem is
    
begin

    wb_miso.stall <= '0';
    wb_miso.err <= '0';
    wb_miso.rty <= '0';

    process (clk) is
    begin
        if rising_edge(clk) then
            wb_miso.ack <= wb_mosi.stb and not wb_miso.stall;
            wb_miso.rdat <= wb_mosi.adr(31 downto 2) & "00";
        end if;
    end process;
    

end architecture RTL;
