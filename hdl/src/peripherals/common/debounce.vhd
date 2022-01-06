library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
    generic (
        REFCLK_FREQ        : integer   := 100_000_000;
        DEBOUNCE_PERIOD_MS : integer   := 50;
        INIT_OUT           : std_logic := '0'
    );
    port (
        clk     : in std_logic;
        val_in  : in std_logic;
        val_out : out std_logic := INIT_OUT
    );
end entity debounce;

architecture rtl of debounce is
    constant DB_COUNT_THRES : integer := DEBOUNCE_PERIOD_MS * REFCLK_FREQ / 1000;
    signal count            : integer := DB_COUNT_THRES;
    signal in_prev          : std_logic;
begin

    process (clk)
    begin
        if rising_edge(clk) then
            in_prev <= val_in;
            -- if val_in changed, reset the counter
            if in_prev = not val_in then
                count <= DB_COUNT_THRES;
            else
                count <= count - 1;
            end if;
            if count = 0 then
                val_out <= in_prev;
            end if;

        end if;
    end process;
end architecture;