

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.graphics_pkg.all;

entity basys3_display_test_top is
    generic
    (
        G_PROJECT_ROOT : string := "C:/Users/joehi/Documents/fpga/fpca/"
    );
    port
    (
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

        -- builtin USB-UART
        RsTx : out std_logic;
        RsRx : in std_logic;

        -- UART to ESP8266
        AUX_UART_TX : out std_logic;
        AUX_UART_RX : in std_logic;
    
        -- I2C SCL (0) / SDA (1)
        JC : out std_logic_vector(1 downto 0);

        -- SD Card (Native interface) -- SPI Interface
        SD_CLK : out std_logic; -- SCLK
        SD_CMD : inout std_logic; -- DI (pullup=true)
        SD_D0  : inout std_logic; -- DO
        SD_D1  : inout std_logic;
        SD_D2  : inout std_logic;
        SD_D3  : inout std_logic; -- CS

        -- PMOD B QSPI interface for APS6404 PSRAM
        PSRAM_QSPI_CSN : out std_logic;
        PSRAM_QSPI_SCK : out std_logic;
        PSRAM_QSPI_SIO : inout std_logic_vector(3 downto 0);

        PSRAM_SEL : out std_logic_vector(1 downto 0) := b"00";
        

        -- VGA Display
        vgaRed   : out std_logic_vector(3 downto 0);
        vgaGreen : out std_logic_vector(3 downto 0);
        vgaBlue  : out std_logic_vector(3 downto 0);
        vgaHsync    : out std_logic;
        vgaVsync    : out std_logic
    );
end entity basys3_display_test_top;

architecture rtl of basys3_display_test_top is
    constant TARGET_LATENCY : natural range 1 to 20 := 5;
    constant END_ACTIVE_X : natural := 1024;
	constant FRONT_PORCH_X : natural := 48;
	constant SYNC_PULSE_X : natural := 80;
	constant BACK_PORCH_X : natural := 32;
	constant END_ACTIVE_Y : natural := 600;
	constant FRONT_PORCH_Y : natural := 3;
	constant SYNC_PULSE_Y : natural := 10;
	constant BACK_PORCH_Y : natural := 5;
	constant ACTIVE_HS : std_logic := '1';
	constant ACTIVE_VS : std_logic := '1';

    -- run location: fpca/boards/basys3/fpca
    constant G_MEM_INIT_FILE  : string := "software/hex/main.hex"; -- from project root
    constant G_BOOT_INIT_FILE : string := "software/hex/boot.hex"; -- from project root
    signal gpio_led           : std_logic_vector(31 downto 0);
    signal gpio_sw            : std_logic_vector(31 downto 0);
    signal gpio_btn           : std_logic_vector(31 downto 0);

    signal btn_raw       : std_logic_vector(4 downto 0);
    signal btn_debounced : std_logic_vector(4 downto 0);

    signal ext_reset : std_logic;
    signal reset     : std_logic;

    signal pixelclk      : std_logic;
    signal clk200     : std_logic;
    signal mem_ctrl_clk : std_logic;
    signal pll_locked : std_logic;
    signal sseg_ca    : std_logic_vector(7 downto 0);
    signal sseg_an    : std_logic_vector(3 downto 0);

    signal uart_tx : std_logic;
    signal uart_rx : std_logic;
    
    signal i2c_scl : std_logic;
    signal i2c_sda : std_logic;

    signal i_spi_sck  : std_logic;
    signal i_spi_miso : std_logic;
    signal i_spi_mosi : std_logic;
    signal i_spi_csn  : std_logic;

    signal blank : std_logic;
    signal pixel : t_pixel;
    signal hsync : std_logic;
    signal vsync : std_logic;
    
--    constant C_MEM_CTRL_CLK_FREQ_KHZ : integer := 65_000;   -- max for SPI_READ command (no wait states)
    constant C_MEM_CTRL_CLK_FREQ_KHZ : integer := 50_000;
    component clk_wiz_1 is
        port
        (
            clk_out1 : out std_logic;
            reset     : in std_logic;
            locked    : out std_logic;
            clk_in1   : in std_logic
        );
    end component;
    
    component vio_0 is
        port
        (
            clk : in std_logic;
            probe_out0 : out std_logic_vector(7 downto 0);
            probe_out1 : out std_logic_vector(7 downto 0);
            probe_out2 : out std_logic_vector(7 downto 0)
        );
    end component;
    

begin


--    qspi_oversample_inst : entity work.qspi_oversample
--    generic map (
--        OVERSAMPLE_KHZ => 200_000,
--        SPI_KHZ => 20_000
--    )
--    port map (
--        oversample_clk => clk200,
--        oversample_rst => reset,
--        init_done_out => open,
--        qspi_clk_out => PSRAM_QSPI_SCK,
--        qspi_csn => PSRAM_QSPI_CSN,
--        qspi_sio => PSRAM_QSPI_SIO
--    );

    -- 100MHz to 44MHz free running
    pll_inst : clk_wiz_1
    port map (
        clk_out1 => pixelclk,
        reset     => '0',
        locked    => pll_locked,
        clk_in1   => clk
    );

    ext_reset <= btn_debounced(4); -- Centre
    reset     <= ext_reset or (not pll_locked);

    led <= gpio_led(15 downto 0);

    gpio_btn(31 downto 4) <= (others => '0');

    btn_raw <= (btnC, btnU, btnL, btnR, btnD);

    debounce_btn_inst : entity work.debounce
        generic map (
            REFCLK_FREQ => 44_000_000,
            WIDTH       => 5
        ) port map (
            clk     => pixelclk,
            val_in  => btn_raw,
            val_out => btn_debounced
        );
    gpio_btn(3 downto 0)  <= btn_debounced(3 downto 0);
    gpio_sw(31 downto 16) <= (others => '0');
    -- gpio_sw(15 downto 0)  <= sw;
    debounce_sw_inst : entity work.debounce
        generic map (
            REFCLK_FREQ => 44_000_000,
            WIDTH       => 16
        ) port map (
            clk     => pixelclk,
            val_in  => sw,
            val_out => gpio_sw(15 downto 0)
        );

    -- 7 Seg Display
    seg <= sseg_ca(6 downto 0);
    dp  <= sseg_ca(7);
    an  <= sseg_an;

    -- UART TX OUT
    RsTx <= uart_tx;

    -- UART RX IN
    uart_rx <= RsRx;

    -- I2C
    JC(0) <= i2c_scl;
    JC(1) <= i2c_sda;

    -- SD Card
    SD_CLK <= i_spi_sck;
    SD_CMD <= i_spi_mosi;
    i_spi_miso <= SD_D0;
    SD_D3 <= i_spi_csn;
    
    -- counters for
    disp_counters : entity work.flex_vga_counters
        generic map(
            TARGET_LATENCY => TARGET_LATENCY,
            END_ACTIVE_X   => END_ACTIVE_X,
            FRONT_PORCH_X  => FRONT_PORCH_X,
            SYNC_PULSE_X   => SYNC_PULSE_X,
            BACK_PORCH_X   => BACK_PORCH_X,
            END_ACTIVE_Y   => END_ACTIVE_Y,
            FRONT_PORCH_Y  => FRONT_PORCH_Y,
            SYNC_PULSE_Y   => SYNC_PULSE_Y,
            BACK_PORCH_Y   => BACK_PORCH_Y,
            ACTIVE_HS      => ACTIVE_HS,
            ACTIVE_VS      => ACTIVE_VS
        )
        port map(
            pixelclk   => pixelclk,
            req_pixel  => open,
            load_line  => open,
            load_frame => open,
            VGA_HSYNC  => hsync,
            VGA_VSYNC  => vsync,
            VGA_BLANK  => blank
        );
    
    vga_trim : entity work.flex_vga_colour_trim
        generic map(
            COL_DEPTH  => COLOUR_BITS_12_BPP,
            REG_OUTPUT => true
        )
        port map(
            pixelclk  => pixelclk,
            pixel     => pixel,
            hsync     => hsync,
            vsync     => vsync,
            blank     => blank,
            vga_hsync => vgaHsync,
            vga_vsync => vgaVsync,
            vga_blank => open, -- only needed for some displays/HDMI
            vga_red   => vgaRed,
            vga_grn   => vgaGreen,
            vga_blu   => vgaBlue
        );
    
    pixel_vio : component vio_0
        port map(
            clk        => pixelclk,
            probe_out0 => pixel.red,
            probe_out1 => pixel.green,
            probe_out2 => pixel.blue
        );
    
end architecture;