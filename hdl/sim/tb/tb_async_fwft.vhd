
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

library osvvm;
use osvvm.ScoreBoardPkg_slv.all;

entity fifo_async_fwft_tb is
    generic
    (
        runner_cfg : string
    );
end;

architecture bench of fifo_async_fwft_tb is

    -- OSVMM stuff
    signal SB : ScoreBoardIDType := NewID("FIFO Scoreboard");

    -- Clock period
    constant wr_clk_period : time := 40 ns;
    constant rd_clk_period : time := 10 ns;
    -- Generics
    constant DUAL_CLOCK       : boolean := true;
    constant RELATED_CLOCKS   : boolean := true;
    constant FIFO_WRITE_DEPTH : integer := 16;
    constant WR_DATA_WIDTH    : integer := 8;
    constant RD_DATA_WIDTH    : integer := 8;
    -- Ports
    signal wr_clk  : std_logic := '0';
    signal wr_rst  : std_logic := '1';
    signal wr_vld  : std_logic := '0';
    signal wr_data : std_logic_vector(WR_DATA_WIDTH - 1 downto 0);
    signal wr_rdy  : std_logic;
    signal rd_clk  : std_logic := '0';
    signal rd_rdy  : std_logic := '0';
    signal rd_data : std_logic_vector(RD_DATA_WIDTH - 1 downto 0);
    signal rd_vld  : std_logic;
begin

    fifo_fwft_inst : entity work.fifo_fwft
        generic
        map (
        DUAL_CLOCK       => DUAL_CLOCK,
        RELATED_CLOCKS   => RELATED_CLOCKS,
        FIFO_WRITE_DEPTH => FIFO_WRITE_DEPTH,
        WR_DATA_WIDTH    => WR_DATA_WIDTH,
        RD_DATA_WIDTH    => RD_DATA_WIDTH
        )
        port map
        (
            wr_clk  => wr_clk,
            wr_rst  => wr_rst,
            wr_vld  => wr_vld,
            wr_data => wr_data,
            wr_rdy  => wr_rdy,
            rd_clk  => rd_clk,
            rd_rdy  => rd_rdy,
            rd_data => rd_data,
            rd_vld  => rd_vld
        );
    main : process
        procedure write_byte(byte : std_logic_vector(7 downto 0)) is
        begin
            info("Writing byte 0x" & to_hstring(byte));
            wr_vld  <= '1';
            wr_data <= byte;
            wait until wr_rdy = '1' and rising_edge(wr_clk);
            push(SB, byte); -- push expected data onto OSVVM Scoreboard
            wr_vld <= '0';
        end procedure;

    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("test_alive") then

                wait for 20 * wr_clk_period;
                wr_rst <= '0';

                info("Wait for reset to complete");

                write_byte(x"11");
                write_byte(x"23");

                wait for 100 ns;

                write_byte(x"55");

                for i in 0 to 50 loop
                    write_byte(std_logic_vector(to_unsigned(i, 8)));
                end loop;
                write_byte(x"ff");
                wait for 100 * wr_clk_period;
                test_runner_cleanup(runner);

            end if;
        end loop;
    end process main;
test_runner_watchdog(runner, 10 us);

-- allow the FIFO to hit full before we start reading out
rd_rdy <= '1' after 2 us;
-- rd_rdy <= '1';

    -- Check using OSVVM Scoreboard
    check_proc : process is
        variable sb_data : std_logic_vector(7 downto 0);
    begin
        wait until rd_vld = '1' and rd_rdy = '1' and rising_edge(rd_clk);
        info("Read byte 0x" & to_hstring(rd_data));
        Pop(SB, sb_data); -- OSVVM Check fails not picked up by VUnit, so pop expected data off scoreboard
        check_equal(rd_data, sb_data);
    end process;
    wr_clk <= not wr_clk after wr_clk_period/2;
    rd_clk <= not rd_clk after rd_clk_period/2;

end;