library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tang_nano_9k_wrapper is
    port (
        XTAL_IN : in std_logic; -- 27MHz

        LEDn : out std_logic_vector(5 downto 0); -- active low

        -- active low?
        Reset_Button : in std_logic;
        User_Button : in std_logic;

        UART_TX : out std_logic;
        UART_RX : in std_logic;

        LCD_DEN  : out std_logic; -- Data Enable (optional?)
        LCD_SYNC : out std_logic; -- VSYNC
        LCD_HYNC : out std_logic; -- HSYNC
        LCD_CLK  : out std_logic; -- 9 MHZ out

        LCD_B : out std_logic_vector(4 downto 0);
        LCD_G : out std_logic_vector(5 downto 0);
        LCD_R : out std_logic_vector(4 downto 0)

    );
end entity tang_nano_9k_wrapper;

architecture rtl of tang_nano_9k_wrapper is
    signal counter : unsigned(31 downto 0)        := (others => '0');
    signal led     : std_logic_vector(5 downto 0) := (others => '0');

    signal pixelclk : std_logic;

    signal reset   : std_logic;
    signal reset_n : std_logic;

    signal vga_hs : std_logic;
    signal vga_vs : std_logic;
    signal vga_red : std_logic_vector(3 downto 0);
    signal vga_green : std_logic_vector(3 downto 0);
    signal vga_blue : std_logic_vector(3 downto 0);

    component Gowin_rPLL
        port (
            clkout : out std_logic;
            lock   : out std_logic;
            clkin  : in std_logic
        );
    end component;
begin

    reset   <= Reset_Button;
    reset_n <= not reset;

--    reset   <= not reset_n;
--    reset_n <= Reset_Button;

    LEDn <= not led;

    UART_TX <= '1';

    your_instance_name : Gowin_rPLL
    port map(
        clkout => pixelclk, -- 9 MHz
        lock   => open,
        clkin  => XTAL_IN -- 27 MHz
    );
    -- test LEDs with Counting
    process (XTAL_IN) is
    begin
        if rising_edge(XTAL_IN) then
            counter <= counter + to_unsigned(1, 32);
            if counter > x"0200_0000" then
                counter <= (others => '0');
                led     <= std_logic_vector(unsigned(led) + to_unsigned(1, 6));
            end if;
        end if;
    end process;

        LCD_DEN  <= '0';
        LCD_SYNC  <= vga_vs;
        LCD_HYNC  <= vga_hs;
        LCD_CLK   <= pixelclk;

        LCD_R  <= vga_red & '0';
        LCD_G  <= vga_green & "00";
        LCD_B  <= vga_blue & '0';

    display_text_controller_inst : entity work.display_text_controller
        port map(
            pixelclk => pixelclk,
            areset_n => reset_n,
            vga_hs   => vga_hs,
            vga_vs   => vga_vs,
            -- 12-bit VGA
            vga_r => vga_red,
            vga_g => vga_green,
            vga_b => vga_blue
        );

end architecture;