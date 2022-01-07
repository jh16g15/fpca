library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
    generic (
        REFCLK_FREQ        : positive := 100_000_000;
        DEBOUNCE_PERIOD_MS : integer range 0 to 50 := 50;
        INIT_OUT           : std_logic := '0'
    );
    port (
        clk     : in std_logic;
        val_in  : in std_logic;
        val_out : out std_logic := INIT_OUT
    );
end entity debounce;

architecture rtl of debounce is

    signal in_reg1 : std_logic;
    signal in_reg2 : std_logic;

    constant UREFCLK_FREQ : unsigned(31 downto 0) := to_unsigned(REFCLK_FREQ, 32);
    constant UDEBOUNCE_PERIOD_MS : unsigned(31 downto 0) := to_unsigned(DEBOUNCE_PERIOD_MS, 32);
    constant U1000 : unsigned(31 downto 0) := to_unsigned(1000, 32);

    constant UDIV_FREQ : unsigned(31 downto 0) := UREFCLK_FREQ / U1000;
    constant DB_COUNT_THRES64 : unsigned(63 downto 0) := UDEBOUNCE_PERIOD_MS * UDIV_FREQ;
    constant DB_COUNT_THRES : unsigned(31 downto 0) := DB_COUNT_THRES64(31 downto 0);

--    constant DB_COUNT_THRES : unsigned(31 downto 0) := DEBOUNCE_PERIOD_MS * (REFCLK_FREQ / 1000);
    signal count            : unsigned(31 downto 0) := DB_COUNT_THRES;
    signal in_prev          : std_logic;

begin

    process (clk)
    begin
        if rising_edge(clk) then

            -- 2 FF synchroniser
            in_reg1 <= val_in;
            in_reg2 <= in_reg1;

            in_prev <= in_reg2;
            -- if val_in changed, reset the counter
            if in_prev = not in_reg2 then
                count <= DB_COUNT_THRES;
            else
                if count = 0 then
                    val_out <= in_prev;
                else
                    count <= count - 1;
                end if;
            end if;

        end if;
    end process;
end architecture;