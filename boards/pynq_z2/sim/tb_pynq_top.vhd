-- Used in the Vivado Simulator

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi_pkg.all;
use work.wb_pkg.all;
use work.graphics_pkg.all;

entity pynq_top_tb is
end;

architecture bench of pynq_top_tb is
    
    signal tb_clk  : std_logic;
    signal tb_rstn : std_logic;

    -- Clock period
    -- 50 MHz PS input clock
    constant clk_period : time := 20 ns;
    -- Generics
    constant G_DVI : string := "hamsterworks";

    -- Ports
    signal DDR               : t_ddr;
    signal FIXED_IO_mio      : std_logic_vector (53 downto 0);
    signal FIXED_IO_ddr_vrn  : std_logic;
    signal FIXED_IO_ddr_vrp  : std_logic;
    signal FIXED_IO_ps_srstb : std_logic := '1';
    signal FIXED_IO_ps_clk   : std_logic := '0';
    signal FIXED_IO_ps_porb  : std_logic := '1';
    signal hdmi_tx_clk_n     : std_logic;
    signal hdmi_tx_clk_p     : std_logic;
    signal hdmi_tx_d_n       : std_logic_vector(2 downto 0);
    signal hdmi_tx_d_p       : std_logic_vector(2 downto 0);
    signal led               : std_logic_vector(3 downto 0);
    signal led4_b            : std_logic;
    signal led4_g            : std_logic;
    signal led4_r            : std_logic;
    signal led5_b            : std_logic;
    signal led5_g            : std_logic;
    signal led5_r            : std_logic;
    signal btn               : std_logic_vector(3 downto 0);
    signal sw                : std_logic_vector(1 downto 0);
    signal uart_tx_out       : std_logic;
    signal uart_rx_in        : std_logic;

begin

    pynq_top_inst : entity work.pynq_top
        generic map(
            G_DVI => G_DVI
        )
        port map(
            DDR               => DDR,
            FIXED_IO_mio      => FIXED_IO_mio,
            FIXED_IO_ddr_vrn  => FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp  => FIXED_IO_ddr_vrp,
            FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
            FIXED_IO_ps_clk   => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb  => FIXED_IO_ps_porb,
            hdmi_tx_clk_n     => hdmi_tx_clk_n,
            hdmi_tx_clk_p     => hdmi_tx_clk_p,
            hdmi_tx_d_n       => hdmi_tx_d_n,
            hdmi_tx_d_p       => hdmi_tx_d_p,
            led               => led,
            led4_b            => led4_b,
            led4_g            => led4_g,
            led4_r            => led4_r,
            led5_b            => led5_b,
            led5_g            => led5_g,
            led5_r            => led5_r,
            btn               => btn,
            sw                => sw,
            uart_tx_out       => uart_tx_out,
            uart_rx_in        => uart_rx_in
        );

    reset_process : process
    begin   
        btn <= b"0000";
        sw <= b"00";
        uart_rx_in <= '0';
        tb_rstn <= '0';
        wait for 20*clk_period;
        tb_rstn <= '1';
        wait;
    end process;
    
    FIXED_IO_ps_clk <= tb_clk;
    FIXED_IO_ps_porb <= tb_rstn;
    FIXED_IO_ps_srstb <= tb_rstn; 
    
    clk_process : process
    begin
        tb_clk <= '1';
        wait for clk_period/2;
        tb_clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;