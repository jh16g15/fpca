library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all;

--! Wishbone wrapper for PSRAM streaming controller. Should handle sub-word accesses, and allow pipelined transfers
--! for future DMA burst access
entity wb_psram_aps6404_streaming is
    generic
    (
        MEM_CTRL_CLK_FREQ_KHZ : integer;
        RELATED_CLOCKS        : boolean := true
    );
    port
    (
        wb_clk       : in std_logic;
        mem_ctrl_clk : in std_logic;
        wb_reset     : in std_logic;

        wb_mosi_in  : in t_wb_mosi;
        wb_miso_out : out t_wb_miso;

        -- PSRAM IO
        psram_clk  : out std_logic;
        psram_cs_n : out std_logic;
        psram_sio  : inout std_logic_vector(3 downto 0)

    );
end entity wb_psram_aps6404_streaming;

architecture rtl of wb_psram_aps6404_streaming is

    constant CMD_LEN : integer := 23 + 8 + 1 + 1;
    type t_cmd is record
        -- we can replace this duplicated full address with a 2 bit "byte offset" later and calculate actual address on the FIFO read size
        address : std_logic_vector(22 downto 0);
        wdata : std_logic_vector(7 downto 0);
        we : std_logic;
        keep : std_logic;
    end record;

    type t_cmd_arr is array(0 to 3) of t_cmd;

    signal wb_fifo_cmd      : t_cmd_arr; -- submit 4 commands to the CMD FIFO at once
    signal wb_cmd_valid     : std_logic;
    signal wb_cmd_ready     : std_logic;

    signal mem_reset        : std_logic := '0';
    signal mem_fifo_cmd     : t_cmd;
    signal mem_cmd_valid    : std_logic;
    signal mem_cmd_ready    : std_logic;
    -- Memory Map of 8MB PSRAM
    -- 0x00_0000 to 0x7f_ffff   Mapped RAM
    constant PSRAM_ADDR_BITS : integer := 23; -- APS6404 is 8MB PSRAM
    constant FIFO_WRITE_DEPTH : integer := 16; -- Small CDC FIFOs

    -- pack Address, Data, Write En and Keep into a single vector
    signal wb_fifo_command_in   : std_logic_vector(4*(CMD_LEN) - 1 downto 0);
    signal mem_fifo_command_out : std_logic_vector(CMD_LEN - 1 downto 0);

    -- just data comes back
    signal mem_rsp_valid          : std_logic;
    signal mem_fifo_response_in   : std_logic_vector(8-1 downto 0);
    signal wb_fifo_response_out   : std_logic_vector(8-1 downto 0);
    signal wb_fifo_response_valid : std_logic;
    signal wb_rsp_valid     : std_logic;
    signal wb_rsp_ready     : std_logic;
    signal wb_rsp_rdata_out : std_logic_vector(7 downto 0);

    -- FIFO Queue for managing the returned RDATA, so we can reassemble the Wishbone response
    signal rsp_sel_in : std_logic_vector(3 downto 0);
    signal rsp_sel_out : std_logic_vector(3 downto 0);
    signal rsp_sel_in_vld : std_logic;
    signal rsp_sel_out_vld : std_logic;
    signal rsp_sel_in_rdy : std_logic;
    signal rsp_sel_out_rdy : std_logic;

    type t_rsp_state is (IDLE, RX_ACKS);
    signal rsp_state : t_rsp_state := IDLE;

    signal rsp_byte_index : integer range 0 to 4; -- 0 to 3 really, but goes to 4 on exit from Word transfer
    signal rsp_bytes_to_process : integer range 1 to 4;
    signal rsp_bytes_processed  : integer range 0 to 4;


begin

    -- continue to accept Wishbone commands until command FIFO or response byte selet FIFO is full
    wb_miso_out.stall <= (not wb_cmd_ready) or (not rsp_sel_in_rdy);

    -- Command Process
    process (wb_clk)
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                null;
            else
                -- defaults, don't write to FIFOs
                wb_cmd_valid <= '0';
                rsp_sel_in_vld <= '0';

                -- if we can accept a new transaction, do that here
                if wb_mosi_in.stb = '1' and wb_miso_out.stall = '0' and rsp_sel_in_rdy = '1' then
                    -- Write to Command FIFO
                    wb_cmd_valid <= '1';
                    for i in 0 to 3 loop
                        wb_fifo_cmd(i).address <= wb_mosi_in.adr(PSRAM_ADDR_BITS-1 downto 2) & std_logic_vector(to_unsigned(i, 2));
                        wb_fifo_cmd(i).wdata <= wb_mosi_in.wdat(i*8+7 downto i*8);
                        wb_fifo_cmd(i).we <= wb_mosi_in.we;
                        wb_fifo_cmd(i).keep <= wb_mosi_in.sel(i);
                    end loop;
                    -- Write to Response Select FIFO so we can re-assemble later
                    rsp_sel_in <= wb_mosi_in.sel;
                    rsp_sel_in_vld <= '1';
                end if;
            end if;
        end if;
    end process;

    -- Response Process (independent of Command process )
    process (wb_clk)
        procedure set_rsp_params(sel : std_logic_vector(3 downto 0)) is
            variable bytes : integer range 0 to 4;
            variable start : integer range 0 to 4;
        begin
            -- iterate down so least significant '1' remains
            for i in 3 downto 0 loop
                if sel(i) = '1' then
                    bytes := bytes + 1;
                    start := i;
                end if;
            end loop;
            rsp_byte_index <= start;
            rsp_bytes_to_process <= bytes;
        end procedure;
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                rsp_state <= IDLE;
                rsp_sel_out_rdy <= '0';
                wb_rsp_ready <= '0';
                wb_miso_out.ack <= '0';
                wb_miso_out.err <= '0';
            else
                -- defaults
                wb_miso_out.ack <= '0';
                case rsp_state is
                    --------------------------------------------------------------------------------
                    -- Wait for a new command SEL to emerge from the byte select FIFO
                    -- NOTE: latency of this FIFO should always be shorter than time taken to get any response from the memory controller
                    when IDLE =>
                        rsp_sel_out_rdy <= '1'; -- SEL FIFO ready
                        if rsp_sel_out_vld = '1' and rsp_sel_out_rdy = '1' then
                            rsp_sel_out_rdy <= '0';
                            rsp_state <= RX_ACKS;
                            wb_rsp_ready <= '1'; -- RDATA FIFO ready
                            rsp_bytes_processed <= 0;
                            set_rsp_params(rsp_sel_out);    -- set start index and number of bytes to process
                            wb_miso_out.rdat <= (others => '0'); -- perhaps not strictly needed but cleans things up nicely
                        end if;
                    when RX_ACKS =>
                        if wb_rsp_valid = '1' then

                            -- load byte into rdata (if was a write, will be junk, but that doesn't matter)
                            wb_miso_out.rdat(rsp_byte_index*8+7 downto rsp_byte_index*8) <= wb_rsp_rdata_out;
                            rsp_byte_index <= rsp_byte_index + 1;
                            rsp_bytes_processed <= rsp_bytes_processed + 1;

                            if rsp_bytes_processed + 1 = rsp_bytes_to_process then -- check if done transaction
                                rsp_sel_out_rdy <= '1'; -- SEL FIFO ready
                                wb_miso_out.ack <= '1';
                                wb_rsp_ready <= '0'; -- RDATA FIFO ready
                                rsp_state <= IDLE;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------
    -- CDC over to the APS6404 PSRAM controller
    --------------------------------------------------------------------------------

    cdc_sync_rst_inst : entity work.cdc_sync_rst
        port map
        (
            dest_clk => mem_ctrl_clk,
            src_rst  => wb_reset,
            dest_rst => mem_reset
        );

    -- map commands to a single CDC 4:1 FIFO direction
    gen : for i in 0 to 3 generate
        wb_fifo_command_in(i*CMD_LEN+CMD_LEN-1 downto i*CMD_LEN) <=  wb_fifo_cmd(i).keep & wb_fifo_cmd(i).wdata & wb_fifo_cmd(i).we & wb_fifo_cmd(i).address;
    end generate;
    mem_fifo_cmd.address <= mem_fifo_command_out(22 downto 0);
    mem_fifo_cmd.we <= mem_fifo_command_out(23);
    mem_fifo_cmd.wdata <= mem_fifo_command_out(31 downto 24);
    mem_fifo_cmd.keep <= mem_fifo_command_out(32);

    wb_rsp_rdata_out <= wb_fifo_response_out;
    wb_rsp_valid     <= wb_fifo_response_valid;

    fifo_cmd_inst : entity work.fifo_fwft
        generic
        map (
        DUAL_CLOCK       => true,
        RELATED_CLOCKS   => RELATED_CLOCKS,
        FIFO_WRITE_DEPTH => FIFO_WRITE_DEPTH,
        WR_DATA_WIDTH    => 4 * CMD_LEN,
        RD_DATA_WIDTH    => CMD_LEN
        )
        port
        map (
        wr_clk  => wb_clk,
        wr_rst  => wb_reset,
        wr_vld  => wb_cmd_valid,
        wr_data => wb_fifo_command_in,
        wr_rdy  => wb_cmd_ready,
        rd_clk  => mem_ctrl_clk,
        rd_rdy  => mem_cmd_ready or not(mem_fifo_cmd.keep), -- read FIFO word if mem controller requires or we don't want to keep
        rd_data => mem_fifo_command_out,
        rd_vld  => mem_cmd_valid
        );

    fifo_rsp_inst : entity work.fifo_fwft
        generic
        map (
        DUAL_CLOCK       => true,
        RELATED_CLOCKS   => RELATED_CLOCKS,
        FIFO_WRITE_DEPTH => FIFO_WRITE_DEPTH,
        WR_DATA_WIDTH    => 8,
        RD_DATA_WIDTH    => 8
        )
        port
        map (
        wr_clk  => mem_ctrl_clk,
        wr_rst  => mem_reset,
        wr_vld  => mem_rsp_valid,
        wr_data => mem_fifo_response_in,
        wr_rdy  => open, -- no response backpressure supported by memory controller
        rd_clk  => wb_clk,
        rd_rdy  => wb_rsp_ready,
        rd_data => wb_fifo_response_out,
        rd_vld  => wb_fifo_response_valid
        );

    -- SYNC fifo queue for storing the wishbone SEL signals
    fifo_rsp_sel_inst : entity work.fifo_fwft
        generic
        map (
        DUAL_CLOCK       => false,
        FIFO_WRITE_DEPTH => FIFO_WRITE_DEPTH,
        WR_DATA_WIDTH    => 4,
        RD_DATA_WIDTH    => 4
        )
        port
        map (
        wr_clk  => wb_clk,
        wr_rst  => wb_reset,
        wr_vld  => rsp_sel_in_vld,
        wr_data => rsp_sel_in,
        wr_rdy  => rsp_sel_in_rdy,
        rd_rdy  => rsp_sel_out_rdy,
        rd_data => rsp_sel_out,
        rd_vld  => rsp_sel_out_vld
        );

    psram_aps6404_streaming_ctrl_inst : entity work.psram_aps6404_streaming_ctrl
        generic
        map (
        MEM_CTRL_CLK_FREQ_KHZ => MEM_CTRL_CLK_FREQ_KHZ
        )
        port
        map (
        mem_ctrl_clk   => mem_ctrl_clk,
        reset          => mem_reset,
        cmd_valid      => mem_cmd_valid and mem_fifo_cmd.keep, -- submit to mem controller if keep high
        cmd_ready      => mem_cmd_ready,
        cmd_address_in => mem_fifo_cmd.address,
        cmd_wdata_in   => mem_fifo_cmd.wdata,
        cmd_we_in      => mem_fifo_cmd.we,
        rsp_valid      => mem_rsp_valid,
        rsp_rdata_out  => mem_fifo_response_in,
        psram_clk      => psram_clk,
        psram_cs_n     => psram_cs_n,
        psram_sio      => psram_sio
        );

end architecture;