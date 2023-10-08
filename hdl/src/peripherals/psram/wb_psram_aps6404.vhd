library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all;
--! Super simple Wishbone wrapper for the APS6404 PSRAM, handling 4
--------------------------------------------------------------------------------
entity wb_psram_aps6404 is
    generic
    (
        MEM_CTRL_CLK_FREQ_KHZ : integer;
        BURST_LENGTH_BYTES    : integer := 4
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
end entity wb_psram_aps6404;

architecture rtl of wb_psram_aps6404 is
    -- Memory Map of 8MB PSRAM
    -- 0x00_0000 to 0x7f_ffff   Mapped RAM
    -- 0x80_0000                PSRAM Control/Status. Writes latch the counters
    -- 0x80_0004                Cache Hit Counter
    -- 0x80_0008                Cache Miss Counter
    -- 0x80_000C                Stall Cycles Counter (wb_clk)

    constant PSRAM_ADDR_BITS      : integer := 23; -- APS6404 is 8MB PSRAM
    constant WB_ADDR_BITS         : integer := PSRAM_ADDR_BITS + 1; -- top bit 1=registers, 0=psram
    constant WB_REG_ADDR_BITS     : integer := 4;
    constant CACHE_BYTE_ADDR_BITS : integer := clog2(BURST_LENGTH_BYTES);

    constant REG_CONTROL_ADDR              : std_logic_vector(WB_REG_ADDR_BITS - 1 downto 0) := x"0";
    constant REG_CACHE_HIT_COUNT_ADDR      : std_logic_vector(WB_REG_ADDR_BITS - 1 downto 0) := x"4";
    constant REG_CACHE_MISS_COUNT_ADDR     : std_logic_vector(WB_REG_ADDR_BITS - 1 downto 0) := x"8";
    constant REG_STALL_CYCLES_COUNTER_ADDR : std_logic_vector(WB_REG_ADDR_BITS - 1 downto 0) := x"C";

    signal reset_mem_clk : std_logic := '1';

    -- very minimal 1-line cache of X bytes to improve efficiency by using longer burst length
    -- also lets us do sub-word writes
    signal cache_line_buf : std_logic_vector(BURST_LENGTH_BYTES * 8 - 1 downto 0);
    signal cache_tag      : std_logic_vector(PSRAM_ADDR_BITS - 1 downto CACHE_BYTE_ADDR_BITS);
    -- signal cache_line_addr         : std_logic_vector(PSRAM_ADDR_BITS - 1 downto 0); -- Start Byte Address of the line currently in the cache (debug)
    signal cache_line_empty_wb_clk : std_logic := '1'; -- clear after first load

    -- decompose the WB address into its parts/
    signal addr_tag  : std_logic_vector(PSRAM_ADDR_BITS - 1 downto CACHE_BYTE_ADDR_BITS);
    signal addr_byte : natural;

    -- save the WB transaction in case of a cache miss
    signal saved_wb_mosi   : t_wb_mosi;
    signal saved_addr_tag  : std_logic_vector(PSRAM_ADDR_BITS - 1 downto CACHE_BYTE_ADDR_BITS);
    signal saved_addr_byte : natural;

    -- signal when cache line modified
    signal cache_line_dirty        : std_logic;
    signal psram_read_req_wb_clk   : std_logic;
    signal psram_write_req_wb_clk  : std_logic;
    signal psram_read_req_mem_clk  : std_logic;
    signal psram_write_req_mem_clk : std_logic;

    -- PSRAM controller signals (memclk)
    signal burst_start : std_logic;
    signal burst_start_byte_address : std_logic_vector(22 downto 0);
    signal burst_write : std_logic;
    signal burst_wdata : std_logic_vector(BURST_LENGTH_BYTES * 8 - 1 downto 0); -- memclk
    signal burst_rdata : std_logic_vector(BURST_LENGTH_BYTES * 8 - 1 downto 0); -- memclk

    -- signal when PSRAM read has completed
    signal psram_done_mem_clk : std_logic;
    signal psram_done_wb_clk  : std_logic;

    signal psram_busy_mem_clk : std_logic;
    signal psram_busy_wb_clk  : std_logic;

    -- Stats counters
    signal cache_hit_count        : unsigned(31 downto 0)         := x"0000_0000";
    signal cache_miss_count       : unsigned(31 downto 0)         := x"0000_0000";
    signal stall_cycles_count     : unsigned(31 downto 0)         := x"0000_0000";
    signal reg_cache_hit_count    : std_logic_vector(31 downto 0) := x"0000_0000";
    signal reg_cache_miss_count   : std_logic_vector(31 downto 0) := x"0000_0000";
    signal reg_stall_cycles_count : std_logic_vector(31 downto 0) := x"0000_0000";
    -- on wishbone clk
    type t_wb_state is (IDLE, CACHE_HIT, CACHE_MISS_WAIT_FOR_PSRAM_READY, CACHE_MISS_WRITEBACK, CACHE_MISS_RELOAD, CACHE_MISS_FINAL);
    signal wb_state : t_wb_state := IDLE;

    type t_mem_state is (BUSY, IDLE, FETCH, WRITEBACK);
    signal mem_state : t_mem_state := BUSY;
begin

    addr_tag        <= wb_mosi_in.adr(PSRAM_ADDR_BITS - 1 downto CACHE_BYTE_ADDR_BITS);
    addr_byte       <= slv2uint(wb_mosi_in.adr(CACHE_BYTE_ADDR_BITS - 1 downto 0)); -- note that bits 1:0 should always be 0 for WB - check SEL lines
    saved_addr_tag  <= saved_wb_mosi.adr(PSRAM_ADDR_BITS - 1 downto CACHE_BYTE_ADDR_BITS);
    saved_addr_byte <= slv2uint(saved_wb_mosi.adr(CACHE_BYTE_ADDR_BITS - 1 downto 0)); -- note that bits 1:0 should always be 0 for WB - check SEL lines

    process (wb_clk)
        -- used for addressing calcs
        variable hi : integer;
        variable lo : integer;
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                wb_miso_out.ack         <= '0';
                wb_miso_out.err         <= '0';
                wb_miso_out.rty         <= '0';
                cache_hit_count         <= x"0000_0000";
                cache_miss_count        <= x"0000_0000";
                stall_cycles_count      <= x"0000_0000";
                cache_line_empty_wb_clk <= '1';
                wb_state                <= IDLE;
            else
                -- defaults
                wb_miso_out.ack  <= '0';
                wb_miso_out.err  <= '0'; -- this slave does not generate ERR or RTY responses
                wb_miso_out.rty  <= '0';
                wb_miso_out.rdat <= x"DEADC0DE";

                wb_miso_out.stall      <= '1'; -- stall by default
                psram_read_req_wb_clk  <= '0';
                psram_write_req_wb_clk <= '0';

                case wb_state is
                        -- Wait for WB transaction to come in
                    when IDLE =>
                        wb_miso_out.stall <= '0'; -- ready for WB transaction
                        if wb_mosi_in.stb = '1' and wb_miso_out.stall = '0' then
                            saved_wb_mosi <= wb_mosi_in;
                            if wb_mosi_in.adr(WB_ADDR_BITS - 1) = '1' then -- register access
                                wb_miso_out.ack <= '1'; -- ACK register access
                                if wb_mosi_in.we then
                                    -- Register Write
                                    case(wb_mosi_in.adr(WB_REG_ADDR_BITS - 1 downto 0)) is
                                    when REG_CONTROL_ADDR => -- Latch all counters
                                        reg_cache_hit_count    <= std_logic_vector(cache_hit_count);
                                        reg_cache_miss_count   <= std_logic_vector(cache_miss_count);
                                        reg_stall_cycles_count <= std_logic_vector(stall_cycles_count);
                                    when others => null;
                                    end case;
                                else
                                    -- Register Read
                                    case(wb_mosi_in.adr(WB_REG_ADDR_BITS - 1 downto 0)) is
                                    when REG_CONTROL_ADDR =>
                                        wb_miso_out.rdat <= (others                                  => '0'); -- autoformat breaks here
                                    when REG_CACHE_HIT_COUNT_ADDR =>
                                        wb_miso_out.rdat <= reg_cache_hit_count;
                                    when REG_CACHE_MISS_COUNT_ADDR =>
                                        wb_miso_out.rdat <= reg_cache_miss_count;
                                    when REG_STALL_CYCLES_COUNTER_ADDR =>
                                        wb_miso_out.rdat <= reg_stall_cycles_count;
                                    when others =>
                                        null;
                                    end case;
                                end if;

                            else -- Cache/PSRAM access
                                if (addr_tag = cache_tag) and cache_line_empty_wb_clk = '0' then
                                    cache_hit_count <= cache_hit_count + to_unsigned(1, 32);
                                    -- wb_state        <= CACHE_HIT;    -- no need to change state on Cache Hit
                                    wb_miso_out.ack <= '1'; -- ACK Cache Hit

                                    -- on a cache hit, perform the read/write. If a write, trigger a writeback
                                    for i in 0 to 3 loop
                                        -- add on addr_byte  offset within cache line
                                        hi := 8 * (i + addr_byte + 1) - 1;
                                        lo := 8 * (i + addr_byte);
                                        if wb_mosi_in.sel(i) = '1' then -- if this byte is selected
                                            -- synchronous write logic
                                            cache_line_dirty <= '1'; -- mark cache line as dirty
                                            if wb_mosi_in.we = '1' then
                                                cache_line_buf(hi downto lo) <= wb_mosi_in.wdat(8 * (i + 1) - 1 downto 8 * i); -- write byte
                                            end if;
                                        end if;
                                        -- synchronous read logic
                                        wb_miso_out.rdat(8 * (i + 1) - 1 downto 8 * i) <= cache_line_buf(hi downto lo); -- read byte
                                    end loop;

                                else
                                    cache_miss_count  <= cache_miss_count + to_unsigned(1, 32);
                                    wb_state          <= CACHE_MISS_WAIT_FOR_PSRAM_READY;
                                    wb_miso_out.stall <= '1'; -- halt future WB transactions
                                end if;

                            end if;
                        end if;

                    when CACHE_MISS_WAIT_FOR_PSRAM_READY => -- wait for PSRAM to be ready (TODO skippable if already ready)
                        if psram_busy_wb_clk = '0' then
                            if cache_line_dirty = '1' then
                                wb_state               <= CACHE_MISS_WRITEBACK; -- writeback before we reload cache line
                                psram_write_req_wb_clk <= '1'; -- 1-cycle pulse to CDC
                            else
                                wb_state              <= CACHE_MISS_RELOAD;
                                psram_read_req_wb_clk <= '1'; -- 1-cycle pulse to CDC
                            end if;
                        end if;

                    when CACHE_MISS_WRITEBACK =>
                        if psram_done_wb_clk = '1' then
                            cache_line_dirty      <= '0'; -- now cache line is clean as writeback complete
                            wb_state              <= CACHE_MISS_RELOAD;
                            psram_read_req_wb_clk <= '1'; -- 1-cycle pulse to CDC
                        end if;
                    when CACHE_MISS_RELOAD => -- wait for cache line to be reloaded
                        if psram_done_wb_clk = '1' then
                            wb_state                <= CACHE_MISS_FINAL;
                            cache_line_empty_wb_clk <= '0';
                            cache_line_buf          <= burst_rdata;-- NOTE burst_rdata is in the mem_clk domain, but will be stable while the PSRAM DONE pulse is CDC'd
                            cache_tag               <= saved_addr_tag;
                        end if;
                    when CACHE_MISS_FINAL => -- apply original WB transaction to new cache line
                        wb_state        <= IDLE;
                        wb_miso_out.ack <= '1';
                        for i in 0 to 3 loop
                            -- add on addr_byte  offset within cache line
                            hi := 8 * (i + saved_addr_byte + 1) - 1;
                            lo := 8 * (i + saved_addr_byte);
                            if saved_wb_mosi.sel(i) = '1' then -- if this byte is selected
                                -- synchronous write logic
                                cache_line_dirty <= '1'; -- mark cache line as dirty
                                if saved_wb_mosi.we = '1' then
                                    cache_line_buf(hi downto lo) <= saved_wb_mosi.wdat(8 * (i + 1) - 1 downto 8 * i); -- write byte
                                end if;
                            end if;
                            -- synchronous read logic
                            wb_miso_out.rdat(8 * (i + 1) - 1 downto 8 * i) <= cache_line_buf(hi downto lo); -- read byte
                        end loop;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    process (mem_ctrl_clk)
    begin
        if rising_edge(mem_ctrl_clk) then
            -- defaults
            burst_start <= '0';
            if reset_mem_clk = '1' then
                mem_state <= BUSY;
            else
                case(mem_state) is
                    when BUSY =>
                    if psram_busy_mem_clk = '0' then
                        mem_state <= IDLE;
                    end if;
                    when IDLE =>
                    if psram_read_req_mem_clk then
                        mem_state                <= BUSY;
                        burst_start              <= '1'; -- pulse
                        burst_write              <= '0'; -- READ
                        burst_start_byte_address <= (others => '0'); -- fill with all 0s, overwrite below
                        burst_start_byte_address <= wb_mosi_in.adr(PSRAM_ADDR_BITS - 1 downto CACHE_BYTE_ADDR_BITS);
                    end if;
                    if psram_write_req_mem_clk then
                        mem_state                <= BUSY;
                        burst_start              <= '1'; -- pulse
                        burst_write              <= '1'; -- WRITE
                        burst_start_byte_address <= (others => '0'); -- fill with all 0s, overwrite below
                        burst_start_byte_address <= wb_mosi_in.adr(PSRAM_ADDR_BITS - 1 downto CACHE_BYTE_ADDR_BITS);
                        burst_wdata              <= cache_line_buf; -- NOTE cache_line_buf is in the wb_clk domain, but will be stable while the WRITE REQ pulse is CDC'd
                    end if;
                    when others => null;
                end case;

            end if;
        end if;
    end process;

    psram_aps6404_ctrl_inst : entity work.psram_aps6404_ctrl
        generic
        map (
        MEM_CTRL_CLK_FREQ_KHZ => MEM_CTRL_CLK_FREQ_KHZ,
        BURST_LENGTH_BYTES    => BURST_LENGTH_BYTES
        ) port map
        (
        mem_ctrl_clk             => mem_ctrl_clk,
        reset                    => reset_mem_clk,
        burst_start_byte_address => burst_start_byte_address,
        burst_start              => burst_start,
        burst_write              => burst_write,
        wdata_in                 => burst_wdata,
        burst_done               => psram_done_mem_clk,
        rdata_out                => burst_rdata,
        psram_busy               => psram_busy_mem_clk,
        psram_clk                => psram_clk,
        psram_cs_n               => psram_cs_n,
        psram_sio                => psram_sio
        );

    --==============================================================================
    -- Clock Domain Crossing of Reset/Control Signals
    --==============================================================================
    -- WB Clock to MEM Clock
    cdc_sync_rst_inst : entity work.cdc_sync_rst
        port
        map (
        src_rst  => wb_reset,
        dest_clk => mem_ctrl_clk,
        dest_rst => reset_mem_clk
        );

    read_req_cdc_pulse_inst : entity work.cdc_pulse
        port
        map (
        src_clk    => wb_clk,
        src_pulse  => psram_read_req_wb_clk,
        dest_clk   => mem_ctrl_clk,
        dest_pulse => psram_read_req_mem_clk
        );

    write_req_cdc_pulse_inst : entity work.cdc_pulse
        port
        map (
        src_clk    => wb_clk,
        src_pulse  => psram_write_req_wb_clk,
        dest_clk   => mem_ctrl_clk,
        dest_pulse => psram_write_req_mem_clk
        );

    --------------------------------------------------------------------------------
    -- MEM Clock to WB Clock
    psram_done_cdc_pulse_inst : entity work.cdc_pulse
        port
        map (
        src_clk    => mem_ctrl_clk,
        src_pulse  => psram_done_mem_clk,
        dest_clk   => wb_clk,
        dest_pulse => psram_done_wb_clk
        );

    psram_busy_cdc_single_inst : entity work.cdc_single
        port
        map (
        src_clk  => mem_ctrl_clk,
        src_in   => psram_busy_mem_clk,
        dest_clk => wb_clk,
        dest_out => psram_busy_wb_clk
        );

end architecture;