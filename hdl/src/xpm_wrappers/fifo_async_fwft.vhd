library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library xpm;
use xpm.vcomponents.all;

-- note that overflow/underflow is non-destructive, as reads/writes are gated inside the XPM
entity fifo_async_fwft is
    generic
    (
        RELATED_CLOCKS   : boolean := false; -- were clocks generated from same clock source?
        FIFO_WRITE_DEPTH : integer := 16; -- number of WR_DATA_WIDTH words that can be written
        WR_DATA_WIDTH    : integer := 32;
        RD_DATA_WIDTH    : integer := 32
    );
    port
    (
        wr_clk   : in std_logic;
        wr_rst : in std_logic;
        wr_vld   : in std_logic;
        wr_data  : in std_logic_vector(WR_DATA_WIDTH - 1 downto 0);
        wr_rdy  : out std_logic;

        rd_clk   : in std_logic;
        rd_rdy   : in std_logic;
        rd_data  : out std_logic_vector(RD_DATA_WIDTH - 1 downto 0);
        rd_vld   : out std_logic
    );
end entity fifo_async_fwft;

architecture rtl of fifo_async_fwft is
    constant WR_DATA_COUNT_WIDTH : integer := integer(ceil(log2(real(FIFO_WRITE_DEPTH)))) + 1;
    constant RD_DATA_COUNT_WIDTH : integer := integer(ceil(log2(real(FIFO_WRITE_DEPTH * WR_DATA_WIDTH/RD_DATA_WIDTH)))) + 1;

    -- force BRAM if using asymmetrical FIFO
    function get_fifo_memtype return string is
    begin
        if WR_DATA_COUNT_WIDTH /= RD_DATA_COUNT_WIDTH then
            return "block";
        else
            return "auto";
        end if;
    end function;

    -- 0707: bits set 0,1,2,8,9,10
    -- |   Setting USE_ADV_FEATURES[0] to 1 enables overflow flag; Default value of this bit is 1                            |
    -- |   Setting USE_ADV_FEATURES[1] to 1 enables prog_full flag; Default value of this bit is 1                           |
    -- |   Setting USE_ADV_FEATURES[2] to 1 enables wr_data_count; Default value of this bit is 1                            |
    -- |   Setting USE_ADV_FEATURES[3] to 1 enables almost_full flag; Default value of this bit is 0                         |
    -- |   Setting USE_ADV_FEATURES[4] to 1 enables wr_ack flag; Default value of this bit is 0                              |
    -- |   Setting USE_ADV_FEATURES[8] to 1 enables underflow flag; Default value of this bit is 1                           |
    -- |   Setting USE_ADV_FEATURES[9] to 1 enables prog_empty flag; Default value of this bit is 1                          |
    -- |   Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count; Default value of this bit is 1                           |
    -- |   Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                       |
    -- |   Setting USE_ADV_FEATURES[12] to 1 enables data_valid flag; Default value of this bit is 0
    constant ADV_FEATURES : string := "0000";
    -- constant ADV_FEATURES : string := "0707";

    -- gate these with appropriate reset_busy
    signal empty       : std_logic;
    signal full        : std_logic;
    signal rd_rst_busy : std_logic;
    signal wr_rst_busy : std_logic;
begin

    rd_vld <= not(empty or rd_rst_busy); -- force while still resetting
    wr_rdy <= not(full or wr_rst_busy); -- force while still resetting

    xpm_fifo_async_inst : xpm_fifo_async
    generic
    map (
    CASCADE_HEIGHT      => 0, -- DECIMAL
    CDC_SYNC_STAGES     => 2, -- DECIMAL
    DOUT_RESET_VALUE    => "0", -- String
    ECC_MODE            => "no_ecc", -- String
    FIFO_MEMORY_TYPE    => get_fifo_memtype, -- String
    FIFO_READ_LATENCY   => 0, -- DECIMAL    Must be 0 for FWFT
    FIFO_WRITE_DEPTH    => FIFO_WRITE_DEPTH, -- DECIMAL
    FULL_RESET_VALUE    => 1, -- DECIMAL    Hold "FULL" high while resetting to ensure no data is written
    PROG_EMPTY_THRESH   => 10, -- DECIMAL
    PROG_FULL_THRESH    => 10, -- DECIMAL
    RD_DATA_COUNT_WIDTH => RD_DATA_COUNT_WIDTH, -- DECIMAL
    READ_DATA_WIDTH     => RD_DATA_WIDTH, -- DECIMAL
    READ_MODE           => "fwft", -- String "std" or "fwft"
    RELATED_CLOCKS      => 0, -- DECIMAL
    SIM_ASSERT_CHK      => 0, -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    USE_ADV_FEATURES    => ADV_FEATURES, -- String
    WAKEUP_TIME         => 0, -- DECIMAL
    WRITE_DATA_WIDTH    => WR_DATA_WIDTH, -- DECIMAL
    WR_DATA_COUNT_WIDTH => WR_DATA_COUNT_WIDTH -- DECIMAL
    )
    port map
    (
        almost_empty => open, -- 1-bit output: Almost Empty : When asserted, this signal indicates that
        -- only one more read can be performed before the FIFO goes to empty.

        almost_full => open, -- 1-bit output: Almost Full: When asserted, this signal indicates that
        -- only one more write can be performed before the FIFO is full.

        data_valid => open, -- 1-bit output: Read Data Valid: When asserted, this signal indicates
        -- that valid data is available on the output bus (dout).

        dbiterr => open, -- 1-bit output: Double Bit Error: Indicates that the ECC decoder
        -- detected a double-bit error and data in the FIFO core is corrupted.

        dout => rd_data, -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
        -- when reading the FIFO.

        empty => empty, -- 1-bit output: Empty Flag: When asserted, this signal indicates that
        -- the FIFO is empty. Read requests are ignored when the FIFO is empty,
        -- initiating a read while empty is not destructive to the FIFO.

        full => full, -- 1-bit output: Full Flag: When asserted, this signal indicates that the
        -- FIFO is full. Write requests are ignored when the FIFO is full,
        -- initiating a write when the FIFO is full is not destructive to the
        -- contents of the FIFO.

        overflow => open, -- 1-bit output: Overflow: This signal indicates that a write request
        -- (wren) during the prior clock cycle was rejected, because the FIFO is
        -- full. Overflowing the FIFO is not destructive to the contents of the
        -- FIFO.

        prog_empty => open, -- 1-bit output: Programmable Empty: This signal is asserted when the
        -- number of words in the FIFO is less than or equal to the programmable
        -- empty threshold value. It is de-asserted when the number of words in
        -- the FIFO exceeds the programmable empty threshold value.

        prog_full => open, -- 1-bit output: Programmable Full: This signal is asserted when the
        -- number of words in the FIFO is greater than or equal to the
        -- programmable full threshold value. It is de-asserted when the number
        -- of words in the FIFO is less than the programmable full threshold
        -- value.

        rd_data_count => open, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates
        -- the number of words read from the FIFO.

        rd_rst_busy => rd_rst_busy, -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO
        -- read domain is currently in a reset state.

        sbiterr => open, -- 1-bit output: Single Bit Error: Indicates that the ECC decoder
        -- detected and fixed a single-bit error.

        underflow => open, -- 1-bit output: Underflow: Indicates that the read request (rd_en)
        -- during the previous clock cycle was rejected because the FIFO is
        -- empty. Under flowing the FIFO is not destructive to the FIFO.

        wr_ack => open, -- 1-bit output: Write Acknowledge: This signal indicates that a write
        -- request (wr_en) during the prior clock cycle is succeeded.

        wr_data_count => open, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
        -- the number of words written into the FIFO.

        wr_rst_busy => wr_rst_busy, -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
        -- write domain is currently in a reset state.

        din => wr_data, -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
        -- writing the FIFO.

        injectdbiterr => '0', -- 1-bit input: Double Bit Error Injection: Injects a double bit error if
        -- the ECC feature is used on block RAMs or UltraRAM macros.

        injectsbiterr => '0', -- 1-bit input: Single Bit Error Injection: Injects a single bit error if
        -- the ECC feature is used on block RAMs or UltraRAM macros.

        rd_clk => rd_clk, -- 1-bit input: Read clock: Used for read operation. rd_clk must be a
        -- free running clock.

        rd_en => rd_rdy, -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this
        -- signal causes data (on dout) to be read from the FIFO. Must be held
        -- active-low when rd_rst_busy is active high.

        rst => wr_rst, -- 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
        -- unstable at the time of applying reset, but reset must be released
        -- only after the clock(s) is/are stable.

        sleep => '0', -- 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
        -- block is in power saving mode.

        wr_clk => wr_clk, -- 1-bit input: Write clock: Used for write operation. wr_clk must be a
        -- free running clock.

        wr_en => wr_vld -- 1-bit input: Write Enable: If the FIFO is not full, asserting this
        -- signal causes data (on din) to be written to the FIFO. Must be held
        -- active-low when rst or wr_rst_busy is active high.

    );
end architecture;