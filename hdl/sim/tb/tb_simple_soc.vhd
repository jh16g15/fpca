library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vunit_lib;
context vunit_lib.vunit_context;

use work.wb_pkg.all;
use work.axi_pkg.all;

entity tb_simple_soc is
    generic (runner_cfg : string);
end tb_simple_soc;

architecture bench of tb_simple_soc is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    -- constant G_MEM_INIT_FILE : string := "data/blinky.hex"; -- simulation
    constant G_MEM_INIT_FILE : string := "../../software/hex/main.hex"; -- from toolchain

    -- Ports
    signal clk          : std_logic;
    signal reset        : std_logic := '0';
    signal gpio_led_out : std_logic_vector(31 downto 0);
    signal gpio_btn_in  : std_logic_vector(31 downto 0);
    signal gpio_sw_in   : std_logic_vector(31 downto 0);
    signal sseg_ca_out  : std_logic_vector(7 downto 0);
    signal sseg_an_out  : std_logic_vector(3 downto 0);
    signal uart_tx      : std_logic;

    signal text_display_wb_mosi        : t_wb_mosi;
    signal text_display_wb_miso        : t_wb_miso;
    signal zynq_ps_peripherals_wb_mosi : t_wb_mosi;
    signal zynq_ps_peripherals_wb_miso : t_wb_miso;

begin
    -- DUT


    -- simple_soc_inst : entity work.simple_soc
    --     generic map(
    --         G_MEM_INIT_FILE  => G_MEM_INIT_FILE,
    --         G_BOOT_INIT_FILE => G_BOOT_INIT_FILE,
    --         G_SOC_FREQ       => 25_000_000,
    --         G_DEFAULT_BAUD   => 9600
    --     )
    --     port map(
    --         clk          => pixelclk,
    --         reset        => reset,
    --         gpio_led_out => gpio_led,
    --         gpio_btn_in  => x"0000_000" & btn(3 downto 0),
    --         gpio_sw_in   => x"0000_000" & b"00" & sw(1 downto 0),
    --         -- sseg_ca_out              => sseg_ca_out,
    --         -- sseg_an_out              => sseg_an_out,
    --         uart_tx_out                     => uart_tx_out,
    --         uart_rx_in                      => uart_rx_in,
    --         i2c_scl_out                     => open,
    --         i2c_sda_out                     => open,
    --         text_display_wb_mosi_out        => text_display_wb_mosi,
    --         text_display_wb_miso_in         => text_display_wb_miso,
    --         zynq_ps_peripherals_wb_mosi_out => zynq_ps_peripherals_wb_mosi,
    --         zynq_ps_peripherals_wb_miso_in  => zynq_ps_peripherals_wb_miso
    --     );

    simple_soc_inst : entity work.simple_soc
        generic map(
            G_MEM_INIT_FILE => G_MEM_INIT_FILE
        )
        port map(
            clk          => clk,
            reset        => reset,
            gpio_led_out => gpio_led_out,
            gpio_btn_in  => gpio_btn_in,
            gpio_sw_in   => gpio_sw_in,
            sseg_ca_out  => sseg_ca_out,
            sseg_an_out  => sseg_an_out,
            uart_tx_out  => uart_tx,
            uart_rx_in   => '1',
            i2c_scl_out                     => open,
            i2c_sda_out                     => open,
            text_display_wb_mosi_out        => text_display_wb_mosi,
            text_display_wb_miso_in         => text_display_wb_miso,
            zynq_ps_peripherals_wb_mosi_out => zynq_ps_peripherals_wb_mosi,
            zynq_ps_peripherals_wb_miso_in  => zynq_ps_peripherals_wb_miso
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);

        -- continue simulating on error
        set_stop_level(failure);

        while test_suite loop
            if run("test_alive") then
                info("Hello world test_alive");

                gpio_btn_in <= x"0000_0000";
                gpio_sw_in  <= x"0000_0000";

                wait for 500000 * clk_period;

                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

    rst_proc : process
    begin
        reset <= '1';
        wait for 10 * clk_period;
        reset <= '0';
        wait for 250000 * clk_period;
        reset <= '1';
        wait for 1 * clk_period;
        reset <= '0';
        wait;
    end process;

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;