library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tang_nano_9k_wrapper is
    port (
        XTAL_IN : in std_logic; -- 27MHz

        LEDn : out std_logic_vector(5 downto 0); -- active low

        -- active low
        Reset_Button_n : in std_logic;
        User_Button_n : in std_logic;

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

    signal x_count : integer;
    signal y_count : integer;

    signal red : std_logic_vector(4 downto 0);
    signal green : std_logic_vector(5 downto 0);
    signal blue : std_logic_vector(4 downto 0);
begin

    reset   <= not Reset_Button_n;
    reset_n <= not reset;


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

    LCD_CLK   <= pixelclk;

    process (all)
    begin
        -- defaults
        red <= (others => '0');
        green <= (others => '0');
        blue <= (others => '0');

        -- red <= "11111";
        -- green <= "100000";
        -- blue <= "10000";

        -- borders
        if x_count = 0 then
            red <= (others => '1');
        end if;
        if x_count = 480-1 then
            red <= (others => '1');
        end if;
        if y_count = 0 then
            green <= (others => '1');
        end if;
        if y_count = 272-1 then
            blue <= (others => '1');
        end if;
    end process;


    lcd_counters_inst : entity work.lcd_counters
    generic map (
        G_PIXEL_DATA_LATENCY => 0
    )
    port map (
      pixelclk => pixelclk,
      reset => reset,
      LCD_HSYNC => LCD_HYNC,
      LCD_VSYNC => LCD_SYNC,
      LCD_DATA_EN => LCD_DEN,
      x_count_out => x_count,
      y_count_out => y_count,
      red_in => red,
      green_in => green,
      blue_in => blue,
      LCD_R_out => LCD_R,
      LCD_G_out => LCD_G,
      LCD_B_out => LCD_B
    );


end architecture;