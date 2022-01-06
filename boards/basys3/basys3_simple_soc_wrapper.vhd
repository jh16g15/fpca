

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity basys3_simple_soc_wrapper is
    port (
        clk : in std_logic; --! 100MHz

        btnC : in std_logic;
        btnU : in std_logic;
        btnL : in std_logic;
        btnR : in std_logic;
        btnD : in std_logic;

        sw  : in std_logic_vector(15 downto 0);
        led : out std_logic_vector(15 downto 0);

        seg : out std_logic_vector(6 downto 0);
        dp  : out std_logic;
        an  : out std_logic_vector(3 downto 0);
        
        RsTx : out std_logic;
        RsRx : in std_logic;
        -- mirrored UART_TX for a logic analyser
        JB : out std_logic_vector(0 downto 0) 

    );
end entity basys3_simple_soc_wrapper;

architecture rtl of basys3_simple_soc_wrapper is

    -- run location: fpca/boards/basys3/fpca
    constant G_MEM_INIT_FILE : string := "../../../software/build/blinky.hex"; -- from toolchain
    signal gpio_led          : std_logic_vector(31 downto 0);
    signal gpio_sw           : std_logic_vector(31 downto 0);
    signal gpio_btn          : std_logic_vector(31 downto 0);

    signal ext_reset : std_logic;
    signal reset : std_logic;

    signal clk50      : std_logic;
    signal pll_locked : std_logic;
    signal sseg_ca    : std_logic_vector(7 downto 0);
    signal sseg_an    : std_logic_vector(3 downto 0);

    signal uart_tx : std_logic;
    signal uart_rx : std_logic;

    component clk_wiz_0 is
        port (
            clk_out50 : out std_logic;
            reset     : in std_logic;
            locked    : out std_logic;
            clk_in1   : in std_logic
        );
    end component;

begin

    -- 100MHz to 50MHz
    pll_inst : clk_wiz_0
    port map(
        clk_out50 => clk50,
        reset     => ext_reset,
        locked    => pll_locked,
        clk_in1   => clk
    );

    ext_reset <= btnC;
    reset <= ext_reset or (not pll_locked);
    
    led   <= gpio_led(15 downto 0);

    gpio_btn(31 downto 4) <= (others => '0');
    gpio_btn(3 downto 0)  <= (btnU, btnL, btnR, btnD);

    gpio_sw(31 downto 16) <= (others => '0');
    gpio_sw(15 downto 0)  <= sw;

    seg <= sseg_ca(6 downto 0);
    dp  <= sseg_ca(7);

    an <= sseg_an;

    simple_soc_inst : entity work.simple_soc
        generic map(
            G_MEM_INIT_FILE => G_MEM_INIT_FILE,
            G_SOC_FREQ      => 50_000_000
        )
        port map(
            clk          => clk50,
            reset        => reset,
            gpio_led_out => gpio_led,
            gpio_btn_in  => gpio_btn,
            gpio_sw_in   => gpio_sw,
            sseg_ca_out  => sseg_ca,
            sseg_an_out  => sseg_an,
            uart_tx_out  => RsTx,
            uart_rx_in   => RsRx
            
        );
        -- UART TX OUT
        RsTx <= uart_tx;
        JB(0) <= uart_tx;
        -- UART RX IN
        uart_rx <= RsRx;

end architecture;