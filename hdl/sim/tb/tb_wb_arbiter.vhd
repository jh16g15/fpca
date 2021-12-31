library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all;
--

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_wb_arbiter is
    generic (runner_cfg : string);
end;

architecture bench of tb_wb_arbiter is

    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant G_ARBITER : string := "simple";

    -- Ports
    signal wb_clk             : std_logic;
    signal wb_reset           : std_logic := '0';
    signal wb_master_0_mosi   : t_wb_mosi;
    signal wb_master_0_miso   : t_wb_miso;
    signal wb_master_1_mosi   : t_wb_mosi;
    signal wb_master_1_miso   : t_wb_miso;
    signal wb_master_sel_mosi : t_wb_mosi;
    signal wb_master_sel_miso : t_wb_miso;

    signal cmd_req_0 : std_logic := '1';
    signal cmd_req_1 : std_logic := '1';

    signal rsp_rdata_0 : std_logic_vector(31 downto 0);
    signal rsp_rdata_1 : std_logic_vector(31 downto 0);
    
begin

    wb_arbiter_inst : entity work.wb_arbiter
        generic map(
            G_ARBITER => G_ARBITER
        )
        port map(
            wb_clk                 => wb_clk,
            wb_reset               => wb_reset,
            wb_master_0_mosi_in    => wb_master_0_mosi,
            wb_master_0_miso_out   => wb_master_0_miso,
            wb_master_1_mosi_in    => wb_master_1_mosi,
            wb_master_1_miso_out   => wb_master_1_miso,
            wb_master_sel_mosi_out => wb_master_sel_mosi,
            wb_master_sel_miso_in  => wb_master_sel_miso
        );

    -- two wishbone masters
    wb_master_0 : entity work.wb_master
        port map(
            wb_clk               => wb_clk,
            wb_reset             => wb_reset,
            wb_mosi_out          => wb_master_0_mosi,
            wb_miso_in           => wb_master_0_miso,
            cmd_addr_in          => x"0000_0010",
            cmd_wdata_in         => x"3333_3333",
            cmd_sel_in           => x"F",
            cmd_we_in            => '1',
            cmd_req_in           => cmd_req_0,
            cmd_stall_out        => open,
            cmd_unsigned_flag_in => '0',
            rsp_rdata_out        => rsp_rdata_0,
            rsp_valid_out        => open,
            rsp_err_out          => open
        );
    -- two wishbone masters
    wb_master_1 : entity work.wb_master
        port map(
            wb_clk               => wb_clk,
            wb_reset             => wb_reset,
            wb_mosi_out          => wb_master_1_mosi,
            wb_miso_in           => wb_master_1_miso,
            cmd_addr_in          => x"0000_0010",
            cmd_wdata_in         => x"1111_1111",
            cmd_sel_in           => x"F",
            cmd_we_in            => '1',
            cmd_req_in           => cmd_req_1,
            cmd_stall_out        => open,
            cmd_unsigned_flag_in => '0',
            rsp_rdata_out        => rsp_rdata_1,
            rsp_valid_out        => open,
            rsp_err_out          => open
        );
    -- a single wishbone slave
    wb_sp_bram_inst : entity work.wb_sp_bram
        generic map(
            G_MEM_DEPTH_WORDS => 32,
            G_INIT_FILE       => ""
        )
        port map(
            wb_clk      => wb_clk,
            wb_reset    => wb_reset,
            wb_mosi_in  => wb_master_sel_mosi,
            wb_miso_out => wb_master_sel_miso
        );
    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("test_alive") then
                info("Hello world test_alive");

                wait for 100 * clk_period;

                test_runner_cleanup(runner);

            end if;
        end loop;
    end process main;

    clk_process : process
    begin
        wb_clk <= '1';
        wait for clk_period/2;
        wb_clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;