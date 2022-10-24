library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.axi_pkg.all;
use work.wb_pkg.all;
use work.graphics_pkg.all;

entity pynq_top is
    generic (
        G_DVI : string := "hamsterworks" -- "hamsterworks"
    );
    port (
        DDR : inout t_ddr;

        -- Zynq Fixed IO
        FIXED_IO_mio      : inout std_logic_vector (53 downto 0);
        FIXED_IO_ddr_vrn  : inout std_logic;
        FIXED_IO_ddr_vrp  : inout std_logic;
        FIXED_IO_ps_srstb : inout std_logic;
        FIXED_IO_ps_clk   : inout std_logic;
        FIXED_IO_ps_porb  : inout std_logic;

        -- HDMI out
        hdmi_tx_clk_n : out std_logic;
        hdmi_tx_clk_p : out std_logic;
        hdmi_tx_d_n   : out std_logic_vector(2 downto 0);
        hdmi_tx_d_p   : out std_logic_vector(2 downto 0);
        -- LEDs, Buttons and Switches
        led    : out std_logic_vector(3 downto 0);
        led4_b : out std_logic;
        led4_g : out std_logic;
        led4_r : out std_logic;
        led5_b : out std_logic;
        led5_g : out std_logic;
        led5_r : out std_logic;
        btn    : in std_logic_vector(3 downto 0);
        sw     : in std_logic_vector(1 downto 0);

        -- UART (to Raspi connector)
        uart_tx_out : out std_logic; -- Pin 5 (W19)
        uart_rx_in  : in std_logic   -- Pin 3 (W18)

    );
end entity;

architecture rtl of pynq_top is
    -- run location: fpca/boards/pynq_z2/fpca
    constant G_MEM_INIT_FILE  : string := "../../../software/hex/main.hex"; -- from toolchain
    constant G_BOOT_INIT_FILE : string := "../../../software/hex/boot.hex"; -- from toolchain

    signal FCLK_CLK0_100 : std_logic;
    signal FCLK_RESET0_N : std_logic;

    signal reset  : std_logic;
    signal resetn : std_logic;

    signal IRQ_P2F_UART0  : std_logic;
    signal M_AXI_GP0_MOSI : t_axi_mosi;
    signal M_AXI_GP0_MISO : t_axi_miso;
    signal S_AXI_GP0_MOSI : t_axi_mosi;
    signal S_AXI_GP0_MISO : t_axi_miso;
    signal S_AXI_HP0_MOSI : t_axi_mosi;
    signal S_AXI_HP0_MISO : t_axi_miso;
    signal S_AXI_HP1_MOSI : t_axi_mosi;
    signal S_AXI_HP1_MISO : t_axi_miso;

    signal pixelclk : std_logic;
    signal dma_clk  : std_logic;
    signal dvi_clk  : std_logic;
    signal dvi_clkn : std_logic;

    signal red_pixel   : std_logic_vector(7 downto 0);
    signal green_pixel : std_logic_vector(7 downto 0);
    signal blue_pixel  : std_logic_vector(7 downto 0);
    signal hsync       : std_logic;
    signal vsync       : std_logic;
    signal blank       : std_logic;

    signal locked : std_logic;

    signal TMDS_allp : std_logic_vector(3 downto 0);
    signal TMDS_alln : std_logic_vector(3 downto 0);

    signal text_display_wb_mosi        : t_wb_mosi;
    signal text_display_wb_miso        : t_wb_miso;
    signal ext_mem_wb_mosi             : t_wb_mosi;
    signal ext_mem_wb_miso             : t_wb_miso;
    signal zynq_ps_peripherals_wb_mosi : t_wb_mosi;
    signal zynq_ps_peripherals_wb_miso : t_wb_miso;

    signal gpio_led : std_logic_vector(31 downto 0);

    signal bitmap_pixel : t_pixel := (red => x"00", green => x"00", blue => x"00");
    signal txt_pixel    : t_pixel := (red => x"00", green => x"00", blue => x"00");
    signal comb_pixel   : t_pixel := (red => x"00", green => x"00", blue => x"00"); -- combined pixel

    -- VDMA control and status
    signal buffer0_start                 : std_logic_vector(31 downto 0) := x"1000_0000";
    signal buffer1_start                 : std_logic_vector(31 downto 0) := x"1020_0000";
    signal buffer_sel_dma_clk            : std_logic                     := '0';
    signal start_of_frame_dma_clk        : std_logic;
    signal pixel_underflow_count_dma_clk : std_logic_vector(31 downto 0);

    component clk_wiz_0
        port (
            clk_out1       : out std_logic;
            pixelclk_out   : out std_logic;
            axi_hp_clk_out : out std_logic;
            dvi_clk_out    : out std_logic;
            dvi_clkn_out   : out std_logic;
            locked         : out std_logic;

            reset     : in std_logic;
            clk_in100 : in std_logic
        );
    end component;

    attribute mark_debug                                  : boolean;
    attribute mark_debug of locked                        : signal is true;
    attribute mark_debug of reset                         : signal is true;
    attribute mark_debug of pixel_underflow_count_dma_clk : signal is true;
    attribute mark_debug of buffer_sel_dma_clk            : signal is true;

begin

    led4_b <= sw(0);
    led4_g <= locked;
    led5_g <= sw(1);

    reset  <= (not locked) or btn(3) or (not FCLK_RESET0_N);
    resetn <= not reset;

    pll : clk_wiz_0
    port map(
        clk_out1       => open,     -- 100MHz
        pixelclk_out   => pixelclk, -- 25MHz
        axi_hp_clk_out => dma_clk,  -- 200MHz
        dvi_clk_out    => dvi_clk,  -- 125MHz
        dvi_clkn_out   => dvi_clkn, -- 125MHz, 180deg phase shift
        locked         => locked,
        reset          => '0',
        clk_in100      => FCLK_CLK0_100

    );
    gen_hamsterworks : if G_DVI = "hamsterworks" generate
        dvid_inst : entity work.dvid
            port map(
                dvi_clk      => dvi_clk,
                dvi_clkn     => dvi_clkn,
                vga_pixelclk => pixelclk,
                vga_red      => comb_pixel.red,
                vga_green    => comb_pixel.green,
                vga_blue     => comb_pixel.blue,
                vga_blank    => blank,
                vga_hsync    => hsync,
                vga_vsync    => vsync,
                tmds         => hdmi_tx_d_p,
                tmdsn        => hdmi_tx_d_n,
                tmds_clk     => hdmi_tx_clk_p,
                tmds_clkn    => hdmi_tx_clk_n
            );
    end generate;

    -- wb_display_text_controller_inst : entity work.wb_display_text_controller
    --     port map(
    --         pixelclk                 => pixelclk,
    --         areset_n                 => locked,
    --         vga_hs                   => hsync,
    --         vga_vs                   => vsync,
    --         vga_blank                => blank,
    --         vga_r                    => red_pixel(7 downto 4),
    --         vga_g                    => green_pixel(7 downto 4),
    --         vga_b                    => blue_pixel(7 downto 4),
    --         text_display_wb_mosi_in  => text_display_wb_mosi,
    --         text_display_wb_miso_out => text_display_wb_miso
    --     );

    axi3_vdma_inst : entity work.axi3_vdma
        generic map(
            G_PIXEL_FIFO_DEPTH => 512,
            G_ILA              => true
        )
        port map(
            dma_clk_in                        => dma_clk,
            pixelclk_in                       => pixelclk,
            pixelclk_reset_in                 => reset,
            dma_reset_in                      => reset,
            dma_axi_hp_mosi_out               => S_AXI_HP0_MOSI,
            dma_axi_hp_miso_in                => S_AXI_HP0_MISO,
            vga_pixel_out                     => bitmap_pixel,
            vga_hsync_out                     => hsync,
            vga_vsync_out                     => vsync,
            vga_blank_out                     => blank,
            buffer0_start_in                  => buffer0_start,
            buffer1_start_in                  => buffer1_start,
            pixel_underflow_count_dma_clk_out => pixel_underflow_count_dma_clk,
            start_of_frame_dma_clk_out        => start_of_frame_dma_clk,
            buffer_sel_dma_clk_in             => buffer_sel_dma_clk
        );

    -- remove to prevent flickering until we are writing to the framebuffer
    --    buffer_flip : process(dma_clk) is
    --    begin
    --        if rising_edge(dma_clk) then
    --            if start_of_frame_dma_clk = '1' then
    --                buffer_sel_dma_clk <= not buffer_sel_dma_clk;
    --            end if;
    --        end if;
    --    end process;

    comb_pixel <= func_combine_pixel_or(bitmap_pixel, txt_pixel);

    ps_block_custom_wrapper_inst : entity work.ps_block_custom_wrapper
        generic map(G_S_AXI_GP0_DEBUG => false)
        port map(
            M_AXI_GP0_ACLK_IN => pixelclk,
            S_AXI_GP0_ACLK_IN => pixelclk,
            S_AXI_HP0_ACLK_IN => dma_clk,
            S_AXI_HP1_ACLK_IN => pixelclk,
            DDR               => DDR,
            FCLK_CLK0_100     => FCLK_CLK0_100,
            FCLK_RESET0_N     => FCLK_RESET0_N, -- reset out
            FIXED_IO_ddr_vrn  => FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp  => FIXED_IO_ddr_vrp,
            FIXED_IO_mio      => FIXED_IO_mio,
            FIXED_IO_ps_clk   => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb  => FIXED_IO_ps_porb,
            FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
            IRQ_P2F_UART0     => IRQ_P2F_UART0,
            M_AXI_GP0_MOSI    => M_AXI_GP0_MOSI,
            M_AXI_GP0_MISO    => M_AXI_GP0_MISO,
            S_AXI_GP0_MOSI    => S_AXI_GP0_MOSI,
            S_AXI_GP0_MISO    => S_AXI_GP0_MISO,
            S_AXI_HP0_MOSI    => S_AXI_HP0_MOSI,
            S_AXI_HP0_MISO    => S_AXI_HP0_MISO,
            S_AXI_HP1_MOSI    => S_AXI_HP1_MOSI,
            S_AXI_HP1_MISO    => S_AXI_HP1_MISO
        );

    led <= gpio_led(3 downto 0);

    -- connect the FPCA SoC to the Zynq PS peripheral registers
    wb_to_axi3_shim_inst : entity work.wb_to_axi3_shim
        port map(
            wb_clk       => pixelclk,
            wb_reset     => reset,
            wb_mosi_in   => zynq_ps_peripherals_wb_mosi,
            wb_miso_out  => zynq_ps_peripherals_wb_miso,
            axi_mosi_out => S_AXI_GP0_MOSI,
            axi_miso_in  => S_AXI_GP0_MISO
        );

    -- connect the FPCA SoC to the Zynq DDR3. This could use a cache at some point
    wb_to_axi3_shim_inst2 : entity work.wb_to_axi3_shim
        port map(
            wb_clk       => pixelclk,
            wb_reset     => reset,
            wb_mosi_in   => ext_mem_wb_mosi,
            wb_miso_out  => ext_mem_wb_miso,
            axi_mosi_out => S_AXI_HP1_MOSI,
            axi_miso_in  => S_AXI_HP1_MISO
        );

    -- FPCA RISC-V SoC and peripherals
    simple_soc_inst : entity work.simple_soc
        generic map(
            G_MEM_INIT_FILE      => G_MEM_INIT_FILE,
            G_BOOT_INIT_FILE     => G_BOOT_INIT_FILE,
            G_SOC_FREQ           => 25_000_000,
            G_DEFAULT_BAUD       => 9600,
            G_INCLUDE_JTAG_DEBUG => false -- connect AXI JTAG to the wishbone bus
        )
        port map(
            clk          => pixelclk,
            reset        => reset,
            gpio_led_out => gpio_led,
            gpio_btn_in  => x"0000_000" & btn(3 downto 0),
            gpio_sw_in   => x"0000_000" & b"00" & sw(1 downto 0),
            -- sseg_ca_out              => sseg_ca_out,
            -- sseg_an_out              => sseg_an_out,
            uart_tx_out                     => uart_tx_out,
            uart_rx_in                      => uart_rx_in,
            i2c_scl_out                     => open,
            i2c_sda_out                     => open,
            text_display_wb_mosi_out        => text_display_wb_mosi,
            text_display_wb_miso_in         => text_display_wb_miso,
            ext_mem_wb_mosi_out             => ext_mem_wb_mosi,
            ext_mem_wb_miso_in              => ext_mem_wb_miso,
            zynq_ps_peripherals_wb_mosi_out => zynq_ps_peripherals_wb_mosi,
            zynq_ps_peripherals_wb_miso_in  => zynq_ps_peripherals_wb_miso
        );
end architecture;