library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.axi_pkg.all;

entity pynq_top is
    generic (
        G_DVI : string := "hamsterworks" -- "hamsterworks"
    );
    port (
        -- clk   : in std_logic;
        -- reset : in std_logic;

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
        sw     : in std_logic_vector(1 downto 0)
    );
end entity;

architecture rtl of pynq_top is

    signal FCLK_CLK0_100 : std_logic;
    signal FCLK_RESET0_N : std_logic;
    signal resetn        : std_logic;

    signal IRQ_P2F_UART0  : std_logic;
    signal M_AXI_GP0_MOSI : t_axi_mosi;
    signal M_AXI_GP0_MISO : t_axi_miso;
    signal S_AXI_GP0_MOSI : t_axi_mosi;
    signal S_AXI_GP0_MISO : t_axi_miso;
    signal S_AXI_HP0_MOSI : t_axi_mosi;
    signal S_AXI_HP0_MISO : t_axi_miso;

    signal pixelclk : std_logic;
    signal tmdsclk  : std_logic;
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

    component clk_wiz_0
        port (
            clk_out1            : out std_logic;
            pixelclk_out        : out std_logic;
            hdmi_serdes_clk_out : out std_logic;
            dvi_clk_out         : out std_logic;
            dvi_clkn_out        : out std_logic;
            locked              : out std_logic;

            reset     : in std_logic;
            clk_in100 : in std_logic
        );
    end component;

begin

    led4_b <= sw(0);
    led4_g <= locked;
    led5_g <= sw(1);

    led <= btn;

    resetn <= FCLK_RESET0_N;

    pll : clk_wiz_0
    port map(
        clk_out1            => open,     -- 100MHz
        pixelclk_out        => pixelclk, -- 25MHz
        hdmi_serdes_clk_out => tmdsclk,  -- 250MHz
        dvi_clk_out         => dvi_clk,  -- 125MHz
        dvi_clkn_out        => dvi_clkn, -- 125MHz, 180deg phase shift
        locked              => locked,
        reset               => '0',
        clk_in100           => FCLK_CLK0_100

    );
    gen_hamsterworks : if G_DVI = "hamsterworks" generate
        dvid_inst : entity work.dvid
            port map(
                dvi_clk      => dvi_clk,
                dvi_clkn     => dvi_clkn,
                vga_pixelclk => pixelclk,
                vga_red      => red_pixel,
                vga_green    => green_pixel,
                vga_blue     => blue_pixel,
                vga_blank    => blank,
                vga_hsync    => hsync,
                vga_vsync    => vsync,
                tmds         => hdmi_tx_d_p,
                tmdsn        => hdmi_tx_d_n,
                tmds_clk     => hdmi_tx_clk_p,
                tmds_clkn    => hdmi_tx_clk_n
            );
    end generate;

    display_text_controller_inst : entity work.display_text_controller
        port map(
            pixelclk  => pixelclk,
            areset_n  => locked,
            vga_hs    => hsync,
            vga_vs    => vsync,
            vga_blank => blank,
            vga_r     => red_pixel(7 downto 4),
            vga_g     => green_pixel(7 downto 4),
            vga_b     => blue_pixel(7 downto 4)
        );

    ps_block_custom_wrapper_inst : entity work.ps_block_custom_wrapper
        port map(
            AXI_CLK_IN        => FCLK_CLK0_100, -- feed back in to drive AXI interfaces
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
            S_AXI_HP0_MISO    => S_AXI_HP0_MISO
        );

end architecture;