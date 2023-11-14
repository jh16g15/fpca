library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Simple streaming controller for APS6404 PSRAM
--! Bursts are automatically continued if contiguous and within max burst length, so suitable for DMA/cache line refills
entity psram_aps6404_streaming_ctrl is
    generic
    (
        MEM_CTRL_CLK_FREQ_KHZ : integer := 25000 -- PSRAM SPI CLK is half this
    );
    port
    (
        mem_ctrl_clk : in std_logic;
        reset        : in std_logic;

        -- command stream
        cmd_valid : in std_logic;
        cmd_ready : out std_logic := '0';
        cmd_address_in : in std_logic_vector(22 downto 0);
        cmd_wdata_in : in std_logic_vector(7 downto 0);
        cmd_we_in : in std_logic;

        -- response stream (no backpressure)
        rsp_valid : out std_logic := '0';
        rsp_rdata_out  : out std_logic_vector(7 downto 0);

        -- PSRAM IO
        psram_clk  : out std_logic;
        psram_cs_n : out std_logic;
        psram_sio  : inout std_logic_vector(3 downto 0)

    );
end entity psram_aps6404_streaming_ctrl;

architecture rtl of psram_aps6404_streaming_ctrl is

    signal reg_cmd_address : unsigned(22 downto 0);
    signal reg_cmd_wdata :  std_logic_vector(7 downto 0);
    signal reg_cmd_we : std_logic;

    constant PSRAM_CLK_FREQ_KHZ : integer := MEM_CTRL_CLK_FREQ_KHZ / 2; -- spi clk

    -- 1MHz has a period of 1us
    -- max 8us per burst before refresh is needed

    constant MAX_CSN_ASSERT : time := 8 us;
    -- constant MEM_CTRL_CLK_PERIOD : time := (MEM_CTRL_CLK_FREQ_KHZ * 1 us) /1000 ;
    constant MEM_CTRL_CLK_PERIOD : time := 1 sec / (MEM_CTRL_CLK_FREQ_KHZ * 1000);

    -- can trim these later if needed to meet timing
    constant C_CSN_COUNT_W : integer := 16;
    constant ONE_MORE_BYTE_CYCLES : unsigned(C_CSN_COUNT_W-1 downto 0) := to_unsigned(5, C_CSN_COUNT_W); -- number of mem_ctrl_clk cycles it takes to transfer one more byte before we deassert CSN at the end of a burst
    constant MAX_CSN_ASSERT_CYCLES  : unsigned(C_CSN_COUNT_W-1 downto 0) := to_unsigned(MAX_CSN_ASSERT / MEM_CTRL_CLK_PERIOD, C_CSN_COUNT_W);
    signal csn_asserted_counter : unsigned(C_CSN_COUNT_W-1 downto 0); -- to check we haven't hit max burst length before a refresh is needed

    constant PWR_ON_DELAY_CYCLES : integer := 150 * MEM_CTRL_CLK_FREQ_KHZ / 1000; -- 150us

    -- We need 18ns of CS_N deasserted between each burst for DRAM auto-refresh
    -- 18ns = 55.5 MHz
    constant PSRAM_REFRESH_TARGET : time := 18 ns;
    constant REFRESH_CYCLES : integer := (MEM_CTRL_CLK_FREQ_KHZ / 55500) + 1;
    signal refresh_counter  : integer := 0;


    -- unused
    constant CMD_RESET_ENABLE : std_logic_vector(7 downto 0) := x"66";
    constant CMD_RESET        : std_logic_vector(7 downto 0) := x"99";

    constant CMD_QUAD_ENABLE    : std_logic_vector(7 downto 0) := x"35";
    constant CMD_QUAD_WRITE     : std_logic_vector(7 downto 0) := x"38";
    constant CMD_FAST_QUAD_READ : std_logic_vector(7 downto 0) := x"EB";

    constant FAST_QUAD_READ_WAIT_CYCLES : integer := 6;
    constant FAST_QUAD_READ_WAIT_BYTES  : integer := FAST_QUAD_READ_WAIT_CYCLES/2;

    -- 19.5MHz MEM_CTRL_CLK_FREQ_HZ is the minimum for 32 byte burst
    -- as CSn can't be asserted for more than 8us

    --   BYTES  | Efficiency    | Min MEM_CTRL Freq | Approx BW at 84MHz SPI CLK
    -- ---------|---------------|-------------------|---------------------------
    --      1   | 12.5%         |  4.0 MHz          |   10.5 MB/s
    --      2   | 22.2%         |  4.5 MHz          |   18.7 MB/s
    --      4   | 36.4%         |  5.5 MHz          |   30.5 MB/s
    --      8   | 53.3%         |  7.5 MHz          |   44.8 MB/s
    --     16   | 69.6%         | 11.5 MHz          |   58.4 MB/s
    --     32   | 82.1%         | 19.5 MHz          |   68.9 MB/s
    --     64   | 90.1%         | 35.5 MHz          |   75.7 MB/s
    --    128   | 94.8%         | 67.5 MHz          |   79.6 MB/s

    signal psram_qpi_so           : std_logic_vector(3 downto 0);
    signal psram_qpi_si           : std_logic_vector(3 downto 0);
    signal psram_qpi_io_dir_input : std_logic := '1'; -- '1' for input, '0' for output

    signal psram_spi_so : std_logic;
    signal psram_spi_si : std_logic;

    signal mode_qpi : std_logic := '0';

    type t_state is (PWR_ON, ENTER_QUAD, IDLE, QPI_READ_CMD, QPI_READ_WAIT, QPI_READ_DATA, QPI_READ_DONE_HOLD_CSN, QPI_WRITE_CMD, QPI_WRITE_DATA, XCHG_BYTES_START, XCHG_BYTES_NEGEDGE, XCHG_BYTES_POSEDGE, CMD_DONE, QPI_DATA, CHECK_CONTINUE);
    signal state              : t_state := PWR_ON;
    -- set XCHG buffer to fit CMD+ADDR (4 bytes)
    constant XCHG_BUFFER_SIZE_BYTES : integer := 4;
    signal xchg_buffer        : std_logic_vector(XCHG_BUFFER_SIZE_BYTES * 8 - 1 downto 0);
    signal xchg_num_bytes     : integer;
    signal xchg_bytes_counter : integer;
    signal xchg_return_state  : t_state := PWR_ON;
    signal xchg_done_stb      : std_logic;

begin

    process
    begin
        report "MEM_CTRL_CLK_PERIOD: " & to_string(MEM_CTRL_CLK_PERIOD);
        report "MAX_CSN_ASSERT     : " & to_string(MAX_CSN_ASSERT);
        report "MAX_CSN_ASSERT_CYCLES : " & to_string(to_integer(MAX_CSN_ASSERT_CYCLES));
        wait;
    end process;

    -- Main controller process
    process (mem_ctrl_clk)
        variable bits_transferred : integer;
    begin
        if rising_edge(mem_ctrl_clk) then
            if reset = '1' then
                state <= PWR_ON;
                cmd_ready <= '0';
                rsp_valid <= '0';
            else
                -- defaults
                cmd_ready <= '0';
                rsp_valid <= '0';
                csn_asserted_counter <= csn_asserted_counter + to_unsigned(1, C_CSN_COUNT_W);
                xchg_done_stb <= '0';
                case state is
                        --------------------------------------------------------------------------------
                        -- Start init process
                        --------------------------------------------------------------------------------
                    when PWR_ON =>
                        psram_cs_n             <= '1';
                        psram_clk              <= '0';
                        mode_qpi               <= '0';
                        psram_qpi_io_dir_input <= '1'; -- default to Hi-Z
                        cmd_ready              <= '0';
                        bits_transferred := 0;
                        -- wait for 150us (not implemented) then move to next state
                        state           <= ENTER_QUAD;
                        refresh_counter <= 0;

                        --------------------------------------------------------------------------------
                        -- Send Enter Quad Mode command over SPI
                        --------------------------------------------------------------------------------
                    when ENTER_QUAD =>
                        psram_qpi_io_dir_input <= '0'; -- set to OUTPUT (although this is SPI mode anyway)
                        csn_asserted_counter <= (others => '0');
                        psram_cs_n                                                    <= '0'; -- start PSRAM transaction
                        xchg_buffer(xchg_buffer'left downto xchg_buffer'left - 8 + 1) <= CMD_QUAD_ENABLE; -- set top byte
                        xchg_num_bytes                                                <= 1;
                        xchg_bytes_counter                                            <= 0;
                        xchg_return_state                                             <= CMD_DONE;
                        state                                                         <= XCHG_BYTES_START;

                        --------------------------------------------------------------------------------
                        -- Deassert Chip Select and psram_busy, move to IDLE
                        --------------------------------------------------------------------------------
                    when CMD_DONE =>
                        psram_cs_n      <= '1';
                        assert csn_asserted_counter < MAX_CSN_ASSERT_CYCLES
                            report "Check not asserted CSn for too long"
                            severity error;

                        psram_clk       <= '0';
                        mode_qpi        <= '1'; -- after ENTER QUAD command done, we are in QPI mode

                        refresh_counter <= refresh_counter + 1;
                        if refresh_counter + 1 = REFRESH_CYCLES then
                            cmd_ready <= '1';
                            state      <= IDLE;
                        end if;

                        --------------------------------------------------------------------------------
                        -- Wait for next burst
                        --------------------------------------------------------------------------------
                    when IDLE =>
                        cmd_ready <= '1';
                        refresh_counter <= 0;
                        if cmd_valid = '1' then -- and cmd_ready, but that is always set on transition to IDLE
                            -- register byte read/write command
                            reg_cmd_address <= unsigned(cmd_address_in);
                            reg_cmd_wdata <= cmd_wdata_in;
                            reg_cmd_we <= cmd_we_in;
                            -- drop cmd_ready while we set up transaction
                            cmd_ready <= '0';
                            if cmd_we_in = '1' then
                                state <= QPI_WRITE_CMD;
                            else
                                state <= QPI_READ_CMD;
                            end if;
                        end if;

                        --------------------------------------------------------------------------------
                        -- Send QPI Write command
                        --------------------------------------------------------------------------------
                    when QPI_WRITE_CMD =>
                        psram_cs_n <= '0'; -- start PSRAM transaction
                        csn_asserted_counter <= (others => '0');
                        -- set top byte
                        xchg_buffer(xchg_buffer'left downto xchg_buffer'left - 8 + 1) <= CMD_QUAD_WRITE;
                        -- set address bytes
                        xchg_buffer(xchg_buffer'left - 8 * 1 downto xchg_buffer'left - 8 * (1 + 1) + 1) <= '0' & std_logic_vector(reg_cmd_address(22 downto 16));
                        xchg_buffer(xchg_buffer'left - 8 * 2 downto xchg_buffer'left - 8 * (2 + 1) + 1) <= std_logic_vector(reg_cmd_address(15 downto 8));
                        xchg_buffer(xchg_buffer'left - 8 * 3 downto xchg_buffer'left - 8 * (3 + 1) + 1) <= std_logic_vector(reg_cmd_address(7 downto 0));

                        psram_qpi_io_dir_input <= '0'; -- set to OUTPUT
                        xchg_num_bytes         <= 4;
                        xchg_bytes_counter     <= 0;
                        xchg_return_state      <= QPI_DATA;
                        state                  <= XCHG_BYTES_START;
                        ----------------------------------------------------------------------------------
                        -- Send QPI Data
                        --------------------------------------------------------------------------------
                    when QPI_DATA =>
                        xchg_buffer(31 downto 24) <= reg_cmd_wdata;
                        xchg_num_bytes            <= 1;
                        xchg_bytes_counter        <= 0;
                        state                     <= XCHG_BYTES_START;
                        xchg_return_state         <= CHECK_CONTINUE;
                        if reg_cmd_we = '1' then
                            psram_qpi_io_dir_input    <= '0'; -- set to OUTPUT
                        else
                            psram_qpi_io_dir_input <= '1'; -- set to INPUT
                        end if;
                        --------------------------------------------------------------------------------
                        -- Check if we can continue the read/write burst with the next command
                        --------------------------------------------------------------------------------
                    when CHECK_CONTINUE =>
                        if xchg_done_stb = '1' then -- byte transfer done (only do this once, hence triggered by one-cycle pulse)
                            rsp_rdata_out <= xchg_buffer(7 downto 0);   -- bottom byte was most recently shifted into
                            rsp_valid <= '1'; -- one cycle pulse
                        end if;
                        -- check we have time left in the burst
                        if csn_asserted_counter < (MAX_CSN_ASSERT_CYCLES - ONE_MORE_BYTE_CYCLES) and
                        (   -- if command available and continues the burst
                            (cmd_valid = '1' and cmd_we_in = reg_cmd_we and unsigned(cmd_address_in) = reg_cmd_address + to_unsigned(1, 23))
                            or cmd_valid = '0' -- if no command is available, hold the burst open anyway in case next transaction continues it, as there is only a small latency penalty
                        ) then
                            if cmd_valid = '1' then -- accept next command to contine the burst
                                cmd_ready <= '1'; -- one cycle pulse
                                reg_cmd_address <= unsigned(cmd_address_in);
                                reg_cmd_wdata <= cmd_wdata_in;
                                state <= QPI_DATA;
                            end if;
                        else -- close the burst as we have timed out, or next CMD is part of a new burst
                            if reg_cmd_we = '1' then
                                state         <= CMD_DONE;
                                psram_qpi_io_dir_input    <= '0'; -- set to OUTPUT
                            else
                                state      <= QPI_READ_DONE_HOLD_CSN;
                                psram_qpi_io_dir_input <= '1'; -- set to INPUT
                            end if;
                        end if;
                        --------------------------------------------------------------------------------
                        -- Send QPI Read command
                        --------------------------------------------------------------------------------
                    when QPI_READ_CMD =>
                        psram_cs_n <= '0'; -- start PSRAM transaction
                        csn_asserted_counter <= (others => '0');
                        -- set top byte
                        xchg_buffer(xchg_buffer'left downto xchg_buffer'left - 8 + 1) <= CMD_FAST_QUAD_READ;
                        -- set address bytes
                        xchg_buffer(xchg_buffer'left - 8 * 1 downto xchg_buffer'left - 8 * (1 + 1) + 1) <= '0' & std_logic_vector(reg_cmd_address(22 downto 16));
                        xchg_buffer(xchg_buffer'left - 8 * 2 downto xchg_buffer'left - 8 * (2 + 1) + 1) <= std_logic_vector(reg_cmd_address(15 downto 8));
                        xchg_buffer(xchg_buffer'left - 8 * 3 downto xchg_buffer'left - 8 * (3 + 1) + 1) <= std_logic_vector(reg_cmd_address(7 downto 0));

                        psram_qpi_io_dir_input <= '0'; -- set to OUTPUT
                        xchg_num_bytes         <= 4;
                        xchg_bytes_counter     <= 0;
                        xchg_return_state      <= QPI_READ_WAIT;
                        state                  <= XCHG_BYTES_START;

                        --------------------------------------------------------------------------------
                        -- QPI Read Wait States
                        --------------------------------------------------------------------------------
                    when QPI_READ_WAIT =>
                        xchg_num_bytes         <= FAST_QUAD_READ_WAIT_BYTES;
                        xchg_bytes_counter     <= 0;
                        xchg_return_state      <= QPI_DATA;
                        state                  <= XCHG_BYTES_START;
                        psram_qpi_io_dir_input <= '1'; -- set to INPUT for Hi-Z

                        --------------------------------------------------------------------------------
                        -- Wait 1 cycle before deasserting Chip Select to ensure we latch correctly
                        --------------------------------------------------------------------------------
                    when QPI_READ_DONE_HOLD_CSN =>
                        psram_clk <= '0';
                        state     <= CMD_DONE;

                        --------------------------------------------------------------------------------
                        -- subroutine to send bytes from a buffer
                        --------------------------------------------------------------------------------
                    when XCHG_BYTES_START => -- set up initial bit(s) on the bus
                        psram_clk <= '0';
                        if mode_qpi = '1' then
                            psram_qpi_so <= xchg_buffer(xchg_buffer'left downto xchg_buffer'left - 4 + 1); -- set from top 4 bits
                        else
                            psram_spi_so <= xchg_buffer(xchg_buffer'left); -- set from top bit
                        end if;
                        state <= XCHG_BYTES_POSEDGE;
                        --------------------------------------------------------------------------------
                    when XCHG_BYTES_NEGEDGE =>
                        if mode_qpi = '1' then
                            psram_qpi_so <= xchg_buffer(xchg_buffer'left downto xchg_buffer'left - 4 + 1); -- set from top 4 bits
                        else
                            psram_spi_so <= xchg_buffer(xchg_buffer'left); -- set from top bit
                        end if;
                        psram_clk <= '0'; -- now generate negedge
                        state     <= XCHG_BYTES_POSEDGE;
                        --------------------------------------------------------------------------------
                    when XCHG_BYTES_POSEDGE =>
                        if mode_qpi = '1' then
                            xchg_buffer <= xchg_buffer(xchg_buffer'left - 4 downto 0) & psram_qpi_si; -- and shift in
                            -- report "shifted in " & to_hstring(psram_qpi_si);
                            bits_transferred := bits_transferred + 4;
                        else
                            xchg_buffer <= xchg_buffer(xchg_buffer'left - 1 downto 0) & psram_spi_si; -- and shift in
                            bits_transferred := bits_transferred + 1;
                        end if;
                        psram_clk <= '1'; --now generate posedge
                        state     <= XCHG_BYTES_NEGEDGE;
                        -- unless we have finished our transfer
                        if bits_transferred = 8 then
                            bits_transferred := 0;
                            xchg_bytes_counter <= xchg_bytes_counter + 1;
                            if xchg_bytes_counter + 1 = xchg_num_bytes then
                                state <= xchg_return_state;
                                xchg_done_stb <= '1'; -- one cycle pulse
                            end if;
                        end if;
                        --------------------------------------------------------------------------------
                    when others =>
                        state <= PWR_ON;
                end case;
            end if;
        end if;
    end process;

    -- infer IOBUFs (TODO check for correct inference!)
    process (all)
    begin
        -- default all 0's
        psram_qpi_si <= "0000";
        psram_spi_si <= '0';
        if mode_qpi then
            psram_sio <= psram_qpi_so when psram_qpi_io_dir_input = '0' else
                "ZZZZ";
            psram_qpi_si <= psram_sio;
        else
            psram_sio(0)          <= psram_spi_so; -- Serial IN for APS6404, Serial OUT for controller
            psram_sio(3 downto 1) <= "ZZZ";
            psram_spi_si          <= psram_sio(1); -- Serial OUT for APS6404, Serial IN for controller
        end if;
    end process;

end architecture;