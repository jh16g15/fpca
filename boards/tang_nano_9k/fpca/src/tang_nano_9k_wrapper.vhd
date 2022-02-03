library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tang_nano_9k_wrapper is
    port (
        XTAL_IN : in std_logic; -- 27MHz

        LEDn : out std_logic_vector(5 downto 0); -- active low

        Reset_Button : in std_logic;
        User_Button : in std_logic;

        UART_TX : out std_logic;
        UART_RX : in std_logic

    );
    end entity tang_nano_9k_wrapper;

    architecture rtl of tang_nano_9k_wrapper is
        signal counter : unsigned(31 downto 0) := (others => '0');
        signal led : std_logic_vector(5 downto 0):= (others => '0');
    begin

        LEDn <= not led;


        -- test LEDs with Counting
        process (XTAL_IN) is
        begin
            if rising_edge(XTAL_IN) then
                counter <= counter + to_unsigned(1, 32);
                if counter > x"0200_0000" then
                    counter <= (others => '0');
                    led <= std_logic_vector( unsigned(led) + to_unsigned(1, 6));
                end if;
            end if;
        end process;


    end architecture;