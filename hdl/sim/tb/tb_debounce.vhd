library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_debounce is
  generic (runner_cfg : string);
end;

architecture bench of tb_debounce is


  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant REFCLK_FREQ : integer := 100_000_000;
  constant DEBOUNCE_PERIOD_MS : integer := 1;
  constant INIT_OUT : std_logic := '0';

  -- Ports
  signal clk : std_logic;
  signal val_in : std_logic;
  signal val_out : std_logic;

begin

  debounce_inst : entity work.debounce
    generic map (
      REFCLK_FREQ => REFCLK_FREQ,
      DEBOUNCE_PERIOD_MS => DEBOUNCE_PERIOD_MS,
      INIT_OUT => INIT_OUT
    )
    port map (
      clk => clk,
      val_in => val_in,
      val_out => val_out
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    show(get_logger(default_checker), display_handler, pass);
    while test_suite loop
      if run("start_low") then
        info("start_low Started");
        val_in <= '0';
        wait for 0.5 ms;
        check_equal(val_out, '0', "check still 0");
        val_in <= '1';
        wait for 1.1 ms;
        check_equal(val_out, '1', "check now 1 as stable for more than debounce period");
        val_in <= '0';
        wait for 0.1 ms;
        check_equal(val_out, '1', "check that the short pulse of '0' has been rejected");
        val_in <= '1';
        wait for 0.1 ms;
        check_equal(val_out, '1', "check still '1'");
        val_in <= '0';
        wait for 2 ms;
        check_equal(val_out, '0', "check that now we've gone to '0'");
        test_runner_cleanup(runner);
      elsif run("start_high") then
          info("start_high Started");
          val_in <= '1';
          wait for 0.5 ms;
          check_equal(val_out, '0', "check still 0");
          val_in <= '1';
          wait for 1.1 ms;
          check_equal(val_out, '1', "check now 1 as stable for more than debounce period");
          val_in <= '0';
          wait for 0.1 ms;
          check_equal(val_out, '1', "check that the short pulse of '0' has been rejected");
          val_in <= '1';
          wait for 0.1 ms;
          check_equal(val_out, '1', "check still '1'");
          val_in <= '0';
          wait for 2 ms;
          check_equal(val_out, '0', "check that now we've gone to '0'");
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
