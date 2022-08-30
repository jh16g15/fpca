library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.axi_pkg.all;

entity pynq_top is
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
        
        -- LEDs, Buttons and Switches
        led : out std_logic_vector(3 downto 0);
        led4_b : out std_logic;
        led4_g : out std_logic;
        led4_r : out std_logic;
        led5_b : out std_logic;
        led5_g : out std_logic;
        led5_r : out std_logic;
        btn : in std_logic_vector(3 downto 0);
        sw : in std_logic_vector(1 downto 0)
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
begin

    led4_b <= sw(0);
    led5_g <= sw(1);
    
    led <= btn;

    resetn <= FCLK_RESET0_N;

    ps_block_custom_wrapper_inst : entity work.ps_block_custom_wrapper
        port map(
            AXI_CLK_IN        => FCLK_CLK0_100,
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