library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Simple burst-driven controller for APS6404 PSRAM
--! Bursts are read from and written to this controller all in one cycle, making it only suitable for short bursts
--!
entity psram_aps6404_ctrl is
    generic
    (
        MEM_CTRL_CLK_FREQ_KHZ : integer := 25000; -- MEM SPI CLK is half this
        BURST_LENGTH_BYTES    : integer := 4 --  the higher the frequency, the higher the max burst
    );
    port
    (
        mem_ctrl_clk : in std_logic;
        reset        : in std_logic;

        -- command
        burst_start_byte_address : in std_logic_vector(22 downto 0);
        burst_start              : in std_logic;
        burst_write              : in std_logic;

        -- data in (valid with burst_start)
        wdata_in : in std_logic_vector(BURST_LENGTH_BYTES * 8 - 1 downto 0);

        -- data out (valid with burst_done)
        burst_done : out std_logic;
        rdata_out  : out std_logic_vector(BURST_LENGTH_BYTES * 8 - 1 downto 0);

        psram_busy : out std_logic; -- ready for next burst

        -- PSRAM IO
        psram_clk  : out std_logic;
        psram_cs_n : out std_logic;
        psram_sio  : inout std_logic_vector(3 downto 0)

    );
end entity psram_aps6404_ctrl;

architecture rtl of psram_aps6404_ctrl is
    constant PSRAM_CLK_FREQ_KHZ : integer := MEM_CTRL_CLK_FREQ_KHZ / 2; -- spi clk



    constant MAX_BURST_CYCLES   : integer := 8 * PSRAM_CLK_FREQ_KHZ / 1000; -- 8us per burst
    constant MAX_BURST_BYTES    : integer := (MAX_BURST_CYCLES - 14) / 2;

    constant PWR_ON_DELAY_CYCLES : integer := 150 * MEM_CTRL_CLK_FREQ_KHZ / 1000; -- 150us

    -- set XCHG buffer as large of CMD+ADDR (4 bytes) or burst buffer
    function f_get_buf_size(burst_len : integer) return integer is
        variable buf_size                 : integer;
    begin
        if (4 > burst_len) then
            return 4;
        else
            return burst_len;
        end if;
    end function;

    constant XCHG_BUFFER_SIZE_BYTES : integer := f_get_buf_size(BURST_LENGTH_BYTES);

    -- unused
    constant CMD_RESET_ENABLE : std_logic_vector(7 downto 0) := x"66";
    constant CMD_RESET        : std_logic_vector(7 downto 0) := x"99";

    constant CMD_QUAD_ENABLE    : std_logic_vector(7 downto 0) := x"35";
    constant CMD_QUAD_WRITE     : std_logic_vector(7 downto 0) := x"38";
    constant CMD_FAST_QUAD_READ : std_logic_vector(7 downto 0) := x"EB";

    constant FAST_QUAD_READ_WAIT_CYCLES : integer := 6;
    constant FAST_QUAD_READ_WAIT_BYTES  : integer := FAST_QUAD_READ_WAIT_CYCLES/2;

    -- 19.5MHz MEM_CTRL_CLK_FREQ_HZ is the minimum for 32 byte burst

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

    type t_state is (PWR_ON, ENTER_QUAD, IDLE, QPI_READ_CMD, QPI_READ_WAIT, QPI_READ_DATA, QPI_READ_DONE_HOLD_CSN, QPI_WRITE_CMD, QPI_WRITE_DATA, XCHG_BYTES_START, XCHG_BYTES_NEGEDGE, XCHG_BYTES_POSEDGE, CMD_DONE);
    signal state              : t_state := PWR_ON;
    signal xchg_buffer        : std_logic_vector(XCHG_BUFFER_SIZE_BYTES * 8 - 1 downto 0);
    signal xchg_num_bytes     : integer;
    signal xchg_bytes_counter : integer;
    signal xchg_return_state  : t_state := PWR_ON;

begin
    assert BURST_LENGTH_BYTES <= MAX_BURST_BYTES
    report "Selected Burst Length " & integer'image(BURST_LENGTH_BYTES) & " larger than max supported burst (" & integer'image(MAX_BURST_BYTES) & ") for currently selected mem controller frequency."
        severity failure;

    -- Main controller process
    process (mem_ctrl_clk)
        variable bits_transferred : integer;
    begin
        if rising_edge(mem_ctrl_clk) then
            if reset = '1' then
                state <= PWR_ON;
            else
                burst_done <= '0'; -- default
                case state is
                        --------------------------------------------------------------------------------
                        -- Start init process
                        --------------------------------------------------------------------------------
                    when PWR_ON =>
                        psram_cs_n             <= '1';
                        psram_clk              <= '0';
                        mode_qpi               <= '0';
                        psram_qpi_io_dir_input <= '1'; -- default to Hi-Z
                        psram_busy             <= '1';
                        bits_transferred := 0;
                        -- wait for 150us (not implemented) then move to next state
                        state <= ENTER_QUAD;

                        --------------------------------------------------------------------------------
                        -- Send Enter Quad Mode command over SPI
                        --------------------------------------------------------------------------------
                    when ENTER_QUAD =>
                        psram_qpi_io_dir_input <= '0'; -- set to OUTPUT (although this is SPI mode anyway)

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
                        psram_cs_n <= '1';
                        psram_clk  <= '0';
                        mode_qpi   <= '1'; -- after ENTER QUAD command done, we are in QPI mode
                        psram_busy <= '0';
                        rdata_out  <= xchg_buffer(BURST_LENGTH_BYTES * 8 - 1 downto 0); -- if not a read, this will be junk
                        burst_done <= '1'; -- high for 1 cycle
                        state      <= IDLE;

                        --------------------------------------------------------------------------------
                        -- Wait for next burst
                        --------------------------------------------------------------------------------
                    when IDLE =>
                        if burst_start = '1' then
                            psram_busy <= '1';
                            if burst_write = '1' then
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
                        -- set top byte
                        xchg_buffer(xchg_buffer'left downto xchg_buffer'left - 8 + 1) <= CMD_QUAD_WRITE;
                        -- set address bytes
                        xchg_buffer(xchg_buffer'left - 8 * 1 downto xchg_buffer'left - 8 * (1 + 1) + 1) <= '0' & burst_start_byte_address(22 downto 16);
                        xchg_buffer(xchg_buffer'left - 8 * 2 downto xchg_buffer'left - 8 * (2 + 1) + 1) <= burst_start_byte_address(15 downto 8);
                        xchg_buffer(xchg_buffer'left - 8 * 3 downto xchg_buffer'left - 8 * (3 + 1) + 1) <= burst_start_byte_address(7 downto 0);

                        psram_qpi_io_dir_input <= '0'; -- set to OUTPUT
                        xchg_num_bytes         <= 4;
                        xchg_bytes_counter     <= 0;
                        xchg_return_state      <= QPI_WRITE_DATA;
                        state                  <= XCHG_BYTES_START;
                        --------------------------------------------------------------------------------
                        -- Send QPI Write Data
                        --------------------------------------------------------------------------------
                    when QPI_WRITE_DATA =>
                        xchg_buffer(BURST_LENGTH_BYTES * 8 - 1 downto 0) <= wdata_in;
                        xchg_num_bytes                                   <= BURST_LENGTH_BYTES;
                        xchg_bytes_counter                               <= 0;
                        xchg_return_state                                <= CMD_DONE;
                        state                                            <= XCHG_BYTES_START;
                        psram_qpi_io_dir_input                           <= '0'; -- set to OUTPUT

                        --------------------------------------------------------------------------------
                        -- Send QPI Read command
                        --------------------------------------------------------------------------------
                    when QPI_READ_CMD =>
                        psram_cs_n <= '0'; -- start PSRAM transaction
                        -- set top byte
                        xchg_buffer(xchg_buffer'left downto xchg_buffer'left - 8 + 1) <= CMD_FAST_QUAD_READ;
                        -- set address bytes
                        xchg_buffer(xchg_buffer'left - 8 * 1 downto xchg_buffer'left - 8 * (1 + 1) + 1) <= '0' & burst_start_byte_address(22 downto 16);
                        xchg_buffer(xchg_buffer'left - 8 * 2 downto xchg_buffer'left - 8 * (2 + 1) + 1) <= burst_start_byte_address(15 downto 8);
                        xchg_buffer(xchg_buffer'left - 8 * 3 downto xchg_buffer'left - 8 * (3 + 1) + 1) <= burst_start_byte_address(7 downto 0);

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
                        xchg_return_state      <= QPI_READ_DATA;
                        state                  <= XCHG_BYTES_START;
                        psram_qpi_io_dir_input <= '1'; -- set to INPUT for Hi-Z

                        --------------------------------------------------------------------------------
                        -- Receive QPI Read Data
                        --------------------------------------------------------------------------------
                        when QPI_READ_DATA =>
                        xchg_num_bytes         <= BURST_LENGTH_BYTES;
                        xchg_bytes_counter     <= 0;
                        xchg_return_state      <= QPI_READ_DONE_HOLD_CSN;
                        state                  <= XCHG_BYTES_START;
                        psram_qpi_io_dir_input <= '1'; -- set to INPUT

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