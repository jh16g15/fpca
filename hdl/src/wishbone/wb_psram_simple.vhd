library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all; -- 32 bit port, 8 bit granularity

--! A simple wishbone slave for individual 32-bit reads/writes to PSRAM. Very Inefficient!
--! But good for easy interfacing with an embedded processor where high speed access is not required.
--! For use with the Sipeed Tang Nano boards
--! This wishbone slave connects up to a "User Port" channel of a Gowin FPGA
--! psram_memory_interface_hs_2ch
--!
--! TODO:
--!     - support byte-level reads
--!
entity wb_psram_simple is
    generic (
        G_BURST_LEN : integer := 16; -- 32, 64, 128
        G_PSRAM_ADDR_W : integer := 21  -- 64Mbit organised into 2^21 16-bit words
    );
    port (
        wb_clk   : in std_logic;    -- usrclk (clk_out from psram IP)
        wb_reset : in std_logic;

        wb_mosi_in : in t_wb_mosi;
        wb_miso_out  : out t_wb_miso;
        -- to PSRAM IP
        wdata_out : out std_logic_vector(C_WB_DATA_W-1 downto 0);
        data_mask_out : out std_logic_vector(C_WB_SEL_W-1 downto 0);
        rdata_in : in std_logic_vector(C_WB_DATA_W-1 downto 0);
        rd_data_valid_in : in std_logic;
        addr_out : out std_logic_vector(G_PSRAM_ADDR_W-1 downto 0);
        cmd_out : out std_logic;
        cmd_en_out : out std_logic;
        init_calib_in : in std_logic
    );
end entity wb_psram_simple;

architecture rtl of wb_psram_simple is
    type t_state is (INIT, IDLE, WRITING, WAIT_FOR_RVALID, READING);
    signal state : t_state := INIT;

    -- requirements from PSRAM IP (max 43 cycles for burst length of 128)
    constant C_MIN_COMMAND_INTERVAL : unsigned(5 downto 0) := to_unsigned(G_BURST_LEN/4 + 11, 6);

    -- number of cycles the PSRAM IP user channel is expecting/outputting data
    constant C_DATA_CYCLES : unsigned(5 downto 0) := to_unsigned(G_BURST_LEN/4, 6);

    signal cmd_cycle_count : unsigned(5 downto 0) := (others => '0');

    signal wait_done : std_logic;
begin

    process (wb_clk)
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                state <= INIT;
                wb_miso_out.ack <= '0';
                wb_miso_out.err <= '0';
                wb_miso_out.rty <= '0';
                wb_miso_out.stall <= '1';
                wb_miso_out.rdat <= x"DEADC0DE";    -- necessary?
            else
                case(state) is

                    when INIT =>    -- wait for PSRAM calibration to finish (takes a second or so)
                        wb_miso_out.ack <= '0';
                        wb_miso_out.stall <= '1';
                        cmd_en_out <= '0';
                        if init_calib_in = '1' then
                            state <= IDLE;
                            wb_miso_out.stall <= '0';   -- ready to receive a command
                        end if;
                    when IDLE =>    -- wait for a wishbone command to arrive
                        -- wb_miso_out.ack <= '0';
                        if wb_mosi_in.stb = '1' and wb_miso_out.stall = '0' then -- assume CYC asserted by master for STB to be high
                            -- common to reads and writes
                            addr_out <= wb_mosi_in.adr(G_PSRAM_ADDR_W-1+1 downto 1);    -- convert to 16 bit address
                            cmd_out <= wb_mosi_in.we; -- READ/WRITE
                            cmd_en_out <= '1';
                            cmd_cycle_count <= (others => '0'); -- reset cycle counter

                            wb_miso_out.stall <= '1'; -- and STALL until READ/WRITE complete

                            if wb_mosi_in.we = '1' then
                                -- write logic
                                wb_miso_out.ack <= '1'; -- ACK this cycle
                                wdata_out <= wb_mosi_in.wdat;
                                data_mask_out <= not wb_mosi_in.sel; -- data_mask = '1' if byte should not be written ("tie to 0 if masking not used")
                                state <= WRITING;
                            else
                                -- read logic
                                state <= WAIT_FOR_RVALID;
                                wait_done <= '0';
                            end if;

                        end if;

                    when WRITING => -- mask off the remaining wdata in the burst, and wait until Tcmd has passed
                        cmd_en_out <= '0';
                        wb_miso_out.ack <= '0';
                        data_mask_out <= (others => '1');   -- all remaining data writes in the burst are masked off
                        cmd_cycle_count <= cmd_cycle_count + to_unsigned(1,cmd_cycle_count'length); -- increment the cycle counter
                        if cmd_cycle_count = C_MIN_COMMAND_INTERVAL-1 then
                            state <= IDLE;
                            wb_miso_out.stall <= '0'; -- ready for next WB command

                        end if;

                    when WAIT_FOR_RVALID => -- wait until we start getting data back, and send a WB reply with the first word only
                        cmd_en_out <= '0';
                        cmd_cycle_count <= cmd_cycle_count + to_unsigned(1,cmd_cycle_count'length); -- increment the cycle counter

                        -- I would expect the RDATA to be returned before we hit our minimum command interval, but just
                        -- in case lets monitor that here
                        if cmd_cycle_count = C_MIN_COMMAND_INTERVAL-1 then
                            wait_done <= '1';
                        end if;

                        if rd_data_valid_in = '1' then
                            wb_miso_out.rdat <= rdata_in;
                            wb_miso_out.ack <= '1';
                            state <= READING;
                        end if;

                    when READING => -- wait until Tcmd has passed
                        wb_miso_out.ack <= '0';
                        cmd_cycle_count <= cmd_cycle_count + to_unsigned(1,cmd_cycle_count'length); -- increment the cycle counter
                        if cmd_cycle_count = C_MIN_COMMAND_INTERVAL-1 then
                            wait_done <= '1';
                        end if;

                        if wait_done = '1' then
                            state <= IDLE;
                            wb_miso_out.stall <= '0'; -- ready for next WB command
                        end if;
                    when others =>
                        state <= INIT;
                end case;

            end if;
        end if;
    end process;

end architecture;