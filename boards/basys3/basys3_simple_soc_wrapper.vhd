

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity basys3_simple_soc_wrapper is
    generic (
        G_PROJECT_ROOT : string := "D:/Documents/fpga/fpca/";
        G_SD_CARD_INSTEAD_OF_SPI_SRAM : boolean := true
    );
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
        
        -- I2C SCL (0) / SDA (1)
        JC : out std_logic_vector(1 downto 0);
        
        -- SD Card (Native interface) -- SPI Interface
        SD_CLK : out std_logic; -- SCLK
        SD_CMD : inout std_logic; -- DI (pullup=true)
        SD_D0 : inout std_logic; -- DO
        SD_D1 : inout std_logic; 
        SD_D2 : inout std_logic;
        SD_D3 : inout std_logic; -- CS
        
        -- PMOD B SPI interface
        SPI_CSN : out std_logic;
        SPI_MOSI : out std_logic;
        SPI_MISO : in std_logic;
        SPI_SCK : out std_logic;
        SPI_HOLDN : out std_logic;
        
        -- VGA Display
        vgaRed : out std_logic_vector(3 downto 0);
        vgaGreen : out std_logic_vector(3 downto 0);
        vgaBlue : out std_logic_vector(3 downto 0);
        Hsync : out std_logic;
        Vsync : out std_logic
        

    );
end entity basys3_simple_soc_wrapper;

architecture rtl of basys3_simple_soc_wrapper is

    -- run location: fpca/boards/basys3/fpca
    constant G_MEM_INIT_FILE : string := "software/hex/main.hex"; -- from project root
    constant G_BOOT_INIT_FILE : string := "software/hex/boot.hex"; -- from project root
    signal gpio_led          : std_logic_vector(31 downto 0);
    signal gpio_sw           : std_logic_vector(31 downto 0);
    signal gpio_btn          : std_logic_vector(31 downto 0);

    signal btn_raw : std_logic_vector( 4 downto 0);
    signal btn_debounced : std_logic_vector( 4 downto 0);

    signal ext_reset : std_logic;
    signal reset : std_logic;

    signal clk25      : std_logic;
    signal pll_locked : std_logic;
    signal sseg_ca    : std_logic_vector(7 downto 0);
    signal sseg_an    : std_logic_vector(3 downto 0);

    signal uart_tx : std_logic;
    signal uart_rx : std_logic;
    
    signal i2c_scl : std_logic;
    signal i2c_sda : std_logic;
    
    signal i_spi_sck : std_logic;
    signal i_spi_miso : std_logic;
    signal i_spi_mosi : std_logic;
    signal i_spi_csn : std_logic;

    component clk_wiz_0 is
        port (
            clk_out25 : out std_logic;
            reset     : in std_logic;
            locked    : out std_logic;
            clk_in1   : in std_logic
        );
    end component;

begin

    -- 100MHz to 25MHz free running
    pll_inst : clk_wiz_0
    port map(
        clk_out25 => clk25,
        reset     => '0',
        locked    => pll_locked,
        clk_in1   => clk
    );

    ext_reset <= btn_debounced(4);  -- Centre
    reset <= ext_reset or (not pll_locked);

    led   <= gpio_led(15 downto 0);

    gpio_btn(31 downto 4) <= (others => '0');

    btn_raw <= (btnC, btnU, btnL, btnR, btnD);

    debounce_btn_inst : entity work.debounce
        generic map (
          REFCLK_FREQ => 25_000_000,
          WIDTH => 5
        )
        port map (
          clk => clk25,
          val_in => btn_raw,
          val_out => btn_debounced
        );
    gpio_btn(3 downto 0)  <= btn_debounced(3 downto 0);


    gpio_sw(31 downto 16) <= (others => '0');
    -- gpio_sw(15 downto 0)  <= sw;
    debounce_sw_inst : entity work.debounce
        generic map (
          REFCLK_FREQ => 25_000_000,
          WIDTH => 16
        )
        port map (
          clk => clk25,
          val_in => sw,
          val_out => gpio_sw(15 downto 0)
        );
    -- 7 Seg Display
    seg <= sseg_ca(6 downto 0);
    dp  <= sseg_ca(7);
    an <= sseg_an;

    -- UART TX OUT
    RsTx <= uart_tx;

    -- UART RX IN
    uart_rx <= RsRx;
    
    -- I2C
    JC(0) <= i2c_scl;
    JC(1) <= i2c_sda;
    
    
    gen_spi_sel : if G_SD_CARD_INSTEAD_OF_SPI_SRAM = false generate
        -- SPI (23LC1024 SRAM)
        SPI_HOLDN <= '1';
        SPI_SCK <= i_spi_sck;
        SPI_CSN <= i_spi_csn;
        SPI_MOSI <= i_spi_mosi;
        i_spi_miso <= SPI_MISO;
    end generate;
    
    gen_sdcard_sel : if G_SD_CARD_INSTEAD_OF_SPI_SRAM = true generate
        -- SPI (PMOD-SD Card)
        SD_CLK <= i_spi_sck;
        SD_D3 <= i_spi_csn;
        SD_CMD <= i_spi_mosi; --(pullup=true)
        i_spi_miso <= SD_D0;
        -- unused for SD card in SPI mode
        SD_D1 <= '0';
        SD_D2 <= '0';
    end generate;

    
    soc_inst : entity work.basys3_soc
        generic map(
            G_PROJECT_ROOT => G_PROJECT_ROOT,
            G_MEM_INIT_FILE => G_MEM_INIT_FILE,
            G_BOOT_INIT_FILE => G_BOOT_INIT_FILE,
            G_SOC_FREQ      => 25_000_000
        )
        port map(
            clk          => clk25,
            reset        => reset,
            gpio_led_out => gpio_led,
            gpio_btn_in  => gpio_btn,
            gpio_sw_in   => gpio_sw,
            sseg_ca_out  => sseg_ca,
            sseg_an_out  => sseg_an,
            uart_tx_out  => uart_tx,
            uart_rx_in   => uart_rx,
            i2c_scl_out => i2c_scl,
            i2c_sda_out => i2c_sda,
            spi_sck_out => i_spi_sck,
            spi_miso_in => i_spi_miso,
            spi_mosi_out => i_spi_mosi,
            spi_csn_out => i_spi_csn,
            vga_hs_out => Hsync,
            vga_vs_out => Vsync,
            vga_r => vgaRed,
            vga_g => vgaGreen,
            vga_b => vgaBlue
        );


end architecture;