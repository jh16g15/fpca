----------------------------------------------------------------------------------
-- Joseph Hindmarsh Septemper 2022
--
-- Wishbone shim to connect a generic "memory" style interface to a wishbone bus
--
-- TODOs:
--  * testbench
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wb_pkg.all;

entity wb_mem_shim is
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_in  : in t_wb_mosi;
        wb_miso_out : out t_wb_miso;

        mem_enable_out : out std_logic;
        mem_we_out     : out std_logic;
        mem_addr_out   : out std_logic_vector(31 downto 0);
        mem_wdata_out  : out std_logic_vector(31 downto 0);
        mem_rdata_in   : in std_logic_vector(31 downto 0)
    );
end entity wb_mem_shim;

architecture rtl of wb_mem_shim is

begin
    -- this slave can always respond to requests, so no stalling is required
    wb_miso_out.stall <= '0';

    --! unsupported
    wb_miso_out.err <= '0';
    wb_miso_out.rty <= '0';

    --! Add our 1 cycle wait state for reads
    wb_ack_proc : process (wb_clk, wb_reset) is
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                wb_miso_out.ack <= '0';
            else
                wb_miso_out.ack <= wb_mosi_in.stb and (not wb_miso_out.stall);
            end if;
        end if;
    end process;

    mem_enable_out <= wb_mosi_in.stb and (not wb_miso_out.stall);
    mem_we_out <= wb_mosi_in.we;
    mem_addr_out <= wb_mosi_in.adr;
    mem_wdata_out <= wb_mosi_in.wdat;
    wb_miso_out.rdat <= mem_rdata_in;

end architecture;