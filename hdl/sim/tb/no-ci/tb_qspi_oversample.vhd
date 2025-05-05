
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_qspi_oversample is
  generic (
    runner_cfg : string
  );
end;

architecture bench of tb_qspi_oversample is
  -- Clock period
  constant clk_period : time := 5 ns;   -- 200MHz
  -- Generics
  constant OVERSAMPLE_KHZ : integer := 200_000;
  constant SPI_KHZ : integer := 20_000;
  -- Ports
  signal oversample_clk : std_logic := '0';
  signal oversample_rst : std_logic := '1';
  signal qspi_clk_in : std_logic;
  signal qspi_clk_out : std_logic;
  signal init_done : std_logic;
  signal qspi_csn : std_logic;
  signal qspi_sio : std_logic_vector(3 downto 0);
begin

    oversample_rst <= '0' after 24 ns;

  qspi_oversample_inst : entity work.qspi_oversample
  generic map (
    OVERSAMPLE_KHZ => OVERSAMPLE_KHZ,
    SPI_KHZ => SPI_KHZ
  )
  port map (
    oversample_clk => oversample_clk,
    oversample_rst => oversample_rst,
    -- qspi_clk_in => qspi_clk_in,
    qspi_clk_out => qspi_clk_out,
    init_done_out => init_done,
    qspi_csn => qspi_csn,
    qspi_sio => qspi_sio
  );

  test_runner_watchdog(runner, 10 ms);

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        info("Hello world test_alive");
        wait until init_done = '1' and rising_edge(oversample_clk);
        test_runner_cleanup(runner);

      end if;
    end loop;
  end process main;

  oversample_clk <= not oversample_clk after clk_period/2;

end;