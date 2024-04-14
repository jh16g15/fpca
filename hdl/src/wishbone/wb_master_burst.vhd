library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all; -- 32 bit port, 8 bit granularity

--! A simple wishbone master that can read and write to a 32-bit Wishbone bus, in bytesize
--! chunks
--!
--! Supports Single and Burst Transactions (B4 pipelined).
--! No explicit burst length provided, just keeps the burst going until no queued command, or max size reached
--!
--! Warning! Misaligned memory accesses will fail invisibly! (FIXME)
entity wb_master_burst is
    generic (
        G_MAX_BURST_TRANSFERS : integer := 8 -- 4 bytes per transfer
    );
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_out : out t_wb_mosi;
        wb_miso_in  : in t_wb_miso;

        -- command bus
        cmd_addr_in          : in std_logic_vector(C_WB_ADDR_W - 1 downto 0);
        cmd_wdata_in         : in std_logic_vector(C_WB_DATA_W - 1 downto 0);
        cmd_sel_in           : in std_logic_vector(C_WB_SEL_W - 1 downto 0); --! positions of read/write data
        cmd_we_in            : in std_logic;
        cmd_valid_in           : in std_logic;
        cmd_ready_out        : out std_logic;

        -- response bus
        rsp_rdata_out : out std_logic_vector(C_WB_DATA_W - 1 downto 0);
        rsp_valid_out : out std_logic;
        -- rsp_stall     : in std_logic;    -- RDATA backpressure not implemented
        rsp_err_out : out std_logic
    );
end entity;

architecture rtl of wb_master_burst is
    signal cmd_ready : std_logic := '0';
    signal wb_cyc    : std_logic := '0';
    signal wb_stb    : std_logic := '0';

    type t_state is (WB_IDLE, WB_REQ_BURST, WB_RSP_WAIT);
    signal state : t_state := WB_IDLE;

    signal burst_done : std_logic;
    signal req_counter : integer range 0 to G_MAX_BURST_TRANSFERS;
    signal rsp_counter : integer range 0 to G_MAX_BURST_TRANSFERS;


begin
    cmd_ready_out <= cmd_ready;

    wb_mosi_out.cyc <= wb_cyc;
    wb_mosi_out.stb <= wb_stb;

    -- handle responses straight off the bus

    rsp_valid_out <= wb_miso_in.ack or wb_miso_in.err;
    rsp_err_out   <= wb_miso_in.err;


    -- cmd_ready <= not wb_miso_in.stall;


    process (wb_clk)
    begin
        if rising_edge(wb_clk) then

            cmd_ready <= '0'; -- default don't ACK CMD
            burst_done <= '0'; -- for 1-cycle pulse

            if wb_reset = '1' then
                state     <= WB_IDLE;
                -- cmd_ready <= '0';
            else

                -- LOGIC FOR CMD STREAM, accept when VALID and READY
                if cmd_valid_in = '1' and cmd_ready = '1' then

                    wb_stb    <= '1';
                    wb_mosi_out.adr    <= cmd_addr_in(C_WB_ADDR_W-1 downto 2) & b"00";  -- force 32 bit aligned addresses
                    wb_mosi_out.sel    <= cmd_sel_in;
                    wb_mosi_out.we     <= cmd_we_in;
                    wb_mosi_out.wdat   <= cmd_wdata_in;
                    req_counter <= req_counter + 1;
                end if;

                if wb_miso_in.ack = '1' then
                    rsp_counter <= rsp_counter + 1;
                end if;

                -- control the READY here
                case state is
                    when WB_IDLE =>
                        if cmd_valid_in = '1' then
                            cmd_ready <= '1'; --ACK this
                            state <= WB_REQ_BURST;
                            wb_cyc    <= '1';
                            req_counter <= 0;
                            rsp_counter <= 0;
                        end if;

                    when WB_REQ_BURST =>
                        if cmd_valid_in = '1' and wb_miso_in.stall = '0' then
                            cmd_ready <= '1'; -- ACK this
                            if req_counter = G_MAX_BURST_TRANSFERS then  --end burst as max size reached
                                state <= WB_RSP_WAIT;
                            end if;
                        end if;
                        if cmd_valid_in = '0' then -- end burst as no more CMDs
                            wb_stb    <= '0'; -- no more commands
                            state <= WB_RSP_WAIT;
                        end if;

                    when WB_RSP_WAIT =>
                        wb_stb    <= '0'; -- no more commands
                        if rsp_counter = req_counter then
                            wb_cyc    <= '0';
                            state <= WB_IDLE;
                            burst_done <= '1';
                        end if;
                    when others =>
                        state <= WB_IDLE;
                end case;

            end if;
        end if;
    end process;

end architecture;