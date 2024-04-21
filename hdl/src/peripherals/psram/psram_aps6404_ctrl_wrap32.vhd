library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;

library unisim;
use unisim.vcomponents.all;

-- simplify the PSRAM clocking by inverting.
-- Uses 32-byte wrapping burst mode
-- designed to fill 32-byte cache lines
entity psram_aps6404_ctrl_wrap32 is
    generic
    (
        G_BURST_LEN : integer range 1 to 32 := 32; --! 32-byte max as using wrap32 mode for faster potential clock speeds
        G_FREQ_KHZ : integer := 75000; -- 75MHz to start? Aim for 109MHz+
        G_SIM      : boolean := false -- skip power on init (150us wait)
    );
    port
    (
        clk   : in std_logic;
        reset : in std_logic;

        -- command
        cmd_valid      : in std_logic;
        cmd_ready      : out std_logic := '0';
        cmd_address_in : in std_logic_vector(24 downto 0); -- 32MB for 4 PSRAM chips
        cmd_we_in      : in std_logic;
        cmd_wdata_in    : in std_logic_vector(G_BURST_LEN*8-1 downto 0);

        -- response (no backpressure)
        rsp_valid     : out std_logic := '0';
        rsp_rdata_out : out std_logic_vector(G_BURST_LEN*8-1 downto 0);

        -- PSRAM IO
        psram_sel  : out std_logic_vector(1 downto 0); -- which PSRAM chip to select
        psram_clk  : out std_logic;
        psram_cs_n : out std_logic;
        psram_sio  : inout std_logic_vector(3 downto 0)

    );
end entity psram_aps6404_ctrl_wrap32;

architecture rtl of psram_aps6404_ctrl_wrap32 is

    --------------------------------------------------------------------------------
    -- Address Slicing
    --------------------------------------------------------------------------------
    -- which chip is selected
    constant PSRAM_SEL_HI : integer := 24;
    constant PSRAM_SEL_LO : integer := 23;     
    -- which 32-byte segment
    constant LINE_ADDR_HI : integer := 22;     
    constant LINE_ADDR_LO : integer := clog2(G_BURST_LEN);     
    -- position in 32-byte segment (TODO - start part way through 32B line to fetch specific data first)
    constant BYTE_ADDR_HI : integer := clog2(G_BURST_LEN)-1;
    constant BYTE_ADDR_LO : integer := 0;

    signal reg_address : std_logic_vector(23 downto 0) := (others => '0') ;
    signal reg_data : std_logic_vector(G_BURST_LEN*8-1 downto 0) := (others => '0') ;
    signal reg_we : std_logic;
    
    --eg 44 go throughs of a 256 cycle counter @ 75MHz
    constant PWR_ON_DELAY_CYCLES : integer              := 150 * G_FREQ_KHZ / 1000; -- 150us
    constant PWR_ON_DELAY_COUNT  : integer              := (PWR_ON_DELAY_CYCLES / 256) + 1;
    signal power_on_counter      : unsigned(7 downto 0) := to_unsigned(PWR_ON_DELAY_COUNT, 8); -- power on done when "11111"

    -- We need 18ns of CS_N deasserted between each burst for DRAM auto-refresh
    -- 18ns = 55.5 MHzconstant PSRAM_REFRESH_TARGET : time := 18 ns;
    constant REFRESH_CYCLES : integer := (G_FREQ_KHZ / 55500) + 1;

    -- Propagation delay for SN74HCS138 decoder used for SSn/CSn on Machdyne PSRAM PMOD is 33ns max (at 2V)
    -- At 4.5V it's only 12ns max, which is a fair bit nicer, but the datasheet has no data for 3V3

    -- 33ns = 30.303 MHz. Max is 5 cycles for 133MHz PSRAM clock.
    -- This does mean we won't have to worry about one extra cycle for read data hold though, hah.
    constant CHIP_SELECT_CHANGE_CYCLES : integer              := (G_FREQ_KHZ / 30303) + 1;
    constant CHIP_SELECT_CHANGE_U      : unsigned(7 downto 0) := to_unsigned(CHIP_SELECT_CHANGE_CYCLES, 8);
    
    constant CMD_RESET_ENABLE : std_logic_vector(7 downto 0) := x"66";
    constant CMD_RESET        : std_logic_vector(7 downto 0) := x"99";

    constant CMD_QUAD_ENABLE    : std_logic_vector(7 downto 0) := x"35";
    constant CMD_QUAD_WRITE     : std_logic_vector(7 downto 0) := x"38";
    constant CMD_FAST_QUAD_READ : std_logic_vector(7 downto 0) := x"EB";

    constant FAST_QUAD_READ_WAIT_CYCLES : integer := 6;
    constant FAST_QUAD_READ_WAIT_BYTES  : integer := FAST_QUAD_READ_WAIT_CYCLES/2;

    signal cycle_counter : unsigned(7 downto 0) := x"00";

    type t_state is (PWR_ON, INIT, IDLE, QPI_CMD_ADDR, QPI_WAIT, QPI_DATA, REFRESH);
    signal state : t_state := PWR_ON;

    signal psram_clk_en : std_logic            := '0';
    signal psram_sel_u  : unsigned(1 downto 0) := "00";

    signal psram_qpi_sio_out      : std_logic_vector(3 downto 0); -- TO APS6404
    signal psram_qpi_sio_in       : std_logic_vector(3 downto 0); -- FROM APS6404
    signal psram_qpi_io_dir_input : std_logic := '1'; -- '1' for input, '0' for output

    signal reg_psram_qpi_sio_in   : std_logic_vector(3 downto 0); -- FROM APS6404, registered
    -- (place in IOB flop for better timing)
    attribute IOB : string;
    attribute IOB of reg_psram_qpi_sio_in : signal is "TRUE";
    
    signal psram_spi_so : std_logic;
--    signal psram_spi_si : std_logic;  -- not used
 
    signal mode_qpi : std_logic := '0';

    signal psram_cmd_addr : std_logic_vector(31 downto 0);
       
begin

    psram_sel <= std_logic_vector(psram_sel_u);

    process (clk)
        variable rdata : std_logic_vector(G_BURST_LEN*8-1 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= PWR_ON;
            else
                -- defaults
                cycle_counter       <= cycle_counter + unsigned'(x"01"); -- 0-255, rolls over
                rsp_valid <= '0';
                case state is
                    when PWR_ON => -- Wait for 150us before INIT
                        psram_cs_n             <= '1';
                        psram_clk_en           <= '0';
                        cmd_ready              <= '0';
                        psram_qpi_io_dir_input <= '0'; -- output
                        mode_qpi               <= '1'; -- assume qpi mode
                        if cycle_counter = x"00" then -- 256 cycles
                            power_on_counter <= power_on_counter - unsigned'("00001");
                            if G_SIM then -- skip rest of power-on-wait
                                power_on_counter <= x"00";
                                psram_sel_u      <= "00"; -- start INIT of PSRAM0
                                cycle_counter    <= x"00";
                                state            <= INIT;
                            end if;
                        end if;
                        if power_on_counter = x"00" then
                            psram_sel_u   <= "00"; -- start INIT of PSRAM0    
                            cycle_counter <= x"00";
                            state         <= INIT;
                        end if;

                    when INIT => -- reset and init all PSRAMs in sequence
                        case cycle_counter is
                            when x"00" => -- =========== QPI RST_EN 0x66 ==================== 
                                psram_cs_n <= '0'; -- start assert of CSn (watch out for propagation delay)
                            when x"06" => -- chip select propagated, start the clock and send RST_EN 0x66
                                psram_clk_en      <= '1';
                                psram_qpi_sio_out <= x"6";
                            when x"07" =>
                                psram_qpi_sio_out <= x"6";
                            when x"08" => -- stop the clock, start deasserting CSn
                                psram_clk_en <= '0';
                                psram_cs_n   <= '1';
                            when x"10" => -- =========== QPI RST 0x99 ==================== 
                                psram_cs_n <= '0'; -- start assert of CSn (watch out for propagation delay)
                            when x"16" => -- chip select propagated, start the clock and send RST 0x99
                                psram_clk_en      <= '1';
                                psram_qpi_sio_out <= x"9";
                            when x"17" =>
                                psram_qpi_sio_out <= x"9";
                            when x"18" => -- stop the clock, start deasserting CSn
                                psram_clk_en <= '0';
                                psram_cs_n   <= '1';
                                -- After approx 50ns for reset to complete
                            when x"20" => -- =========== SPI Enter Quad 0x35 ==================== 
                                psram_cs_n <= '0'; -- start assert of CSn (watch out for propagation delay)
                                mode_qpi   <= '0'; -- now in SPI mode
                            when x"26" => -- chip select propagated, start the clock and send SPI Enter Quad 0x35 ("00110101")
                                psram_clk_en <= '1';
                                psram_spi_so <= '0';
                            when x"27" =>
                                psram_spi_so <= '0';
                            when x"28" =>
                                psram_spi_so <= '1';
                            when x"29" =>
                                psram_spi_so <= '1';
                            when x"2a" =>
                                psram_spi_so <= '0';
                            when x"2b" =>
                                psram_spi_so <= '1';
                            when x"2c" =>
                                psram_spi_so <= '0';
                            when x"2d" =>
                                psram_spi_so <= '1'; -- last bit of SPI Enter Quad
                            when x"2e" => -- stop the clock, start deasserting CSn
                                psram_clk_en <= '0';
                                psram_cs_n   <= '1';
                                mode_qpi     <= '1'; -- back in QPI mode
                            when x"30" => -- =========== Wrap32 Toggle 0xC0 ====================
                                psram_cs_n <= '0'; -- start assert of CSn (watch out for propagation delay)
                            when x"36" => -- chip select propagated, start the clock
                                psram_clk_en      <= '1';
                                psram_qpi_sio_out <= x"C";
                            when x"37" =>
                                psram_qpi_sio_out <= x"0";
                            when x"38" => -- stop the clock, start deasserting CSn
                                psram_clk_en <= '0';
                                psram_cs_n   <= '1';
                                -- =============== PSRAM INIT done ===================
                            when x"50" => --move to next PSRAM and reset cycle counter
                                if psram_sel_u = "11" then
                                    state <= IDLE; -- All PSRAMs init'ed
                                    cmd_ready <= '1';
                                else
                                    psram_sel_u   <= psram_sel_u + unsigned'("01");
                                    cycle_counter <= x"00";
                                end if;
                            when others => null;
                        end case;
                    when IDLE =>
                        if cmd_valid and cmd_ready then -- accept command
                            cmd_ready <= '0'; 
                            reg_address(LINE_ADDR_HI downto LINE_ADDR_LO) <= cmd_address_in(LINE_ADDR_HI downto LINE_ADDR_LO); -- leave byte sel as zeros for now
                            reg_data <= byte_swap(cmd_wdata_in); -- swap byte order so we send LSB first
                            reg_we <= cmd_we_in;
                            psram_sel_u <= unsigned(cmd_address_in(PSRAM_SEL_HI downto PSRAM_SEL_LO));  -- select which PSRAM we are accessing
                            psram_cs_n <= '0'; -- and start waiting for CSn to propagate
                            psram_qpi_io_dir_input <= '0'; -- set SIO to output
                            cycle_counter <= x"00";
                        end if;
                        if cycle_counter = CHIP_SELECT_CHANGE_U-1  and psram_cs_n = '0' then -- CSn should have propageted to the selected PSRAM now
                            state <= QPI_CMD_ADDR;
                            psram_cmd_addr(31 downto 24) <= CMD_QUAD_WRITE when reg_we else CMD_FAST_QUAD_READ; -- set command byte to send
                            psram_cmd_addr(23 downto  0) <= reg_address;
                            cycle_counter <= x"00";
                        end if;

                    when QPI_CMD_ADDR =>
                        psram_clk_en      <= '1'; -- start clock
                        psram_qpi_sio_out <= psram_cmd_addr(31 downto 28);        -- send top nibble
                        psram_cmd_addr(31 downto 0) <= psram_cmd_addr(27 downto 0) & x"0"; -- shift next nibble into position
                        if cycle_counter = 8-1 then -- 8 nibbles to transfer
                            cycle_counter <= x"00";
                            if reg_we then -- send write data
                                state <= QPI_DATA;
                            else -- wait for PSRAM to start sending RDATA
                                state <= QPI_WAIT;
                                
                            end if;
                        end if;

                    when QPI_WAIT => 
                        psram_qpi_io_dir_input <= '1';
                        if cycle_counter = FAST_QUAD_READ_WAIT_CYCLES+1-1 then -- wait one extra cycle as we are registering PSRAM_SIO on input
                            cycle_counter <= x"00";
                            state <= QPI_DATA;
                        end if;

                    when QPI_DATA => -- Data is transferred MSNibble of LSByte first, so we previously byte-swapped reg_data
                        psram_qpi_sio_out <= reg_data(reg_data'left downto reg_data'left-3);
                        reg_data(reg_data'left downto 0) <= reg_data(reg_data'left-4 downto 0) & reg_psram_qpi_sio_in;
                        
                        if cycle_counter = G_BURST_LEN*2 then -- all data transferred
                            psram_clk_en <= '0';    -- stop the clock
                            cycle_counter <= x"00";
                            state <= REFRESH;
                            rdata := reg_data(reg_data'left-4 downto 0) & reg_psram_qpi_sio_in;
                            rsp_rdata_out <= byte_swap(rdata);
                            rsp_valid <= '1'; -- one cycle pulse

                        end if;
                    
                    when REFRESH => 
                        psram_cs_n   <= '1'; -- start deasserting CSn
                        if cycle_counter = REFRESH_CYCLES then 
                            state <= IDLE;
                            cmd_ready <= '1';
                        end if;

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    -- Register the Input Data (place in IOB reg for better timing)
    process (clk)
    begin
        if rising_edge(clk) then
            reg_psram_qpi_sio_in <= psram_qpi_sio_in;
        end if;
    end process;


    process (all)
    begin
        psram_qpi_sio_in <= psram_sio;
--        psram_spi_si     <= '0';
        if mode_qpi then
            psram_sio <= psram_qpi_sio_out when psram_qpi_io_dir_input = '0' else
                "ZZZZ";
        else
            psram_sio(0)          <= psram_spi_so; -- Serial IN for APS6404, Serial OUT for controller
            psram_sio(3 downto 1) <= "ZZZ";
--            psram_spi_si          <= psram_sio(1); -- Serial OUT for APS6404, Serial IN for controller
        end if;
    end process;

    -- Invert the clock and forward to PSRAM
    ODDR_inst : ODDR
    generic
    map(
    DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
    INIT         => '0', -- Initial value for Q port ('1' or '0')
    SRTYPE       => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
    port map
    (
        Q  => psram_clk, -- 1-bit DDR output
        C  => clk, -- 1-bit clock input
        CE => psram_clk_en, -- 1-bit clock enable input
        D1 => '0', -- 1-bit data input (positive edge)
        D2 => '1', -- 1-bit data input (negative edge)
        R  => '0', -- 1-bit reset input
        S  => '0' -- 1-bit set input
    );

end architecture;