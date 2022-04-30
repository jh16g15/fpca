library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_wb_psram_simple is
    generic (runner_cfg : string);
end;

architecture bench of tb_wb_psram_simple is
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

    constant G_BURST_LEN : integer := 16;
    constant G_MEMCLK_PERIOD : time := 10 ns;
    constant G_DATA_W : integer := 32;
    constant G_PSRAM_ADDR_W : integer := 21;  -- of PSRAM (21 bits for 8MB?)
    constant G_MEM_DEPTH : integer := 32;   -- for simulating with a smaller memory to reduce sim time
    constant C_INIT_DELAY : integer := 10;
    constant C_READ_DELAY : integer := 10;

    -- PSRAM IP interface
    signal wr_data : std_logic_vector(G_DATA_W-1 downto 0);
    signal rd_data :  std_logic_vector(G_DATA_W-1 downto 0);
    signal rd_data_valid : std_logic;
    signal addr : std_logic_vector(G_PSRAM_ADDR_W-1 downto 0);
    signal cmd : std_logic;
    signal cmd_en : std_logic;
    signal init_calib : std_logic;
    signal clk : std_logic;     --! output clock 1/2 memclk
    signal data_mask: std_logic_vector(G_DATA_W/8-1 downto 0);

    -- Clock period
    constant clk_period : time := G_MEMCLK_PERIOD * 2;

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


    wb_psram_simple_inst : entity work.wb_psram_simple
        generic map (
          G_BURST_LEN => G_BURST_LEN,
          G_PSRAM_ADDR_W => G_PSRAM_ADDR_W
        )
        port map (
          wb_clk => wb_clk,
          wb_reset => wb_reset,
          wb_mosi_in => wb_mosi,
          wb_miso_out => wb_miso,
          wdata_out => wr_data,
          data_mask_out => data_mask,
          rdata_in => rd_data,
          rd_data_valid_in => rd_data_valid,
          addr_out => addr,
          cmd_out => cmd,
          cmd_en_out => cmd_en,
          init_calib_in => init_calib
        );

    sim_psram_inst : entity work.sim_psram
    generic map (
        G_BURST_LEN => G_BURST_LEN,
        G_MEMCLK_PERIOD => G_MEMCLK_PERIOD,
        G_DATA_W => G_DATA_W,
        G_PSRAM_ADDR_W => G_PSRAM_ADDR_W,
        G_MEM_DEPTH => G_MEM_DEPTH,
        C_INIT_DELAY => C_INIT_DELAY,
        C_READ_DELAY => C_READ_DELAY
    )
    port map (
        rst_n => not wb_reset,
        wr_data => wr_data,
        rd_data => rd_data,
        rd_data_valid => rd_data_valid,
        addr => addr,
        cmd => cmd,
        cmd_en => cmd_en,
        init_calib => init_calib,
        clk_out => wb_clk,
        data_mask => data_mask
    );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        show(get_logger(default_checker), display_handler, pass); -- show passing assertions
        while test_suite loop
            if run("test_master_with_bram") then
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


end;