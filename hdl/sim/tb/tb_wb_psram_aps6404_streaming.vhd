
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.sim_wb_procedures_pkg.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

-- for non-blocking WB transactions (queue)
library osvvm;
use osvvm.ScoreBoardPkg_slv.all;

entity tb_wb_psram_aps6404_streaming is
    generic
    (
        runner_cfg : string
    );
end;

architecture bench of tb_wb_psram_aps6404_streaming is
    constant wb_clk_period  : time := 40 ns; -- 25MHz

    -- constant mem_clk_period : time := 40 ns; -- 25MHz
    -- constant MEM_CTRL_CLK_FREQ_KHZ : integer := 25000;
    -- constant mem_clk_period : time := 20 ns; -- 50MHz
    -- constant MEM_CTRL_CLK_FREQ_KHZ : integer := 50000;
    constant mem_clk_period : time := 10 ns; --100MHz
    constant MEM_CTRL_CLK_FREQ_KHZ : integer :=100000;

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

    wb_psram_aps6404_inst : entity work.wb_psram_aps6404_streaming
        generic
        map (
        MEM_CTRL_CLK_FREQ_KHZ => MEM_CTRL_CLK_FREQ_KHZ,
        RELATED_CLOCKS => true
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
        -- variable rdata : std_logic_vector(31 downto 0);
    begin
        test_runner_setup(runner, runner_cfg);
        show(get_logger("check"), display_handler, pass);
        while test_suite loop
            if run("test_alive") then
                info("Hello world test_alive");
                wait for 10 * wb_clk_period;
                wb_reset <= '0';
                wait for 10 * wb_clk_period;

                wait until wb_miso.stall = '0';
                -- WRITE32
                sim_wb_write(wb_clk, wb_mosi, wb_miso, x"0000_0000", x"ef11_2222"); -- initial
                wait until rising_edge(wb_clk);
                sim_wb_write(wb_clk, wb_mosi, wb_miso, x"0000_0004", x"bebe_8a8a"); -- continued
                wait until rising_edge(wb_clk);
                -- READ32
                sim_wb_check(wb_clk, wb_mosi, wb_miso, x"0000_0000", x"ef11_2222"); -- initial
                wait until rising_edge(wb_clk);
                sim_wb_check(wb_clk, wb_mosi, wb_miso, x"0000_0004", x"bebe_8a8a"); -- continued
                wait until rising_edge(wb_clk);
                -- WRITE16
                sim_wb_write(wb_clk, wb_mosi, wb_miso, x"0000_0000", x"5abc_0000", b"1100"); -- initial
                wait until rising_edge(wb_clk);
                sim_wb_write(wb_clk, wb_mosi, wb_miso, x"0000_0004", x"0000_6a7a", b"0011"); -- continued
                wait until rising_edge(wb_clk);
                -- READ16
                sim_wb_check(wb_clk, wb_mosi, wb_miso, x"0000_0000", x"5abc_0000", b"1100"); -- initial
                wait until rising_edge(wb_clk);
                sim_wb_check(wb_clk, wb_mosi, wb_miso, x"0000_0004", x"0000_6a7a", b"0011"); -- continued
                wait until rising_edge(wb_clk);
                -- WRITE8
                sim_wb_write(wb_clk, wb_mosi, wb_miso, x"0000_1000", x"bc00_0000", b"1000"); -- initial
                wait until rising_edge(wb_clk);
                sim_wb_write(wb_clk, wb_mosi, wb_miso, x"0000_1004", x"0000_0012", b"0001"); -- continued
                wait until rising_edge(wb_clk);
                -- READ8
                sim_wb_check(wb_clk, wb_mosi, wb_miso, x"0000_1000", x"bc00_0000", b"1000"); -- initial
                wait until rising_edge(wb_clk);
                sim_wb_check(wb_clk, wb_mosi, wb_miso, x"0000_1004", x"0000_0012", b"0001"); -- continued
                wait until rising_edge(wb_clk);
                wait for 10 * wb_clk_period;
                info("Test Complete!");
                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

    sim_psram_aps6404_inst : entity work.sim_psram_aps6404
        port
        map (
        psram_clk  => psram_clk,
        psram_cs_n => psram_cs_n,
        psram_sio  => psram_sio
        );

    wb_clk  <= not wb_clk after wb_clk_period/2;
    mem_ctrl_clk <= not mem_ctrl_clk after mem_clk_period/2;
    test_runner_watchdog(runner, 50 us);
end;