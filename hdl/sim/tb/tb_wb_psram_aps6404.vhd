
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.sim_wb_procedures.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity wb_psram_aps6404_tb is
    generic
    (
        runner_cfg : string
    );
end;

architecture bench of wb_psram_aps6404_tb is
    -- Clock period
    constant wb_clk_period  : time := 40 ns; -- 25MHz
    constant mem_clk_period : time := 40 ns; -- 25MHz
    -- Generics
    constant SIM_PSRAM_BYTES       : integer := 25000;
    constant MEM_CTRL_CLK_FREQ_KHZ : integer := 25000;
    constant BURST_LENGTH_BYTES    : integer := 4; -- cache line size
    -- Ports
    signal wb_clk       : std_logic := '0';
    signal mem_ctrl_clk : std_logic := '0';
    signal wb_reset     : std_logic := '1';
    signal wb_mosi      : t_wb_mosi;
    signal wb_miso      : t_wb_miso;
    -- PSRAM
    signal psram_clk  : std_logic;
    signal psram_cs_n : std_logic;
    signal psram_sio  : std_logic_vector(3 downto 0);
begin

    wb_psram_aps6404_inst : entity work.wb_psram_aps6404
        generic
        map (
        MEM_CLK_IS_WB_CLK     => MEM_CLK_IS_WB_CLK,
        MEM_CTRL_CLK_FREQ_KHZ => MEM_CTRL_CLK_FREQ_KHZ,
        BURST_LENGTH_BYTES    => BURST_LENGTH_BYTES
        )
        port map
        (
            wb_clk       => wb_clk,
            mem_ctrl_clk => mem_ctrl_clk,
            wb_reset     => wb_reset,
            wb_mosi_in   => wb_mosi,
            wb_miso_out  => wb_miso,
            psram_clk    => psram_clk,
            psram_cs_n   => psram_cs_n,
            psram_sio    => psram_sio
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("test_alive") then
                info("Hello world test_alive");

                sim_wb_write(wb_clk, wb_mosi, wb_miso, x"0", x"1111_2222");
                sim_wb_read(wb_clk, wb_mosi, wb_miso, x"0");

                wait for 10 * clk_period;
                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

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

    wb_clk  <= not wb_clk after wb_clk_period/2;
    mem_clk <= not mem_clk after mem_clk_period/2;
    test_runner_watchdog(runner, 20 us);
end;