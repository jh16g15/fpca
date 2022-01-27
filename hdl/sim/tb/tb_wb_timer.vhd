library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

--
library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.bus_master_pkg.all;

entity wb_timer_tb is
    generic (runner_cfg : string);
end;

architecture bench of wb_timer_tb is
    -- Clock period
    constant clk_period : time := 20 ns;
    -- Generics
    constant G_NUM_TIMERS : integer := 1;

    -- Ports
    signal wb_clk              : std_logic;
    signal wb_reset            : std_logic := '0';
    signal wb_mosi             : t_wb_mosi;
    signal wb_miso             : t_wb_miso;
    signal pwm_out             : std_logic;
    signal timer_interrupt_out : std_logic_vector(G_NUM_TIMERS - 1 downto 0);

    constant tb_logger     : logger_t := get_logger("tb");
    constant master_logger : logger_t := get_logger("master");
    -- VUnit Jazz (see vunit tb_wishbone_master)
    constant bus_handle : bus_master_t := new_bus(data_length => 32,
    address_length => 32, logger => master_logger);

    constant strobe_high_probability : real := 0.5; -- what does this do?
begin

    wb_timer_inst : entity work.wb_timer
        generic map(
            G_NUM_TIMERS => G_NUM_TIMERS
        )
        port map(
            wb_clk              => wb_clk,
            wb_reset            => wb_reset,
            wb_mosi_in          => wb_mosi,
            wb_miso_out         => wb_miso,
            pwm_out             => pwm_out,
            timer_interrupt_out => timer_interrupt_out
        );

    vunit_wishbone_master_inst : entity vunit_lib.wishbone_master
        generic map(
            bus_handle              => bus_handle,
            strobe_high_probability => strobe_high_probability
        )
        port map(
            clk   => wb_clk,
            adr   => wb_mosi.adr,
            dat_i => wb_miso.rdat,
            dat_o => wb_mosi.wdat,
            sel   => wb_mosi.sel,
            cyc   => wb_mosi.cyc,
            stb   => wb_mosi.stb,
            we    => wb_mosi.we,
            stall => wb_miso.stall,
            ack   => wb_miso.ack
        );

    main : process
        -- Register Map per timer
        -- x0: Current Value of time_reg (32b)
        -- R/W
        -- x4: Timer Control and Status register
        -- [0]      Timer Start/Stop
        -- [1]      Enable Overflow Interrupt
        -- [2]      Enable PWM mode
        -- [8]     Clear timer overflow
        -- [16]     Timer Overflow
        -- x8: Timer Threshold Register (32b)
        -- xC: PWM Threshold Register (32b)
        constant COUNT_REG : std_logic_vector(31 downto 0) := x"0000_0000";
        constant CTRL_REG  : std_logic_vector(31 downto 0) := x"0000_0004";
        constant TOP_REG   : std_logic_vector(31 downto 0) := x"0000_0008";
        constant PWM_REG   : std_logic_vector(31 downto 0) := x"0000_000C";

        variable rdata : std_logic_vector(31 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);

        set_format(display_handler, verbose, true);
        show(tb_logger, display_handler, verbose);
        show(default_logger, display_handler, verbose);
        show(master_logger, display_handler, verbose);
        -- show passing assertions
        -- show(get_logger(default_checker), display_handler, pass);
        wait until rising_edge(wb_clk);
        wb_reset <= '0';
        while test_suite loop
            if run("counting_test") then
                info("Running counting_test");
                info("Setting count value to 0");
                write_bus(net, bus_handle, COUNT_REG, x"0000_0000");
                wait until wb_miso.ack = '1' and rising_edge(wb_clk);
                info("Starting counter");
                write_bus(net, bus_handle, CTRL_REG, x"0000_0001");
                wait until wb_miso.ack = '1' and rising_edge(wb_clk);
                info("Waiting 50 clocks");
                wait for clk_period * 50;
                read_bus(net, bus_handle, COUNT_REG, rdata);
                check_equal(rdata, 50+2, "Counter check (includes 2 cycles of fudge for wishbone accesses)");

                info("Waiting 100 more clocks");
                wait for 100 * clk_period;
                read_bus(net, bus_handle, COUNT_REG, rdata);
                check_equal(rdata, 150+5, "Counter check (includes 5 cycles of fudge for wishbone accesses)");
                info("stop counting");
                write_bus(net, bus_handle, CTRL_REG, x"0000_0000");
                wait until wb_miso.ack = '1' and rising_edge(wb_clk);
                info("Waiting 10 clocks");
                wait for 10 * clk_period;
                read_bus(net, bus_handle, COUNT_REG, rdata);
                check_equal(rdata, 150+10, "Counter check stopped counting (includes 5 cycles of fudge for wishbone accesses");
                test_runner_cleanup(runner);

            elsif run("test_0") then
                info("Hello world test_0");
                wait for 100 * clk_period;
                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

      clk_process : process
      begin
      wb_clk <= '1';
      wait for clk_period/2;
      wb_clk <= '0';
      wait for clk_period/2;
      end process clk_process;

end;