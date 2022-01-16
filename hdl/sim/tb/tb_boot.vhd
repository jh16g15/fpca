library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_boot is
    generic (runner_cfg : string);
end tb_boot;

architecture bench of tb_boot is
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

begin
    -- DUT
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
            uart_rx_in   => '1'
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


                gpio_sw_in(15) <= '1';  -- start the bootloader

                wait for 250000 * clk_period;

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