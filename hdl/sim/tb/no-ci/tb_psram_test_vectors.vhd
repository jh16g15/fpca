library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_psram_test_vectors is
  generic (runner_cfg : string);
end;

architecture bench of tb_psram_test_vectors is


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

  -- STIM
  signal done : std_logic;
  signal err : std_logic_vector(3 downto 0);

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

    psram_test_vectors_inst : entity work.psram_test_vectors
  generic map (
    G_BURST_LEN => G_BURST_LEN
  )
  port map (
    usrclk_in => clk,
    rstn_in => rst_n,
    start_in => init_calib,
    wr_data_out => wr_data,
    data_mask_out => data_mask,
    rd_data_in => rd_data,
    rd_data_valid_in => rd_data_valid,
    addr_out => addr,
    cmd_out => cmd,
    cmd_en_out => cmd_en,
    done_out => done,
    err_out => err
  );


  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        info("Hello world test_alive");
        wait until done = '1';
        wait for 10 ns;
        check_equal(err, std_logic_vector'(x"0"), "check for errors ");
        info("test done!");
        test_runner_cleanup(runner);

      end if;
    end loop;
  end process main;


end;
