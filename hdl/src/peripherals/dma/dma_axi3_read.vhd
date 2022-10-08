library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi_pkg.all;
use work.joe_common_pkg.all;

--! Generates AXI Read transactions and outputs the Rdata over an AXI-Stream
--! only supports word-aligned transfers of whole words
entity dma_axi3_read is
    port (
        axi_clk   : in std_logic;
        axi_reset : in std_logic;
        -- Commands
        dma_start_in          : in std_logic;                                      -- start a new dma transfer
        dma_start_addr_in     : in std_logic_vector(31 downto 0);                  -- dma start address
        dma_axi_burst_mode_in : in std_logic_vector(1 downto 0) := AXI_BURST_INCR; -- AXI_BURST_FIXED for fifo mode
        dma_num_words_in      : in std_logic_vector(31 downto 0);                  -- max 16 words per AXI3 transaction, split into multiple
        dma_queue_limit_in    : in std_logic_vector(31 downto 0);                  -- how many outstanding AXI3 transactions we can queue before auto-stalling

        dma_stall_in : in std_logic; -- stall issuing of future transactions in a multi transaction dma transfer (rudimentary backpressure)

        dma_done_out : out std_logic;

        -- AXI interfaces
        dma_axi_hp_mosi_out : out t_axi_mosi;
        dma_axi_hp_miso_in  : in t_axi_miso;

        axi_stream_mosi_out : out t_axi_stream32_mosi;
        axi_stream_miso_in  : out t_axi_stream32_miso
    );
end entity dma_axi3_read;

architecture rtl of dma_axi3_read is

    type t_state is (IDLE, READ_SETUP, READ_ACCEPT_WAIT, STALL, WAIT_DONE);
    signal state : t_state := IDLE;

    -- for AXI3, max 16 transfers per burst
    constant MAX_TRANSACTIONS : integer := 16;

    constant BYTES_PER_WORD : integer := 4;

    signal words_remaining : integer;
    signal dma_addr_offset : integer;
    signal dma_start_addr  : integer;

    -- queue counters
    signal num_cmd : integer := 0;
    signal num_rsp : integer := 0;
    signal outstanding_cmds : integer;
begin
    -- set ARCACHE[1] = '1' to allow DDR3 controller to pack into 64b transactions for better performance
    -- write channels not used
    dma_axi_hp_mosi_out.awaddr  <= (others => '0');
    dma_axi_hp_mosi_out.awburst <= (others => '0');
    dma_axi_hp_mosi_out.awcache <= (others => '0');
    dma_axi_hp_mosi_out.awid    <= (others => '0');
    dma_axi_hp_mosi_out.awlen   <= (others => '0');
    dma_axi_hp_mosi_out.awlock  <= (others => '0');
    dma_axi_hp_mosi_out.awprot  <= (others => '0');
    dma_axi_hp_mosi_out.awqos   <= (others => '0');
    dma_axi_hp_mosi_out.awsize  <= (others => '0');
    dma_axi_hp_mosi_out.wdata   <= (others => '0');
    dma_axi_hp_mosi_out.wid     <= (others => '0');
    dma_axi_hp_mosi_out.wlast   <= '0';
    dma_axi_hp_mosi_out.wstrb   <= (others => '0');
    dma_axi_hp_mosi_out.bready  <= '0';
    -- connect R channel straight to AXI stream output
    axi_stream_mosi_out.tdata  <= dma_axi_hp_miso_in.rdata;
    axi_stream_mosi_out.tvalid <= dma_axi_hp_miso_in.rvalid;
    axi_stream_mosi_out.tlast  <= dma_axi_hp_miso_in.rlast;
    dma_axi_hp_mosi_out.rready <= axi_stream_miso_in.tready;


    outstanding_cmds <= num_cmd - num_rsp;

    dma_read : process (axi_clk)
        variable v_burst_size       : integer; -- intermediate value
    begin
        if rising_edge(axi_clk) then
            if axi_reset = '1' then
                state                       <= IDLE;
                num_cmd                     <= 0;
                dma_axi_hp_mosi_out.arvalid <= '0';
                dma_done_out <= '1';
            else
                case(state) is
                    ---------------------------------
                    -- wait for a new transfer request to be issued
                    ---------------------------------
                    when IDLE =>

                    if dma_start_in = '1' then
                        dma_done_out <= '0';
                        words_remaining <= slv2uint(dma_num_words_in);
                        dma_start_addr  <= slv2uint(dma_start_addr_in);
                        dma_addr_offset <= 0;

                        state <= READ_SETUP;

                    end if;

                    ---------------------------------
                    -- set up AXI transaction
                    ---------------------------------
                    when READ_SETUP =>

                    -- if more than can fit in one burst, use the max burst size
                    if words_remaining > MAX_TRANSACTIONS then
                        v_burst_size := MAX_TRANSACTIONS;
                    else -- else just finish with a partially full burst
                        v_burst_size := words_remaining;
                    end if;
                    report "words_remaining = " & to_string(words_remaining);
                    report "burst size      = " & to_string(v_burst_size);

                    dma_axi_hp_mosi_out.arlen <= uint2slv(v_burst_size - 1, dma_axi_hp_mosi_out.arlen'length);
                    words_remaining           <= words_remaining - v_burst_size;

                    dma_axi_hp_mosi_out.araddr  <= uint2slv(dma_start_addr + dma_addr_offset); -- set up burst address
                    dma_axi_hp_mosi_out.arburst <= dma_axi_burst_mode_in;                      -- INCR or FIXED
                    dma_axi_hp_mosi_out.arvalid <= '1';
                    num_cmd                     <= num_cmd + 1;

                    state <= READ_ACCEPT_WAIT;

                    -- setup the address offset for the next burst
                    if dma_axi_burst_mode_in = AXI_BURST_FIXED then
                        dma_addr_offset <= 0;
                    else
                        dma_addr_offset <= dma_addr_offset + (BYTES_PER_WORD * v_burst_size);
                    end if;

                    -------------------------------------------
                    -- wait for AXI transaction to be accepted
                    -------------------------------------------
                    when READ_ACCEPT_WAIT =>
                    if dma_axi_hp_mosi_out.arvalid = '1' and dma_axi_hp_miso_in.arready = '1' then
                        dma_axi_hp_mosi_out.arvalid <= '0';

                        -- decide if we stall or issue another burst
                        report "outstanding cmds = " & to_string(outstanding_cmds);
                        if outstanding_cmds >= slv2uint(dma_queue_limit_in) or dma_stall_in = '1' then
                            state <= STALL;
                        else
                            if words_remaining = 0 then
                                state <= WAIT_DONE;
                            else
                                state <= READ_SETUP;
                            end if;
                        end if;
                    end if;

                    -----------------------------------------------------------------
                    -- wait for queue to empty (ie rlast) or manual stall to deassert
                    -----------------------------------------------------------------
                    when STALL =>
                    if outstanding_cmds < slv2uint(dma_queue_limit_in) and dma_stall_in = '0' then
                        if words_remaining = 0 then
                            state <= WAIT_DONE;
                        else
                            state <= READ_SETUP;
                        end if;
                    end if;
                    when WAIT_DONE =>
                    if outstanding_cmds = 0 then
                        dma_done_out <= '1';
                        state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    p_count_rsp : process (axi_clk)
    begin
        if rising_edge(axi_clk) then
            if axi_reset = '1' then
                num_rsp <= 0;
            else
                if dma_axi_hp_miso_in.rvalid = '1' and dma_axi_hp_miso_in.rlast = '1' and dma_axi_hp_mosi_out.rready = '1' then
                    num_rsp <= num_rsp + 1;
                end if;
            end if;
        end if;
    end process;

    -- fixed AXI3 parameters
    dma_axi_hp_mosi_out.arcache <= b"0010"; -- Non bufferable, non-cacheable, modifiable (so can upsize to 64b in Zynq DDR3 controller)
    dma_axi_hp_mosi_out.arid    <= x"000";  -- ID = 0 (all transactions must be in order)
    dma_axi_hp_mosi_out.arlock  <= b"00";   -- normal transaction
    dma_axi_hp_mosi_out.arprot  <= b"000";  -- Unpriviledged, Secure, Data access (AxPROT[1] must be '0' for PS peripheral access)
    dma_axi_hp_mosi_out.arqos   <= x"0";    -- No QoS in use
    dma_axi_hp_mosi_out.arsize  <= b"010";  -- 4 bytes per transfer
end architecture;