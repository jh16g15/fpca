
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_psram_aps6404_ctrl_wrap32 is
  generic (
    runner_cfg : string
  );
end;

architecture bench of tb_psram_aps6404_ctrl_wrap32 is
  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant G_FREQ_KHZ : integer := 10_000;
  constant G_SIM : boolean := true;
  -- Ports
  signal clk : std_logic := '0';
  signal reset : std_logic := '0';
  signal cmd_valid : std_logic;
  signal cmd_ready : std_logic;
  signal cmd_address_in : std_logic_vector(22 downto 0);
  signal cmd_we_in : std_logic;
  signal cmd_wdata_valid : std_logic_vector(7 downto 0);
  signal cmd_wdata_in : std_logic_vector(7 downto 0);
  signal rsp_valid : std_logic;
  signal rsp_rdata_out : std_logic_vector(7 downto 0);
  signal psram_sel : std_logic_vector(1 downto 0);
  signal psram_clk : std_logic;
  signal psram_cs_n : std_logic;
  signal psram_sio : std_logic_vector(3 downto 0);
begin

  psram_aps6404_ctrl_wrap32_inst : entity work.psram_aps6404_ctrl_wrap32
  generic map (
    G_FREQ_KHZ => G_FREQ_KHZ,
    G_SIM => G_SIM
  )
  port map (
    clk => clk,
    reset => reset,
    cmd_valid => cmd_valid,
    cmd_ready => cmd_ready,
    cmd_address_in => cmd_address_in,
    cmd_we_in => cmd_we_in,
    cmd_wdata_valid => cmd_wdata_valid,
    cmd_wdata_in => cmd_wdata_in,
    rsp_valid => rsp_valid,
    rsp_rdata_out => rsp_rdata_out,
    psram_sel => psram_sel,
    psram_clk => psram_clk,
    psram_cs_n => psram_cs_n,
    psram_sio => psram_sio
  );
  main : process
  begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
      if run("test_alive") then
        info("Hello world test_alive");
        wait for 500 * clk_period;
        info("Hello world test_alive still");
        test_runner_cleanup(runner);
        
      end if;
    end loop;
  end process main;

clk <= not clk after clk_period/2;

end;