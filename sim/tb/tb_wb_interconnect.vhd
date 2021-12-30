library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
use vunit_lib.bus_master_pkg.all;

entity tb_wb_interconnect is
    generic (runner_cfg : string);
end;

architecture bench of tb_wb_interconnect is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant G_NUM_SLAVES : integer := 15;

    -- Ports
    signal wb_clk            : std_logic;
    signal wb_reset          : std_logic := '0';
    signal wb_master_mosi    : t_wb_mosi;
    signal wb_master_miso    : t_wb_miso;
    signal wb_slave_mosi_arr : t_wb_mosi_arr(G_NUM_SLAVES - 1 downto 0);
    signal wb_slave_miso_arr : t_wb_miso_arr(G_NUM_SLAVES - 1 downto 0);

    -- signal cmd_req           : std_logic;
    -- signal rsp_rdata         : std_logic;

    -- VUnit Jazz (see vunit tb_wishbone_master example)
    constant tb_logger     : logger_t     := get_logger("tb");
    constant master_logger : logger_t     := get_logger("master");
    constant tb_checker    : checker_t    := new_checker("tb");
    constant bus_handle    : bus_master_t := new_bus(data_length => 32,
    address_length => 32, logger => master_logger);
    constant strobe_high_probability : real := 0.5; -- what does this do?
begin
    -- DUT
    wb_interconnect_inst : entity work.wb_interconnect
        generic map(
            G_NUM_SLAVES => G_NUM_SLAVES
        )
        port map(
            wb_clk                => wb_clk,
            wb_reset              => wb_reset,
            wb_master_mosi_in     => wb_master_mosi,
            wb_master_miso_out    => wb_master_miso,
            wb_slave_mosi_arr_out => wb_slave_mosi_arr,
            wb_slave_miso_arr_in  => wb_slave_miso_arr
        );

    vunit_wishbone_master_inst : entity vunit_lib.wishbone_master
        generic map(
            bus_handle              => bus_handle,
            strobe_high_probability => strobe_high_probability
        )
        port map(
            clk   => wb_clk,
            adr   => wb_master_mosi.adr,
            dat_i => wb_master_miso.rdat,
            dat_o => wb_master_mosi.wdat,
            sel   => wb_master_mosi.sel,
            cyc   => wb_master_mosi.cyc,
            stb   => wb_master_mosi.stb,
            we    => wb_master_mosi.we,
            stall => wb_master_miso.stall,
            ack   => wb_master_miso.ack
        );
gen_slaves : for i in 0 to G_NUM_SLAVES-1 generate
    u_slave : entity work.wb_sp_bram
        generic map(
            G_MEM_DEPTH_WORDS => 8,
            G_INIT_FILE       => ""
        )
        port map(
            wb_clk      => wb_clk,
            wb_reset    => wb_reset,
            wb_mosi_in  => wb_slave_mosi_arr(i),
            wb_miso_out => wb_slave_miso_arr(i)
        );
    
end generate;


    main : process
        variable tmp_wdata  : std_logic_vector(wb_master_mosi.wdat'range);
        variable tmp_rdata  : std_logic_vector(wb_master_miso.rdat'range);
        variable tmp_addr   : std_logic_vector(31 downto 0);
        variable slv_offset : integer;

        function get_slv_offset (i : integer) return unsigned is
            variable    u_offset : unsigned(63 downto 0);
            constant    per_slave : unsigned(31 downto 0) := x"1000_0000";
        begin
            u_offset := to_unsigned(i, 32) * per_slave;
            return u_offset(31 downto 0);   -- only return bottom half
        end function;

        function calc_addr(slv, reg : integer) return std_logic_vector is
        begin
            return std_logic_vector(get_slv_offset(slv) + to_unsigned(reg * 4, 32));
        end function;
    begin
        test_runner_setup(runner, runner_cfg);

        -- set up VUnit Logging
        set_format(display_handler, verbose, true);
        show(tb_logger, display_handler, verbose);
        show(default_logger, display_handler, verbose);
        show(master_logger, display_handler, verbose);
        -- show passing assertions for tb_checker
        show(get_logger(tb_checker), display_handler, pass);
        -- continue simulating on error
        set_stop_level(failure);

        while test_suite loop
            if run("Basic Read/Writes") then
                info(tb_logger, "Starting Writes to Slave 0");
                for i in 0 to 7 loop
                    tmp_wdata := uint2slv(i);
                    tmp_addr  := calc_addr(0, i);
                    info(master_logger, "Writing " & to_hstring(tmp_addr) & " to " & to_hstring(tmp_addr));
                    write_bus(net, bus_handle, tmp_addr, tmp_addr);
                end loop;
                info(tb_logger, "Starting Writes to Slave 1");
                for i in 0 to 7 loop
                    tmp_wdata := uint2slv(i);
                    tmp_addr  := calc_addr(1, i);
                    info(master_logger, "Writing " & to_hstring(tmp_addr) & " to " & to_hstring(tmp_addr));
                    write_bus(net, bus_handle, tmp_addr, tmp_addr);
                end loop;
                info(tb_logger, "Starting Reads from Slave 0");
                for i in 0 to 7 loop
                    tmp_addr  := calc_addr(0, i);
                    tmp_rdata := tmp_addr;
                    info(master_logger, "Reading from " & to_hstring(tmp_addr));
                    read_bus(net, bus_handle, tmp_addr, tmp_rdata);
                    check_equal(tb_checker, tmp_rdata, tmp_addr, "Slave 0 read data");
                end loop;
                info(tb_logger, "Starting Reads from Slave 1");
                for i in 0 to 7 loop
                    tmp_addr  := calc_addr(1, i);
                    tmp_rdata := tmp_addr;
                    info(master_logger, "Reading from " & to_hstring(tmp_addr));
                    read_bus(net, bus_handle, tmp_addr, tmp_rdata);
                    check_equal(tb_checker, tmp_rdata, tmp_addr, "Slave 1 read data");
                end loop;
                wait for 10 * clk_period;
                test_runner_cleanup(runner);

            elsif run("Access All Slaves") then
                loop_slaves : for i in 0 to G_NUM_SLAVES - 1 loop
                    info(tb_logger, "Starting Writes to Slave " & to_string(i));
                    loop_writes : for j in 0 to 7 loop
                        -- tmp_wdata := uint2slv(j);
                        tmp_addr  := calc_addr(i, j);
                        info(master_logger, "Writing " & to_hstring(tmp_addr) & " to " & to_hstring(tmp_addr));
                        write_bus(net, bus_handle, tmp_addr, tmp_addr);
                    end loop loop_writes;
                    info(tb_logger, "Starting Reads from Slave " & to_string(i));
                    loop_reads : for j in 0 to 7 loop
                        tmp_addr  := calc_addr(i, j);
                        tmp_rdata := tmp_addr;
                        info(master_logger, "Reading from " & to_hstring(tmp_addr));
                        read_bus(net, bus_handle, tmp_addr, tmp_rdata);
                        check_equal(tb_checker, tmp_rdata, tmp_addr, "Slave " & to_string(i) &  " read data");
                    end loop loop_reads;

                end loop loop_slaves;

                test_runner_cleanup(runner);

            elsif run("Access Unmapped Slave") then
                tmp_wdata := x"C001_C0DE";
                tmp_addr  := calc_addr(0, 1);

                info(tb_logger, "Test Access to mapped Slave 0");
                info(master_logger, "Writing " & to_hstring(tmp_wdata) & " to " & to_hstring(tmp_addr));
                write_bus(net, bus_handle, tmp_addr, tmp_wdata);

                info(master_logger, "Reading from " & to_hstring(tmp_addr));
                read_bus(net, bus_handle, tmp_addr, tmp_rdata);
                check_equal(tb_checker, tmp_rdata, tmp_wdata, "Mapped Slave read data");

                info(tb_logger, "Starting Access to unmapped Slave F");
                tmp_addr := calc_addr(15, 0);
                info(master_logger, "Writing " & to_hstring(tmp_wdata) & " to " & to_hstring(tmp_addr));
                -- we expect to never get an ACK fron this write, just an ERR (which the default VUnit bus master does not handle)
                write_bus(net, bus_handle, tmp_addr, tmp_wdata);

                wait until wb_master_mosi.cyc = '1'; -- wait for write cycle to start before we check for an error
                wait for 1 ns;
                check_equal(tb_checker, wb_master_miso.err, '1', "Check that we have an ERR");

                -- info(master_logger, "Reading from " & to_hstring(tmp_addr));
                -- read_bus(net, bus_handle, tmp_addr, tmp_rdata);
                -- check_equal(tb_checker, tmp_rdata, tmp_addr, "Unmapped Slave read data");
                tmp_wdata := x"DABE_EFEE";
                tmp_addr  := calc_addr(1, 1);
                info(tb_logger, "Test Access to mapped Slave 1");
                info(master_logger, "Writing " & to_hstring(tmp_wdata) & " to " & to_hstring(tmp_addr));
                write_bus(net, bus_handle, tmp_addr, tmp_wdata);

                -- unfortunately the VUnit WB master can't handle ERROR responses, so the message queue is all messed up and we
                -- can't verify the write (need to check manually)

                -- info(master_logger, "Reading from " & to_hstring(tmp_addr));
                -- read_bus(net, bus_handle, tmp_addr, tmp_rdata);
                -- check_equal(tb_checker, tmp_rdata, tmp_wdata, "Mapped Slave read data");

                wait for 10 * clk_period;
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