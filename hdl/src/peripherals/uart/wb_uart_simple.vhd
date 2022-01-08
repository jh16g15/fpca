library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

entity wb_uart_simple is
    generic (
        DEFAULT_BAUD : integer := 9600;
        REFCLK_FREQ  : integer := 100_000_000
    );
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_in  : in t_wb_mosi;
        wb_miso_out : out t_wb_miso;

        uart_tx_out : out std_logic;
        uart_rx_in  : in std_logic
    );
end entity wb_uart_simple;

architecture rtl of wb_uart_simple is
    --! Register Map
    --! x0  WO  Write the bottom byte of this register to send a byte
    signal uart_byte_transmit_register : std_logic_vector(31 downto 0);
    --! x4  RO  See the UART Transmit status (bit 0 = BUSY)
    signal uart_status_tx_register : std_logic_vector(31 downto 0);
    --! x8  RW  Set the baud rate using a programmable divisor
    signal uart_ctrl_divisor_register : std_logic_vector(31 downto 0);
    --! xC  RO  Read the bottom byte of this register to read a byte
    signal uart_byte_receive_register : std_logic_vector(31 downto 0) := x"0000_0000";
    --! x10  RO  See the UART Receive status (bit 0 = VALID)
    signal uart_status_rx_register : std_logic_vector(31 downto 0);

    constant INIT_DIVISOR : integer   := REFCLK_FREQ / DEFAULT_BAUD;
    signal tx_byte_valid  : std_logic := '0';

    signal uart_tx_ready : std_logic;

    signal uart_byte_received : std_logic_vector(7 downto 0);
    signal uart_rx_byte_ack   : std_logic; -- ACK the received byte
    signal uart_rx_valid      : std_logic;

begin

    -- this slave can always respond to requests, so no stalling is required
    -- potentially we could stall if the UART TX is busy, but that would lock up the
    -- wishbone bus in the meantime.

    -- Later we will want to use a Tx FIFO to allow sending bursts of data
    -- We will definitely need an Rx FIFO, as we can't guarentee to read the UART Rx data fast enough otherwise
    -- (could be handled with a handshaking protocol between devices)
    wb_miso_out.stall <= '0';
    -- wishbone slave logic
    wb_proc : process (wb_clk) is
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                wb_miso_out.ack <= '0';
                wb_miso_out.err <= '0';
                wb_miso_out.rty <= '0';

                -- reset writeable registers
                uart_byte_transmit_register <= x"0000_0000";
                uart_ctrl_divisor_register  <= uint2slv(INIT_DIVISOR);
                uart_status_tx_register     <= x"0000_0000"; -- bit 0 is Tx IDLE
                tx_byte_valid               <= '0';
                uart_status_rx_register     <= x"0000_0000"; -- bit 0 is Rx VALID

            else
                -- defaults
                wb_miso_out.ack  <= '0';
                wb_miso_out.err  <= '0'; -- this slave does not generate ERR or RTY responses
                wb_miso_out.rty  <= '0';
                wb_miso_out.rdat <= x"DEADC0DE";

                uart_rx_byte_ack <= '0';

                if wb_mosi_in.stb = '1' and wb_miso_out.stall = '0' then -- assume CYC asserted by master for STB to be high
                    -- always ACK this cycle (sync operation with 1 wait state)
                    wb_miso_out.ack <= '1';
                    if wb_mosi_in.we = '1' then
                        -- write logic
                        case(wb_mosi_in.adr(3 downto 0)) is
                            when x"0" =>
                            uart_byte_transmit_register <= wb_mosi_in.wdat;
                            tx_byte_valid               <= '1';
                            when x"8" =>
                            uart_ctrl_divisor_register <= wb_mosi_in.wdat;
                            when others => null;
                        end case;
                    else
                        -- read logic
                        case(wb_mosi_in.adr(7 downto 0)) is
                            when x"00" => wb_miso_out.rdat <= uart_byte_transmit_register;
                            when x"04" => wb_miso_out.rdat <= uart_status_tx_register;
                            when x"08" => wb_miso_out.rdat <= uart_ctrl_divisor_register;

                            -- read this rdata register and tell the RX UART that we have read it successfully
                            when x"0C" =>
                            wb_miso_out.rdat <= uart_byte_receive_register;
                            uart_rx_byte_ack <= '1'; -- will be set back to 0 by default on next cycle

                            when x"10"  => wb_miso_out.rdat <= uart_status_rx_register;
                            when others => null;
                        end case;

                    end if;
                end if;

                -- handshake the tx_byte_valid
                if tx_byte_valid = '1' and uart_tx_ready = '1' then
                    tx_byte_valid <= '0';
                end if;
                uart_status_tx_register(0) <= uart_tx_ready;
                uart_status_rx_register(0) <= uart_rx_valid;

                uart_byte_receive_register(7 downto 0) <= uart_byte_received;
            end if; -- end clk'd
        end if;
    end process;

    jh_uart_tx_inst : entity work.jh_uart_tx
        generic map(
            REFCLK_FREQ => REFCLK_FREQ
        )
        port map(
            refclk_in           => wb_clk,
            reset_in            => wb_reset,
            divisor_in          => uart_ctrl_divisor_register,
            uart_tx_out         => uart_tx_out,
            byte_to_transmit_in => uart_byte_transmit_register(7 downto 0),
            uart_tx_valid_in    => tx_byte_valid,
            uart_tx_ready_out   => uart_tx_ready
        );

    jh_uart_rx_inst : entity work.jh_uart_rx
        generic map(
            REFCLK_FREQ => REFCLK_FREQ
        )
        port map(
            refclk_in         => wb_clk,
            reset_in          => wb_reset,
            divisor_in        => uart_ctrl_divisor_register,
            uart_rx_in        => uart_rx_in,
            byte_received_out => uart_byte_received,
            uart_rx_valid_out => uart_rx_valid,
            uart_rx_ready_in  => uart_rx_byte_ack, -- ACK read byte
            uart_rx_error     => open
        );
end architecture;