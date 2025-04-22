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
        variable v_addr_int : integer;
    begin
        if rising_edge(clk) then
            wb_miso.ack <= wb_mosi.stb and not wb_miso.stall;
            v_addr_int := to_integer(unsigned(wb_mosi.adr(31 downto 2))); -- word address 
            -- each 16-bit location is numbered in an incrememting fashion (so 0x0 32b = 0x0001_0000, 0x4 = 0x0003_0002 etc 
            wb_miso.rdat <= std_logic_vector(to_unsigned(v_addr_int * 2 + 1, 16) & to_unsigned(v_addr_int * 2, 16)); 
        end if;
    end process;
    

end architecture RTL;
