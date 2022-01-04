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

entity tb_wb_uart_simple is
    generic (runner_cfg : string);
end;

architecture bench of tb_wb_uart_simple is
    -- Clock period
    constant clk_period : time := 10 ns;
    -- Generics
    constant DEFAULT_BAUD : integer := 9600;
    constant REFCLK_FREQ  : integer := 100_000_000;

    -- Ports
    signal wb_clk      : std_logic;
    signal wb_reset    : std_logic;
    signal wb_mosi     : t_wb_mosi;
    signal wb_miso     : t_wb_miso;
    signal uart_tx_out : std_logic;
    signal uart_rx_in  : std_logic;

    -- Vunit
    constant tb_logger     : logger_t     := get_logger("tb");
    constant master_logger : logger_t     := get_logger("master");
    constant tb_checker    : checker_t    := new_checker("tb");
    constant bus_handle    : bus_master_t := new_bus(data_length => 32,
    address_length => 32, logger => master_logger);
    constant strobe_high_probability : real := 0.5; -- what does this do?

begin

    wb_uart_simple_inst : entity work.wb_uart_simple
        generic map(
            DEFAULT_BAUD => DEFAULT_BAUD,
            REFCLK_FREQ  => REFCLK_FREQ
        )
        port map(
            wb_clk      => wb_clk,
            wb_reset    => wb_reset,
            wb_mosi_in  => wb_mosi,
            wb_miso_out => wb_miso,
            uart_tx_out => uart_tx_out,
            uart_rx_in  => uart_rx_in
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
        variable tmp_addr                : std_logic_vector(31 downto 0);
        variable tmp_rdata               : std_logic_vector(wb_miso.rdat'range);
        variable tmp_wdata               : std_logic_vector(wb_mosi.wdat'range);
        constant UART_BYTE_TRANSMIT_ADDR : std_logic_vector(31 downto 0) := x"0000_0000";
        constant UART_TX_STATUS_ADDR     : std_logic_vector(31 downto 0) := x"0000_0004";
        constant UART_DIVISOR_ADDR       : std_logic_vector(31 downto 0) := x"0000_0008";

        variable uart_tx_idle : std_logic;

        procedure wait_for_uart_tx_idle is
        begin
            uart_tx_idle := '0';
            info(master_logger, "Polling from UART TX Status until TX_IDLE ");
            -- wait until TX IDLE
            while uart_tx_idle = '0' loop
                read_bus(net, bus_handle, UART_TX_STATUS_ADDR, tmp_rdata);
                uart_tx_idle := tmp_rdata(0);
            end loop;
            info(tb_logger, "UART now idle");
        end procedure;

        procedure uart_send_byte(byte : std_logic_vector(7 downto 0)) is
        begin
            tmp_wdata := x"0000_00" & byte;
            info(master_logger, "Writing " & to_hstring(tmp_wdata) & " to UART BYTE TX " & to_hstring(UART_BYTE_TRANSMIT_ADDR));
            write_bus(net, bus_handle, UART_BYTE_TRANSMIT_ADDR, tmp_wdata);
        end procedure;

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

        wb_reset <= '1';
        wait for 15 ns;
        wb_reset <= '0';

        while test_suite loop
            if run("test_alive") then
                info("Hello world test_alive");

                wait_for_uart_tx_idle;
                uart_send_byte(x"FF");

                wait_for_uart_tx_idle;
                uart_send_byte(x"00");

                wait_for_uart_tx_idle;
                uart_send_byte(x"55");

                wait_for_uart_tx_idle;
                uart_send_byte(x"AA");

                wait_for_uart_tx_idle;

                wait for 10 * clk_period;
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