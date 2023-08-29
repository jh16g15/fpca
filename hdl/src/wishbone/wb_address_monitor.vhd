library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

entity wb_address_monitor is
    generic
    (
        G_ADDR : std_logic_vector(31 downto 0) := x"0000_0000"
    );
    port
    (
        wb_clk   : in std_logic;

        wb_mosi  : in t_wb_mosi;
        wb_miso : in t_wb_miso;

        write_cmd_stb : out std_logic;
        read_cmd_stb  : out std_logic
    );
end entity wb_address_monitor;

architecture rtl of wb_address_monitor is

begin
    wb_proc : process (wb_clk) is
    begin
        if rising_edge(wb_clk) then
            -- defaults
            write_cmd_stb <= '0';
            read_cmd_stb  <= '0';

            if wb_mosi.stb = '1' and wb_miso.stall = '0' then
                if wb_mosi.adr = G_ADDR then
                    if wb_mosi.we = '1' then
                        write_cmd_stb <= '1';
                    else
                        read_cmd_stb <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;