library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

-- fpca/hdl/sim
-- fpca/software/build/*.hex

entity simple_soc is
    generic (
        G_MEM_INIT_FILE : string  := "../../software/hex/main.hex";
        G_BOOT_INIT_FILE : string  := "../../software/hex/boot.hex";
        G_SOC_FREQ      : integer := 50_000_000;
        G_DEFAULT_BAUD  : integer := 9600
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;

        -- GPIO
        gpio_led_out : out std_logic_vector(31 downto 0);
        gpio_btn_in  : in std_logic_vector(31 downto 0);
        gpio_sw_in   : in std_logic_vector(31 downto 0);

        -- Quad Seven Seg
        sseg_ca_out : out std_logic_vector(7 downto 0);
        sseg_an_out : out std_logic_vector(3 downto 0);

        -- UART
        uart_tx_out : out std_logic;
        uart_rx_in  : in std_logic

    );
end entity simple_soc;

architecture rtl of simple_soc is
    constant G_PC_RESET_ADDR : unsigned(31 downto 0) := x"0000_0000";

    constant G_NUM_SLAVES : integer := 16; -- max 16

    -- for GPIO register bank
    constant G_NUM_RW_REGS : integer := 4;
    constant G_NUM_RO_REGS : integer := 2;

    signal if_wb_mosi         : t_wb_mosi;
    signal if_wb_miso         : t_wb_miso;
    signal mem_wb_mosi        : t_wb_mosi;
    signal mem_wb_miso        : t_wb_miso;
    signal wb_master_sel_mosi : t_wb_mosi;
    signal wb_master_sel_miso : t_wb_miso;

    signal wb_slave_mosi_arr : t_wb_mosi_arr(G_NUM_SLAVES - 1 downto 0);
    signal wb_slave_miso_arr : t_wb_miso_arr(G_NUM_SLAVES - 1 downto 0);

    signal rw_regs_out : t_slv32_arr(G_NUM_RW_REGS - 1 downto 0);
    signal ro_regs_in  : t_slv32_arr(G_NUM_RO_REGS - 1 downto 0);

    attribute mark_debug : boolean;
    attribute mark_debug of rw_regs_out : signal is true;
    attribute mark_debug of ro_regs_in  : signal is true;

    -- Seven Segment Display controller
    signal sseg_display_data : std_logic_vector(15 downto 0);

begin

    cpu_top_inst : entity work.cpu_top
        generic map(
            G_PC_RESET_ADDR => G_PC_RESET_ADDR
        )
        port map(
            clk             => clk,
            reset           => reset,
            extern_halt_in  => '0',
            if_wb_mosi_out  => if_wb_mosi,
            if_wb_miso_in   => if_wb_miso,
            mem_wb_mosi_out => mem_wb_mosi,
            mem_wb_miso_in  => mem_wb_miso
        );
    -- 2:1 arbiter
    wb_arbiter_inst : entity work.wb_arbiter
        port map(
            wb_clk                 => clk,
            wb_reset               => reset,
            wb_master_0_mosi_in    => if_wb_mosi,
            wb_master_0_miso_out   => if_wb_miso,
            wb_master_1_mosi_in    => mem_wb_mosi,
            wb_master_1_miso_out   => mem_wb_miso,
            wb_master_sel_mosi_out => wb_master_sel_mosi,
            wb_master_sel_miso_in  => wb_master_sel_miso
        );
    -- 1:N interconnect
    wb_interconnect_inst : entity work.wb_interconnect
        generic map(
            G_NUM_SLAVES => G_NUM_SLAVES
        )
        port map(
            wb_clk                => clk,
            wb_reset              => reset,
            wb_master_mosi_in     => wb_master_sel_mosi,
            wb_master_miso_out    => wb_master_sel_miso,
            wb_slave_mosi_arr_out => wb_slave_mosi_arr,
            wb_slave_miso_arr_in  => wb_slave_miso_arr
        );

    --! Main memory
    --! x0000_0000 to x0FFF_FFFF
    wb_sp_bram_inst : entity work.wb_sp_bram
        generic map(
            G_MEM_DEPTH_WORDS => 2048,
            G_INIT_FILE       => G_MEM_INIT_FILE
        )
        port map(
            wb_clk      => clk,
            wb_reset    => reset,
            wb_mosi_in  => wb_slave_mosi_arr(0),
            wb_miso_out => wb_slave_miso_arr(0)
        );

    --! GPIO Register Bank
    --! x1000_0000 to x1FFF_FFFF
    --! RW registers are 0x000, 0x004 up to 0x0FC
    --! RO registers are 0x100, 0x104 up to 0x1FC
    wb_gpio_regs_inst : entity work.wb_regs
        generic map(
            G_NUM_RW_REGS => G_NUM_RW_REGS,
            G_NUM_RO_REGS => G_NUM_RO_REGS
        )
        port map(
            wb_clk      => clk,
            wb_reset    => reset,
            wb_mosi_in  => wb_slave_mosi_arr(1),
            wb_miso_out => wb_slave_miso_arr(1),
            rw_regs_out => rw_regs_out,
            ro_regs_in  => ro_regs_in
        );
    -- Map GPIO registers to peripherals
    gpio_led_out      <= rw_regs_out(0);
    ro_regs_in(0)     <= gpio_btn_in;
    ro_regs_in(1)     <= gpio_sw_in;
    sseg_display_data <= rw_regs_out(1)(15 downto 0);

    wb_uart_simple_inst : entity work.wb_uart_simple
        generic map(
            DEFAULT_BAUD => G_DEFAULT_BAUD,
            REFCLK_FREQ  => G_SOC_FREQ
        )
        port map(
            wb_clk      => clk,
            wb_reset    => reset,
            wb_mosi_in  => wb_slave_mosi_arr(2),
            wb_miso_out => wb_slave_miso_arr(2),
            uart_tx_out => uart_tx_out,
            uart_rx_in  => uart_rx_in
        );
    quad_seven_seg_driver_inst : entity work.quad_seven_seg_driver
        generic map(
            G_REFCLK_FREQ => G_SOC_FREQ
        )
        port map(
            clk             => clk,
            display_data_in => sseg_display_data,
            sseg_ca         => sseg_ca_out,
            sseg_an         => sseg_an_out
        );


    --! Bootloader memory
    --! xF000_0000 to xFFFF_FFFF
    bootloader_inst : entity work.wb_sp_bram
    generic map(
        G_MEM_DEPTH_WORDS => 128,
        G_INIT_FILE       => G_BOOT_INIT_FILE
    )
    port map(
        wb_clk      => clk,
        wb_reset    => reset,
        wb_mosi_in  => wb_slave_mosi_arr(15),
        wb_miso_out => wb_slave_miso_arr(15)
    );
end architecture;