library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi_pkg.all;
use work.joe_common_pkg.all;
--
library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

entity tb_dma_axi3_read is
    generic (runner_cfg : string);
end;

architecture bench of tb_dma_axi3_read is
    signal mem : memory_t; -- get from vunit_axi_slave

    constant MEM_WORDS : integer := 2048;

    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics

    -- Ports
    signal clk                   : std_logic;
    signal axi_reset             : std_logic;
    signal dma_start_in          : std_logic;
    signal dma_done_out          : std_logic;
    signal dma_start_addr_in     : std_logic_vector(31 downto 0);
    signal dma_axi_burst_mode_in : std_logic_vector(1 downto 0);
    signal dma_num_words_in      : std_logic_vector(31 downto 0);
    signal dma_queue_limit_in    : std_logic_vector(31 downto 0);
    signal dma_stall_in          : std_logic;
    signal dma_axi_hp_mosi_out   : t_axi_mosi;
    signal dma_axi_hp_miso_in    : t_axi_miso;
    signal axi_stream_mosi_out   : t_axi_stream32_mosi;
    signal axi_stream_miso_in    : t_axi_stream32_miso;

begin

    dma_axi3_read_inst : entity work.dma_axi3_read
        port map(
            axi_clk               => clk,
            axi_reset             => axi_reset,
            dma_start_in          => dma_start_in,
            dma_done_out          => dma_done_out,
            dma_start_addr_in     => dma_start_addr_in,
            dma_axi_burst_mode_in => dma_axi_burst_mode_in,
            dma_num_words_in      => dma_num_words_in(15 downto 0),
            dma_queue_limit_in    => dma_queue_limit_in,
            dma_stall_in          => dma_stall_in,
            dma_axi_hp_mosi_out   => dma_axi_hp_mosi_out,
            dma_axi_hp_miso_in    => dma_axi_hp_miso_in,
            axi_stream_mosi_out   => axi_stream_mosi_out,
            axi_stream_miso_in    => axi_stream_miso_in
        );

    vunit_axi_slave_inst : entity work.vunit_axi_slave
        generic map(G_NAME => "DDR3", G_BASE_ADDR => x"0000_0000", G_BYTES => MEM_WORDS * 4, G_DEBUG_PRINT => false)
        port map(
            axi_clk        => clk,
            axi_mosi       => dma_axi_hp_mosi_out,
            axi_miso       => dma_axi_hp_miso_in,
            memory_ref_out => mem
        );

    check_proc : process (clk)
        variable count : integer := 0;
    begin
        if rising_edge(clk) then
            if axi_reset = '1' then
                count := 0;
            else
                if axi_stream_miso_in.tready = '1' and axi_stream_mosi_out.tvalid = '1' then
                    check_equal(axi_stream_mosi_out.tdata, uint2slv(count), "rdata check");
                    count := count + 1;
                end if;
            end if;
        end if;
    end process;

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        show(get_logger(default_checker), display_handler, pass);
        while test_suite loop
            axi_reset             <= '1';
            dma_start_in          <= '0';
            dma_start_addr_in     <= x"0000_0000";
            dma_axi_burst_mode_in <= AXI_BURST_INCR;
            dma_stall_in          <= '0';

            axi_stream_miso_in.tready <= '1';

            -- set up intial contents
            for i in 0 to MEM_WORDS - 1 loop
                write_integer(mem, address => i * 4, word => i);
            end loop;

            if run("64 words queue depth 1") then
                dma_num_words_in   <= uint2slv(64);
                dma_queue_limit_in <= uint2slv(1);
                info("Starting 64 words queue depth 1");

            elsif run("64 words queue depth 2") then
                dma_num_words_in   <= uint2slv(64);
                dma_queue_limit_in <= uint2slv(2);
                info("Starting 64 words queue depth 2");
            elsif run("64 words queue depth 4") then
                dma_num_words_in   <= uint2slv(64);
                dma_queue_limit_in <= uint2slv(4);
                info("Starting 64 words queue depth 4");
            elsif run("35 words queue depth 2") then
                dma_num_words_in   <= uint2slv(35);
                dma_queue_limit_in <= uint2slv(2);
                info("Starting 35 words queue depth 2");
            end if;

            info("num bytes allocated in Vunit memory model : " & to_string(num_bytes(mem)));
            wait for 10 * clk_period;
            axi_reset <= '0';
            wait for 10 * clk_period;
            dma_start_in <= '1';
            wait for 1 * clk_period;
            dma_start_in <= '0';
            wait until dma_done_out = '1';
            wait for 10 * clk_period;

            test_runner_cleanup(runner);
        end loop;
    end process main;

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;