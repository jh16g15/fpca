--! quad_seven_seg_driver.vhd

-- TODO: 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity quad_seven_seg_driver is
    generic(
        G_REFCLK_FREQ : integer := 100_000_000
    );
    port (
        clk             : in std_logic;
        display_data_in : in std_logic_vector(15 downto 0);

        sseg_ca : out std_logic_vector(7 downto 0);        -- segment select
        sseg_an : out std_logic_vector(3 downto 0) := x"1" -- char select
    );
end entity quad_seven_seg_driver;

architecture rtl of quad_seven_seg_driver is
    signal char_data : std_logic_vector(3 downto 0);

    signal slowclk_en      : std_logic;
    signal clk_div_counter : unsigned(25 downto 0) := (others => '0');
    
    -- we want to cycle through all 4 digits 60 times a second
    -- so 240 times per second we want to pules slowclk_en
    -- which is a counter val of G_REFCLK_FREQ / 240
    constant clk_div_threshold : unsigned(25 downto 0) := to_unsigned(G_REFCLK_FREQ / 240, 26);

    -- new digit logic
    signal digit_counter : unsigned(1 downto 0);

begin

    clk_div : process (clk) is
    begin
        if rising_edge(clk) then
            clk_div_counter <= clk_div_counter + 1;
            slowclk_en <= '0';
            if clk_div_counter = clk_div_threshold then
                slowclk_en <= '1';  -- one cycle enable pulse
                clk_div_counter <= (others => '0');
            end if;
        end if;
    end process clk_div;

    -- active low char enables
    sseg_an(3) <= '0' when digit_counter = 3 else '1';
    sseg_an(2) <= '0' when digit_counter = 2 else '1';
    sseg_an(1) <= '0' when digit_counter = 1 else '1';
    sseg_an(0) <= '0' when digit_counter = 0 else '1';

    char_select : process (digit_counter, display_data_in) is
    begin
        case(to_integer(digit_counter)) is
            when 0      => char_data      <= std_logic_vector(display_data_in(3 downto 0));
            when 1      => char_data      <= std_logic_vector(display_data_in(7 downto 4));
            when 2      => char_data      <= std_logic_vector(display_data_in(11 downto 8));
            when 3      => char_data      <= std_logic_vector(display_data_in(15 downto 12));
            when others => char_data <= x"F";
            report("invalid digit_counter") severity error;

        end case;
    end process char_select;

    digit_count : process (clk) is
    begin
        if rising_edge(clk) then
            if slowclk_en = '1' then
                digit_counter <= digit_counter + 1;
            end if;
        end if;
    end process digit_count;

    -- character to segment decoder
    -- sseg_ca(0:6) are segments A to G
    -- sseg_ca(7) is the decimal point
    --  A
    -- F B
    --  G
    -- E C
    --  D  .
    char_decode : process (char_data) is
    begin              --    Active low:
        case(char_data) is --    ".GFEDCBA"   
            when x"0"   => sseg_ca(7 downto 0)   <= b"11000000";
            when x"1"   => sseg_ca(7 downto 0)   <= b"11111001";
            when x"2"   => sseg_ca(7 downto 0)   <= b"10100100";
            when x"3"   => sseg_ca(7 downto 0)   <= b"10110000";
            when x"4"   => sseg_ca(7 downto 0)   <= b"10011001";
            when x"5"   => sseg_ca(7 downto 0)   <= b"10010010";
            when x"6"   => sseg_ca(7 downto 0)   <= b"10000010";
            when x"7"   => sseg_ca(7 downto 0)   <= b"11111000";
            when x"8"   => sseg_ca(7 downto 0)   <= b"10000000";
            when x"9"   => sseg_ca(7 downto 0)   <= b"10010000";
            when x"A"   => sseg_ca(7 downto 0)   <= b"10001000";
            when x"B"   => sseg_ca(7 downto 0)   <= b"10000011";
            when x"C"   => sseg_ca(7 downto 0)   <= b"11000110";
            when x"D"   => sseg_ca(7 downto 0)   <= b"10100001";
            when x"E"   => sseg_ca(7 downto 0)   <= b"10000110";
            when x"F"   => sseg_ca(7 downto 0)   <= b"10001110";
            when others => sseg_ca(7 downto 0) <= b"01111111";
            report("invalid char_data") severity warning;
        end case;
    end process char_decode;
end architecture rtl;