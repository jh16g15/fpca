library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

--
library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.bus_master_pkg.all;

entity tb_wb_regs is
    generic (runner_cfg : string);
end;

architecture bench of tb_wb_regs is
    -- Clock period
    signal clk : std_logic;
    constant clk_period : time := 5 ns;
    -- Generics
    constant G_NUM_RW_REGS : integer := 4;
    constant G_NUM_RO_REGS : integer := 4;

    -- Ports
    signal wb_clk      : std_logic;
    signal wb_reset    : std_logic := '0';
    signal wb_mosi     : t_wb_mosi;
    signal wb_miso     : t_wb_miso;
    signal rw_regs_out : t_slv32_arr(G_NUM_RW_REGS - 1 downto 0);
    signal ro_regs_in  : t_slv32_arr(G_NUM_RO_REGS - 1 downto 0);

    constant tb_logger : logger_t := get_logger("tb");
    constant master_logger : logger_t := get_logger("master");

    -- VUnit Jazz (see vunit tb_wishbone_master)
    constant bus_handle : bus_master_t := new_bus(data_length => 32,
    address_length => 32, logger => master_logger);

    constant strobe_high_probability : real := 0.5; -- what does this do?
begin

    wb_clk <= clk;

    ro_regs_in(0) <= x"0000_0000";
    ro_regs_in(1) <= x"1111_1111";
    ro_regs_in(2) <= x"2222_2222";
    ro_regs_in(3) <= x"3333_3333";

    wb_regs_inst : entity work.wb_regs
        generic map(
            G_NUM_RW_REGS => G_NUM_RW_REGS,
            G_NUM_RO_REGS => G_NUM_RO_REGS
        )
        port map(
            wb_clk      => wb_clk,
            wb_reset    => wb_reset,
            wb_mosi_in  => wb_mosi,
            wb_miso_out => wb_miso,
            rw_regs_out => rw_regs_out,
            ro_regs_in  => ro_regs_in
        );

    vunit_wishbone_master_inst : entity vunit_lib.wishbone_master
        generic map(
            bus_handle              => bus_handle,
            strobe_high_probability => strobe_high_probability
        )
        port map(
            clk   => wb_clk,
            adr   => wb_mosi.adr,
            dat_i => wb_miso.rdat,
            dat_o => wb_mosi.wdat,
            sel   => wb_mosi.sel,
            cyc   => wb_mosi.cyc,
            stb   => wb_mosi.stb,
            we    => wb_mosi.we,
            stall => wb_miso.stall,
            ack   => wb_miso.ack
        );

    main : process
        variable tmp_wdata : std_logic_vector(wb_mosi.wdat'range);
        variable tmp_rdata : std_logic_vector(wb_miso.rdat'range);

        constant adr_rw0   : std_logic_vector :=  x"000";
        constant adr_rw1   : std_logic_vector := x"001";
        constant adr_rw2   : std_logic_vector := x"002";
        constant adr_rw3   : std_logic_vector := x"003";
        
        constant adr_ro0   : std_logic_vector := x"100";
        constant adr_ro1   : std_logic_vector := x"101";
        constant adr_ro2   : std_logic_vector := x"102";
        constant adr_ro3   : std_logic_vector := x"103";
    begin
        test_runner_setup(runner, runner_cfg);
        -- VUnit logging setup
        set_format(display_handler, verbose, true);
        show(tb_logger, display_handler, verbose);
        show(default_logger, display_handler, verbose);
        show(master_logger, display_handler, verbose);
        -- show(com_logger, display_handler, verbose);
        -- show passing assertions
        -- show(get_logger(default_checker), display_handler, pass);

        wait until rising_edge(wb_clk);
        wb_reset <= '0';

        while test_suite loop
            if run("test") then
                info(tb_logger, "Starting test, writing to RW...");
                tmp_wdata := x"C001C0DE";
                write_bus(net, bus_handle, x"000", tmp_wdata);
                wait until wb_miso.ack = '1' and rising_edge(clk);
                wait until rising_edge(clk);

                info(tb_logger, "now try to readback the same address");
                read_bus(net, bus_handle, x"000", tmp_rdata);
                check_equal(tmp_rdata, tmp_wdata, "read data");

                info(tb_logger, "Read from RO");
                read_bus(net, bus_handle, x"100", tmp_rdata);
                check_equal(tmp_rdata, std_logic_vector'(x"0000_0000"), "read data");

                read_bus(net, bus_handle, x"104", tmp_rdata);
                -- wait until wb_miso.ack = '1' and rising_edge(clk);
                check_equal(tmp_rdata, std_logic_vector'(x"1111_1111"), "read data");

                read_bus(net, bus_handle, x"108",tmp_rdata);
                -- wait until wb_miso.ack = '1' and rising_edge(clk);
                check_equal(tmp_rdata, std_logic_vector'(x"2222_2222"), "read data");

                read_bus(net, bus_handle, x"10C", tmp_rdata);
                -- wait until wb_miso.ack = '1' and rising_edge(clk);
                check_equal(tmp_rdata, std_logic_vector'(x"3333_3333"), "read data");

                
            end if;
        end loop;

        test_runner_cleanup(runner);
    end process main;

    test_runner_watchdog(runner, 10 us);

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;