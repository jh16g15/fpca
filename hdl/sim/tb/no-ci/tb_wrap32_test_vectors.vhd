
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_wrap32_test_vectors is
    generic (
        runner_cfg : string
    );
end;

architecture bench of tb_wrap32_test_vectors is
    -- Clock period
    constant clk_period : time := 200 ns;
    -- Generics
    constant G_BURST_LEN : integer range 4 to 32 := 4;
    constant G_FREQ_KHZ : integer := 5_000;
    constant G_SIM : boolean := false;
    -- constant G_TEST_LENGTH : integer := 16 * 1024; -- 64KB is modelled as memory
    constant G_TEST_LENGTH : integer := 4; -- smaller test for speed
    -- Ports
    signal clk : std_logic := '0';
    signal reset : std_logic := '1';
    signal test_pass : std_logic;
    signal test_fail : std_logic;
    signal psram_sel : std_logic_vector(1 downto 0);
    signal psram_clk : std_logic;
    signal psram_cs_n : std_logic;
    signal psram_sio : std_logic_vector(3 downto 0);
begin

    reset <= '0' after 10 * clk_period;

    wrap32_test_vectors_inst : entity work.wrap32_test_vectors
    generic map (
        G_BURST_LEN => G_BURST_LEN,
        G_FREQ_KHZ => G_FREQ_KHZ,
        G_SIM => G_SIM,
        G_TEST_LENGTH => G_TEST_LENGTH
    )
    port map (
        clk => clk,
        reset => reset,
        test_pass => test_pass,
        test_fail => test_fail,
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
                

                wait until test_pass or test_fail;

                wait for 100 ns;

                test_runner_cleanup(runner);
        
            
            end if;
        end loop;
    end process main;

    test_runner_watchdog(runner, 10 ms);

clk <= not clk after clk_period/2;

sim_machdyne_qqspi_psram_pmod_inst : entity work.sim_machdyne_qqspi_psram_pmod
  port map (
    sclk => psram_clk,
    ss_n => psram_cs_n,
    sio => psram_sio,
    cs => psram_sel
  );

end;