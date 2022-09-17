library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.axi_pkg.all;
use work.joe_common_pkg.all;

--
library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;
context vunit_lib.com_context;

entity tb_wb_to_axi3_shim is
    generic (runner_cfg : string);
end;

architecture bench of tb_wb_to_axi3_shim is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics

    -- Ports
    signal wb_clk            : std_logic;
    signal wb_reset          : std_logic := '0';
    signal wb_mosi           : t_wb_mosi;
    signal wb_miso           : t_wb_miso;
    signal cmd_addr          : std_logic_vector(C_WB_ADDR_W - 1 downto 0);
    signal cmd_wdata         : std_logic_vector(C_WB_DATA_W - 1 downto 0);
    signal cmd_sel           : std_logic_vector(C_WB_SEL_W - 1 downto 0);
    signal cmd_we            : std_logic;
    signal cmd_req           : std_logic;
    signal cmd_unsigned_flag : std_logic;
    signal cmd_stall         : std_logic;
    signal cmd_sign_ext      : std_logic;
    signal rsp_rdata         : std_logic_vector(C_WB_DATA_W - 1 downto 0);
    signal rsp_valid         : std_logic;
    signal rsp_err           : std_logic;
    signal axi_mosi          : t_axi_mosi;
    signal axi_miso          : t_axi_miso;

    signal done : std_logic;

begin

    cmd_driver_inst : entity work.cmd_driver
        generic map(
            G_SEVERITY => error
        )
        port map(
            clk                   => wb_clk,
            reset                 => wb_reset,
            done                  => done,
            cmd_addr_out          => cmd_addr,
            cmd_wdata_out         => cmd_wdata,
            cmd_sel_out           => cmd_sel,
            cmd_we_out            => cmd_we,
            cmd_req_out           => cmd_req,
            cmd_unsigned_flag_out => cmd_unsigned_flag,
            cmd_stall_in          => cmd_stall,
            rsp_rdata_in          => rsp_rdata,
            rsp_valid_in          => rsp_valid,
            rsp_err               => rsp_err
        );

    wb_master_inst : entity work.wb_master
        port map(
            wb_clk               => wb_clk,
            wb_reset             => wb_reset,
            wb_mosi_out          => wb_mosi,
            wb_miso_in           => wb_miso,
            cmd_addr_in          => cmd_addr,
            cmd_wdata_in         => cmd_wdata,
            cmd_sel_in           => cmd_sel,
            cmd_we_in            => cmd_we,
            cmd_req_in           => cmd_req,
            cmd_stall_out        => cmd_stall,
            cmd_unsigned_flag_in => cmd_unsigned_flag,
            rsp_rdata_out        => rsp_rdata,
            rsp_valid_out        => rsp_valid,
            rsp_err_out          => rsp_err
        );

    wb_to_axi3_shim_inst : entity work.wb_to_axi3_shim
        port map(
            wb_clk       => wb_clk,
            wb_reset     => wb_reset,
            wb_mosi_in   => wb_mosi,
            wb_miso_out  => wb_miso,
            axi_mosi_out => axi_mosi,
            axi_miso_in  => axi_miso
        );

    vunit_axi_slave_inst : entity work.vunit_axi_slave
        generic map(G_BASE_ADDR => x"0000_0000", G_BYTES => 512)
        port map(
            axi_clk  => wb_clk,
            axi_mosi => axi_mosi,
            axi_miso => axi_miso
        );
    main : process
        variable buf : buffer_t;
    begin
        test_runner_setup(runner, runner_cfg);
        show(get_logger(default_checker), display_handler, pass); -- show passing assertions
        while test_suite loop
            if run("test wb to AXI3 converter") then
                info("Hello world test_alive");

                cmd_sign_ext <= '0';
                wb_reset     <= '1';
                wait for 2 * clk_period;
                wb_reset <= '0';
                wait until done;
                test_runner_cleanup(runner);

            end if;
        end loop;
    end process main;

    test_runner_watchdog(runner, 10 us);

    clk_process : process
    begin
        wb_clk <= '1';
        wait for clk_period/2;
        wb_clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;