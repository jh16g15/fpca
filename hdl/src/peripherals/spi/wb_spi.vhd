library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

-- TODO: make all registers byte-accessible
-- Generic simple Wishbone SPI controller.
-- SCK maximum frequency is half the frequency of the wishbone bus clock
-- We can alter the frequency through a register
--
-- To reduce software complexity (no polling needed), once a transfer is triggered
-- the Wishbone bus will stall until it is complete.
--
-- NOTE: This only supports half-duplex comms - we don't store the data coming back as transfers are
-- triggered by a single read or write
--
-- Other registers have a 1-cycle response as normal
entity wb_spi is
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_in  : in t_wb_mosi;
        wb_miso_out : out t_wb_miso;

        sck_out  : out std_logic;
        cs_n_out : out std_logic;
        mosi_out : out std_logic;
        miso_in  : in std_logic
    );
end entity wb_spi;
architecture rtl of wb_spi is
    -- Things to write (bits)
    -- (1) Chip Select
    -- (8) SCK Throttle (clocks between SCK edge)
    -- (8) Byte to write (triggers write?)

    -- Things to read
    -- (1) Chip Select
    -- (8) SCK Throttle (clocks between SCK edge)
    -- (8) Byte received (triggers a read?)

    -- Register Map
    -- x0: Read/Write byte trigger
    -- x4: Chip Select
    -- x8: SPI Throttle

    constant DEFAULT_SPI_SPEED : std_logic_vector(7 downto 0) := x"00";
    signal wait_for_transfer   : std_logic                    := '0';
    signal spi_start_strb      : std_logic                    := '0';
    signal spi_done_strb       : std_logic;
    signal chip_selectn        : std_logic                    := '1';
    signal spi_sck_throttle    : std_logic_vector(7 downto 0) := DEFAULT_SPI_SPEED;
    signal spi_byte_to_write   : std_logic_vector(7 downto 0);
    signal spi_byte_read       : std_logic_vector(7 downto 0);
begin

    cs_n_out <= chip_selectn;

    -- wishbone slave logic
    wb_proc : process (wb_clk) is
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                wb_miso_out.stall <= '0';
                wb_miso_out.ack   <= '0';
                wb_miso_out.err   <= '0';
                wb_miso_out.rty   <= '0';

                -- reset writeable registers
                wait_for_transfer <= '0';
                chip_selectn      <= '1';
                spi_sck_throttle  <= (others => '0');
            else
                -- defaults
                wb_miso_out.ack  <= '0';
                wb_miso_out.err  <= '0'; -- this slave does not generate ERR or RTY responses
                wb_miso_out.rty  <= '0';
                wb_miso_out.rdat <= x"DEADC0DE";

                -- default valids/strobes
                spi_start_strb <= '0';

                -- Accept new wishbone commands here
                if wb_mosi_in.stb = '1' and wb_miso_out.stall = '0' then -- assume CYC asserted by master for STB to be high
                    -- combined read and write logic
                    case(wb_mosi_in.adr(3 downto 0)) is
                        when x"0" => -- Trigger a transfer
                        spi_byte_to_write <= wb_mosi_in.wdat(7 downto 0) when wb_mosi_in.we = '1' else x"00";

                        spi_start_strb    <= '1';
                        wait_for_transfer <= '1';
                        wb_miso_out.stall <= '1'; -- don't accept

                        when x"4" => -- Chip Select (active low)
                        if wb_mosi_in.we = '1' then
                            chip_selectn <= wb_mosi_in.wdat(0);
                        end if;
                        wb_miso_out.rdat  <= (0 => chip_selectn, others => '0');
                        wb_miso_out.ack   <= '1';
                        wb_miso_out.stall <= '0';

                        when x"8" => -- SPI throttle
                        if wb_mosi_in.we = '1' then
                            spi_sck_throttle <= wb_mosi_in.wdat(7 downto 0);
                        end if;
                        wb_miso_out.rdat  <= spi_sck_throttle;
                        wb_miso_out.ack   <= '1';
                        wb_miso_out.stall <= '0';
                        when others => null;
                    end case;
                end if;

                -- wait for SPI byte transfers to complete here
                if wait_for_transfer = '1' then
                    if spi_done_strb = '1' then
                        wb_miso_out.rdat  <= x"0000_00" & spi_byte_read;
                        wb_miso_out.ack   <= '1';
                        wb_miso_out.stall <= '0'; -- now we can accept more WB commands
                    end if;
                end if;
            end if;
        end if; -- end clk'd
    end process;

    simple_mspi_inst : entity work.simple_mspi
        port map(
            clk      => wb_clk,
            byte_in  => spi_byte_to_write,
            strb_in  => spi_start_strb,
            byte_out => spi_byte_read,
            strb_out => spi_done_strb,
            sck_out  => sck_out,
            mosi_out => mosi_out,
            miso_in  => miso_in
        );

end architecture;