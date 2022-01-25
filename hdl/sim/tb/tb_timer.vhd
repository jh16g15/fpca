library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer is
    generic (runner_cfg : string);
end;

architecture bench of tb_timer is
    -- Clock period
    constant clk_period : time := 20 ns;
    -- Generics
    constant G_TIMER_W     : integer := 32;
    constant G_PWM_SUPPORT : boolean := true;

    -- Ports
    signal clk                      : std_logic;
    signal reset                    : std_logic;
    signal new_count_value_in       : std_logic_vector(G_TIMER_W - 1 downto 0);
    signal new_count_value_valid_in : std_logic;
    signal count_enable_in          : std_logic;
    signal count_value_out          : std_logic_vector(G_TIMER_W - 1 downto 0);
    signal pwm_threshold_in         : std_logic_vector(G_TIMER_W - 1 downto 0);
    signal pwm_thresh_valid_in      : std_logic;
    signal count_top_threshold_in   : std_logic_vector(G_TIMER_W - 1 downto 0);
    signal top_thresh_valid_in      : std_logic;
    signal pwm_mode_enable_in       : std_logic;
    signal pwm_out                  : std_logic;
    signal clr_oflow_flag_in        : std_logic;
    signal oflow_flag_out           : std_logic;

begin

    timer_inst : entity work.timer
        generic map(
            G_TIMER_W     => G_TIMER_W,
            G_PWM_SUPPORT => G_PWM_SUPPORT
        )
        port map(
            clk                      => clk,
            reset                    => reset,
            new_count_value_in       => new_count_value_in,
            new_count_value_valid_in => new_count_value_valid_in,
            count_enable_in          => count_enable_in,
            count_value_out          => count_value_out,
            pwm_threshold_in         => pwm_threshold_in,
            pwm_thresh_valid_in      => pwm_thresh_valid_in,
            count_top_threshold_in   => count_top_threshold_in,
            top_thresh_valid_in      => top_thresh_valid_in,
            pwm_mode_enable_in       => pwm_mode_enable_in,
            pwm_out                  => pwm_out,
            clr_oflow_flag_in        => clr_oflow_flag_in,
            oflow_flag_out           => oflow_flag_out
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        show(get_logger(default_checker), display_handler, pass); -- show passing assertions

        reset <= '1';
        wait for clk_period * 3;
        reset              <= '0';
        count_enable_in    <= '0';
        pwm_mode_enable_in <= '0';

        while test_suite loop
            if run("counting_test") then
                info("Running counting_test");
                new_count_value_in       <= (others => '0');
                new_count_value_valid_in <= '1';
                wait for clk_period;
                new_count_value_valid_in <= '0';
                count_enable_in          <= '1';
                wait for clk_period * 50;
                check_equal(count_value_out, 50, "Counter check");

                wait for 100 * clk_period;
                check_equal(count_value_out, 150, "Counter check");

                count_enable_in <= '0';
                wait for 10 * clk_period;
                check_equal(count_value_out, 150, "Counter check");
                test_runner_cleanup(runner);

            elsif run("oflow_test") then
                info("Running oflow_test");
                new_count_value_in       <= (others => '0');
                new_count_value_valid_in <= '1';
                count_top_threshold_in   <= std_logic_vector(to_unsigned(100, 32));
                top_thresh_valid_in      <= '1';
                wait for clk_period;
                new_count_value_valid_in <= '0';
                top_thresh_valid_in      <= '0';

                count_enable_in <= '1';

                wait for 100 * clk_period;
                wait for clk_period; -- takes 1 extra clock for OFlow flag to be set
                check_equal(oflow_flag_out, '1', "check overflow flag set");
                check_equal(count_value_out, 0, "check counter reset");

                wait for 10 * clk_period;
                check_equal(oflow_flag_out, '1', "check overflow flag still set");

                clr_oflow_flag_in <= '1';
                wait for clk_period;
                clr_oflow_flag_in <= '0';
                check_equal(oflow_flag_out, '0', "check overflow flag cleared");
                wait for 10 * clk_period;

                test_runner_cleanup(runner);

            elsif run("pwm_test") then
                info("Running pwm_test (not self checking)");
                -- enable PWM mode
                pwm_mode_enable_in       <= '1';
                -- load values
                new_count_value_in       <= (others => '0');
                count_top_threshold_in   <= std_logic_vector(to_unsigned(20, 32));
                pwm_threshold_in         <= std_logic_vector(to_unsigned(10, 32));
                new_count_value_valid_in <= '1';
                top_thresh_valid_in      <= '1';
                pwm_thresh_valid_in      <= '1';
                wait for clk_period;
                new_count_value_valid_in <= '0';
                top_thresh_valid_in      <= '0';
                pwm_thresh_valid_in      <= '0';
                -- start counting
                count_enable_in <= '1';

                wait for 100 * clk_period;
                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;