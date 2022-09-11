library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity stream_2to1_tb is
  generic (runner_cfg : string);
end;

architecture bench of stream_2to1_tb is


  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant G_IN_W : integer := 8;
  constant G_OUT_W : integer := 4;
--   constant G_HALF_SEND_FIRST : string := "top";
  constant G_HALF_SEND_FIRST : string := "bot";

  -- Ports
  signal clk : std_logic;
  signal reset : std_logic;
  signal data_in : std_logic_vector(G_IN_W-1 downto 0);
  signal data_in_valid : std_logic;
  signal data_in_ready : std_logic;
  signal data_out : std_logic_vector(G_OUT_W-1 downto 0);
  signal data_out_valid : std_logic;
  signal data_out_ready : std_logic;

begin

  stream_2to1_inst : entity work.stream_2to1
    generic map (
      G_IN_W => G_IN_W,
      G_OUT_W => G_OUT_W,
      G_HALF_SEND_FIRST => G_HALF_SEND_FIRST
    )
    port map (
      clk => clk,
      reset => reset,
      data_in => data_in,
      data_in_valid => data_in_valid,
      data_in_ready => data_in_ready,
      data_out => data_out,
      data_out_valid => data_out_valid,
      data_out_ready => data_out_ready
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        info("Hello world test_alive");

        reset <= '1';
        wait for 2 * clk_period;
        reset <= '0';


        data_in_valid <= '0';
        data_in <= x"00";
        wait for clk_period;

        data_in_valid <= '1';
        data_in <= x"12";
        -- wait for 2*clk_period;
        wait until data_in_ready = '1' and rising_edge(clk);

        data_in <= x"34";
        -- wait for 2*clk_period;
        wait until data_in_ready = '1' and rising_edge(clk);

        data_in <= x"56";
        -- wait for 2*clk_period;
        wait until data_in_ready = '1' and rising_edge(clk);

        data_in <= x"78";
        -- wait for 2*clk_period;
        wait until data_in_ready = '1' and rising_edge(clk);

        data_in_valid <= '0';
        data_in <= x"FF";


        wait for 50 * clk_period;
        test_runner_cleanup(runner);


      end if;
    end loop;
  end process main;

  back_pressure_proc : process is
  begin
    data_out_ready <= '1';
    wait for 5 * clk_period;
    data_out_ready <= '0';
    wait for 10 * clk_period;
    data_out_ready <= '1';


  end process back_pressure_proc;

  check_input_proc : process
  begin
    wait until rising_edge(clk) and data_in_valid = '1' and data_in_ready = '1';
    info("Input: " & to_hstring(data_in));

  end process check_input_proc;

  check_output_proc : process
  begin
    wait until rising_edge(clk) and data_out_valid = '1' and data_out_ready = '1';
    info("Output: " & to_hstring(data_out));

  end process check_output_proc;

  test_runner_watchdog(runner, 1 ms);

  clk_process : process
  begin
  clk <= '1';
  wait for clk_period/2;
  clk <= '0';
  wait for clk_period/2;
  end process clk_process;

end;
