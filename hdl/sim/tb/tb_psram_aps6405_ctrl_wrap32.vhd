
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
  constant clk_period : time := 7.5 ns;
  -- Generics
  constant G_BURST_LEN : integer := 8;
  constant G_FREQ_KHZ : integer := 133_000;
  constant G_SIM : boolean := true;
  -- Ports
  signal clk : std_logic := '0';
  signal reset : std_logic := '0';
  signal cmd_valid : std_logic;
  signal cmd_ready : std_logic;
  signal cmd_address_in : std_logic_vector(24 downto 0);
  signal cmd_we_in : std_logic;
  signal cmd_wdata_in : std_logic_vector(G_BURST_LEN*8-1 downto 0) := (others => '0');
  signal rsp_valid : std_logic;
  signal rsp_rdata_out : std_logic_vector(G_BURST_LEN*8-1 downto 0);
  signal psram_sel : std_logic_vector(1 downto 0);
  signal psram_clk : std_logic;
  signal psram_cs_n : std_logic;
  signal psram_sio : std_logic_vector(3 downto 0);

  -- 8MB each
  constant PSRAM0_BASE : std_logic_vector(24 downto 0) := "0" & x"00_0000";
  constant PSRAM1_BASE : std_logic_vector(24 downto 0) := "0" & x"80_0000";
  constant PSRAM2_BASE : std_logic_vector(24 downto 0) := "1" & x"00_0000";
  constant PSRAM3_BASE : std_logic_vector(24 downto 0) := "1" & x"80_0000";
begin

  psram_aps6404_ctrl_wrap32_inst : entity work.psram_aps6404_ctrl_wrap32
  generic map (
    G_BURST_LEN => G_BURST_LEN,
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
        cmd_valid <= '1';
        cmd_address_in <= PSRAM0_BASE;
        cmd_we_in <= '1';
        cmd_wdata_in(31 downto 0) <= x"0403_0201";
        cmd_wdata_in(G_BURST_LEN*8-1 downto G_BURST_LEN*8-32) <= x"CAFE_F00D";
        wait until cmd_ready = '1' and rising_edge(clk); -- write accepted
        cmd_we_in <= '0';
        wait until cmd_ready = '1' and rising_edge(clk);  -- read accepted
        cmd_valid <= '0';
        wait until rsp_valid = '1' and rising_edge(clk);
        info("Rdata= 0x" & to_hstring(rsp_rdata_out));
        
        wait for 100 ns;

        test_runner_cleanup(runner);
        
      end if;
    end loop;
  end process main;
  test_runner_watchdog(runner, 20 ms);

clk <= not clk after clk_period/2;

sim_machdyne_qqspi_psram_pmod_inst : entity work.sim_machdyne_qqspi_psram_pmod
  port map (
    sclk => psram_clk,
    ss_n => psram_cs_n,
    sio => psram_sio,
    cs => psram_sel
  );

-- sim_psram_aps6404_inst : entity work.sim_psram_aps6404
--   port map (
--     psram_clk => psram_clk,
--     psram_cs_n => psram_cs_n,
--     psram_sio => psram_sio
--   );

end;