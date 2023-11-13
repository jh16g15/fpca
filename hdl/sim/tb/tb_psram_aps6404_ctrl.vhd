
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_psram_aps6404_ctrl is
    generic
    (
        runner_cfg : string
    );
end;

architecture bench of tb_psram_aps6404_ctrl is
    -- Mem controller Clock period
    constant clk_period : time := 40 ns; --25MHz
    -- Generics
    constant MEM_CTRL_CLK_FREQ_KHZ : integer := 25000;
    constant BURST_LENGTH_BYTES    : integer := 4;

    -- Ports
    signal mem_ctrl_clk             : std_logic := '0';
    signal reset                    : std_logic := '0';
    signal burst_start_byte_address : std_logic_vector(22 downto 0);
    signal burst_start              : std_logic;
    signal burst_write              : std_logic;
    signal wdata_in                 : std_logic_vector(BURST_LENGTH_BYTES * 8 - 1 downto 0);
    signal burst_done               : std_logic;
    signal rdata_out                : std_logic_vector(BURST_LENGTH_BYTES * 8 - 1 downto 0);
    signal psram_busy               : std_logic;
    signal psram_clk                : std_logic;
    signal psram_cs_n               : std_logic;
    signal psram_sio                : std_logic_vector(3 downto 0);
begin
    main : process

        procedure psram_32b_write(byte_address : in integer; wdata : in std_logic_vector(31 downto 0)) is
        begin
            report "Start PSRAM write of " & to_hstring(wdata) & " to byte address" & integer'image(byte_address);
            wait until psram_busy = '0' and rising_edge(mem_ctrl_clk);
            burst_start_byte_address <= std_logic_vector(to_unsigned(byte_address, 23));
            burst_write              <= '1';
            burst_start              <= '1';
            wdata_in                 <= wdata;
            wait until rising_edge(mem_ctrl_clk);
            burst_start <= '0';
            wait until burst_done = '1' and rising_edge(mem_ctrl_clk);
            report "PSRAM Write complete!";
        end procedure;

        procedure psram_32b_check(byte_address : in integer; exp_rdata : in std_logic_vector(31 downto 0)) is
        begin
            report "Start PSRAM Read of byte address" & integer'image(byte_address);
            wait until psram_busy = '0' and rising_edge(mem_ctrl_clk);
            burst_start_byte_address <= std_logic_vector(to_unsigned(byte_address, 23));
            burst_write              <= '0';
            burst_start              <= '1';
            wait until rising_edge(mem_ctrl_clk);
            burst_start <= '0';
            wait until (burst_done = '1') and rising_edge(mem_ctrl_clk);
            check_equal(rdata_out, exp_rdata);
            report "PSRAM Read complete!";
        end procedure;

    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("test_alive") then
                info("Hello world test_alive");

                wait for 10 * clk_period;
                psram_32b_write(0, x"12345678");
                psram_32b_check(0, x"12345678");

                psram_32b_write(1024, x"78653434");
                psram_32b_check(1024, x"78653434");
                wait for 10 * clk_period;

                test_runner_cleanup(runner);

            end if;
        end loop;
    end process main;

    psram_aps6404_ctrl_inst : entity work.psram_aps6404_ctrl
        generic
        map (
        MEM_CTRL_CLK_FREQ_KHZ => MEM_CTRL_CLK_FREQ_KHZ,
        BURST_LENGTH_BYTES    => BURST_LENGTH_BYTES
        )
        port map
        (
            mem_ctrl_clk             => mem_ctrl_clk,
            reset                    => reset,
            burst_start_byte_address => burst_start_byte_address,
            burst_start              => burst_start,
            burst_write              => burst_write,
            wdata_in                 => wdata_in,
            burst_done               => burst_done,
            rdata_out                => rdata_out,

            psram_busy => psram_busy,
            psram_clk  => psram_clk,
            psram_cs_n => psram_cs_n,
            psram_sio  => psram_sio
        );

    sim_psram_aps6404_inst : entity work.sim_psram_aps6404
        generic
        map (
        G_MEM_BYTES => 8
        )
        port
        map (
        psram_clk  => psram_clk,
        psram_cs_n => psram_cs_n,
        psram_sio  => psram_sio
        );

    mem_ctrl_clk <= not mem_ctrl_clk after clk_period/2;
    test_runner_watchdog(runner, 20 us);
end;