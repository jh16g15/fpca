library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_sim_psram is
  generic (runner_cfg : string);
end;

architecture bench of tb_sim_psram is


    -- Generics
    constant G_BURST_LEN : integer := 16;
    constant G_MEMCLK_PERIOD : time := 10 ns;
    constant G_DATA_W : integer := 32;
    constant G_PSRAM_ADDR_W : integer := 21;
    constant G_MEM_DEPTH : integer := 64;
    constant C_INIT_DELAY : integer := 10;
    constant C_READ_DELAY : integer := 10;

    -- Ports
    signal clk : std_logic;
    signal rst_n : std_logic;
  signal wr_data : std_logic_vector(G_DATA_W-1 downto 0);
  signal rd_data : std_logic_vector(G_DATA_W-1 downto 0);
  signal rd_data_valid : std_logic;
  signal addr : std_logic_vector(G_PSRAM_ADDR_W-1 downto 0);
  signal cmd : std_logic;
  signal cmd_en : std_logic;
  signal init_calib : std_logic;
  signal clk_out : std_logic;
  signal data_mask : std_logic_vector(G_DATA_W/8-1 downto 0);

  -- Clock period
  constant clk_period : time := G_MEMCLK_PERIOD * 2;

begin

  sim_psram_inst : entity work.sim_psram
    generic map (
      G_BURST_LEN => G_BURST_LEN,
      G_MEMCLK_PERIOD => G_MEMCLK_PERIOD,
      G_DATA_W => G_DATA_W,
      G_PSRAM_ADDR_W => G_PSRAM_ADDR_W,
      G_MEM_DEPTH => G_MEM_DEPTH,
      C_INIT_DELAY => C_INIT_DELAY,
      C_READ_DELAY => C_READ_DELAY
    )
    port map (
      rst_n => rst_n,
      wr_data => wr_data,
      rd_data => rd_data,
      rd_data_valid => rd_data_valid,
      addr => addr,
      cmd => cmd,
      cmd_en => cmd_en,
      init_calib => init_calib,
      clk_out => clk,
      data_mask => data_mask
    );

  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        info("Hello world test_alive");


        cmd <= '1';
        cmd_en <= '0';
        wr_data <= x"1111_0000";
        data_mask <= x"0";  -- all bytes active
        addr <= std_logic_vector(to_unsigned(0, addr'length));
        wait until init_calib = '1';
        wait for clk_period;
        cmd_en <= '1';
        wait for clk_period;
        cmd_en <= '0';
        wr_data <= x"3333_2222";
        wait for clk_period;
        wr_data <= x"5555_4444";
        wait for clk_period;
        wr_data <= x"7777_6666";
        wait for clk_period;
        wr_data <= x"FFFF_FFFF";    -- this shouldn't be written

        wait for 20 * clk_period;

        cmd <= '0'; -- READ
        cmd_en <= '1';
        addr <= std_logic_vector(to_unsigned(1 , addr'length));   -- start reading at 1 this time, for an aligned 16-bit access
        wait for clk_period;
        cmd_en <= '0';
        wait until rd_data_valid = '1';
        wait for 1 ns;
        check_equal(rd_data , std_logic_vector'(x"2222_1111"), "1st word readback error" );

        wait for clk_period;
        check_equal(rd_data , std_logic_vector'(x"4444_3333"), "2nd word readback error" );

        wait for clk_period;
        check_equal(rd_data , std_logic_vector'(x"6666_5555"), "3rd word readback error" );

        wait for clk_period;
        check_false(rd_data = std_logic_vector'(x"FFFF_FFFF"), "4th word readback error" );

        wait for clk_period;


        wait for 100 * clk_period;
        info("test done!");
        test_runner_cleanup(runner);

      end if;
    end loop;
  end process main;


end;
