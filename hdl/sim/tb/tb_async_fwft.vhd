
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity fifo_async_fwft_tb is
  generic (
    runner_cfg : string
  );
end;

architecture bench of fifo_async_fwft_tb is
  -- Clock period
  constant wr_clk_period : time := 5 ns;
  constant rd_clk_period : time := 6 ns;
  -- Generics
  constant RELATED_CLOCKS : boolean := false;
  constant FIFO_WRITE_DEPTH : integer := 16;
  constant WR_DATA_WIDTH : integer := 8;
  constant RD_DATA_WIDTH : integer := 8;
  -- Ports
  signal wr_clk : std_logic := '0';
  signal wr_rst : std_logic := '1';
  signal wr_stb : std_logic := '0';
  signal wr_data : std_logic_vector(WR_DATA_WIDTH - 1 downto 0);
  signal wr_full : std_logic;
  signal rd_clk : std_logic := '0';
  signal rd_stb : std_logic := '0';
  signal rd_data : std_logic_vector(RD_DATA_WIDTH - 1 downto 0);
  signal rd_empty : std_logic;
begin

  fifo_async_fwft_inst : entity work.fifo_async_fwft
  generic map (
    RELATED_CLOCKS => RELATED_CLOCKS,
    FIFO_WRITE_DEPTH => FIFO_WRITE_DEPTH,
    WR_DATA_WIDTH => WR_DATA_WIDTH,
    RD_DATA_WIDTH => RD_DATA_WIDTH
  )
  port map (
    wr_clk => wr_clk,
    wr_rst => wr_rst,
    wr_stb => wr_stb,
    wr_data => wr_data,
    wr_full => wr_full,
    rd_clk => rd_clk,
    rd_stb => rd_stb,
    rd_data => rd_data,
    rd_empty => rd_empty
  );
  main : process
    procedure write_byte(byte : std_logic_vector(7 downto 0)) is
    begin
        info("Wait for FIFO not full");
        wait until wr_full = '0' and rising_edge(wr_clk);
        info("Writing byte 0x" & to_hstring(byte));
        wr_stb <= '1';
        wr_data <= byte;
        wait until rising_edge(wr_clk);
        wr_stb <= '0';
    end procedure;

    procedure check_byte(byte : std_logic_vector(7 downto 0)) is
    begin
        info("Wait for FIFO not empty");
        wait until rd_empty = '0' and rising_edge(rd_clk);
        rd_stb <= '1';
        wait until rising_edge(rd_clk);
        info("Read byte 0x" & to_hstring(rd_data));
        rd_stb <= '0';
        -- check_equal(rd_data, byte);
    end procedure;
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then

        wait for 20 * wr_clk_period;
        wr_rst <= '0';

        info("Wait for reset to complete");
        wait until wr_full = '0' and rising_edge(rd_clk);
        write_byte(x"11");
        write_byte(x"23");
        check_byte(x"11");
        check_byte(x"23");
        wait until rd_empty = '1' and rising_edge(rd_clk);
        write_byte(x"55");
        check_byte(x"55");

        wait for 100 * wr_clk_period;
        test_runner_cleanup(runner);

      end if;
    end loop;
  end process main;
  test_runner_watchdog(runner, 10 us);


wr_clk <= not wr_clk after wr_clk_period/2;
rd_clk <= not rd_clk after rd_clk_period/2;

end;