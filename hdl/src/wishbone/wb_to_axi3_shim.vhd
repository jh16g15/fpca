----------------------------------------------------------------------------------
-- Joseph Hindmarsh Septemper 2022
--
-- Wishbone shim to connect AXI3 bus to a wishbone bus
-- ie: 32b Wishbone (B4) Slave to 32b AXI3 Master
--
-- TODOs:
--  * support burst mode/pipelined transactions
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wb_pkg.all;
use work.axi_pkg.all;

entity wb_to_axi3_shim is
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_in  : in t_wb_mosi;
        wb_miso_out : out t_wb_miso;

        axi_mosi_out : out t_axi_mosi;
        axi_miso_in  : in t_axi_miso

    );
end entity wb_to_axi3_shim;

architecture rtl of wb_to_axi3_shim is
begin

    axi_mosi_out.araddr  <= wb_mosi_in.adr;
    axi_mosi_out.arburst <= b"00";   -- FIXED
    axi_mosi_out.arcache <= b"0000"; -- Non bufferable, non-cacheable, no read-allocate, no write-allocate
    axi_mosi_out.arid    <= x"000";  -- ID = 0 (all transactions must be in order)
    axi_mosi_out.arlen   <= x"0";    -- burst length = 1 transfer
    axi_mosi_out.arlock  <= b"00";   -- normal transaction
    axi_mosi_out.arprot  <= b"000";  -- Unpriviledged, Secure, Data access (AxPROT[1] must be '0' for PS peripheral access)
    axi_mosi_out.arqos   <= x"0";    -- No QoS in use
    axi_mosi_out.arsize  <= b"010";  -- 4 bytes per transfer
    axi_mosi_out.awaddr  <= wb_mosi_in.adr;
    axi_mosi_out.awburst <= b"00";   -- FIXED
    axi_mosi_out.awcache <= b"0000"; -- Non bufferable, non-cacheable, no read-allocate, no write-allocate
    axi_mosi_out.awid    <= x"000";  -- ID = 0 (all transactions must be in order)
    axi_mosi_out.awlen   <= x"0";    -- burst length = 1 transfer
    axi_mosi_out.awlock  <= b"00";   -- normal transaction
    axi_mosi_out.awprot  <= b"000";  -- Unpriviledged, Secure, Data access (AxPROT[1] must be '0' for PS peripheral access)
    axi_mosi_out.awqos   <= x"0";    -- No QoS in use
    axi_mosi_out.awsize  <= b"010";  -- 4 bytes per transfer
    axi_mosi_out.bready  <= '1';     -- can always accept a response
    axi_mosi_out.rready  <= '1';     -- can always accept a response
    axi_mosi_out.wdata   <= wb_mosi_in.wdat;
    axi_mosi_out.wid     <= x"000";         -- ID = 0 (all transactions must be in order)
    axi_mosi_out.wlast   <= '1';            -- only transaction per burst
    axi_mosi_out.wstrb   <= wb_mosi_in.sel; -- wishbone byte strobe
    -- assign Wishbone MISO signals (single transaction only)
    wb_miso_out.rdat <= axi_miso_in.rdata;
    wb_miso_out.rty  <= '0'; -- unsupported

    -- proper handshaking - we could register other signals here to improve timing as well, but as they are all going into the ZYNQ PS probably unecessary.
    process (wb_clk) is
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                axi_mosi_out.arvalid <= '0';
                axi_mosi_out.awvalid <= '0';
                axi_mosi_out.wvalid  <= '0';
                wb_miso_out.stall    <= '0';
                wb_miso_out.ack      <= '0';
                wb_miso_out.err      <= '0';
            else
                -- handshaking to avoid repeat AXI channel acceptance
                if axi_mosi_out.arvalid = '1' and axi_miso_in.arready = '1' then
                    axi_mosi_out.arvalid <= '0';
                end if;
                if axi_mosi_out.awvalid = '1' and axi_miso_in.awready = '1' then
                    axi_mosi_out.awvalid <= '0';
                end if;
                if axi_mosi_out.wvalid = '1' and axi_miso_in.wready = '1' then
                    axi_mosi_out.wvalid <= '0';
                end if;

                if wb_mosi_in.stb = '1' then -- new transaction, set CMD valids
                    wb_miso_out.stall <= '1';
                    if wb_mosi_in.we = '1' then
                        axi_mosi_out.awvalid <= '1';
                        axi_mosi_out.wvalid  <= '1';
                    else
                        axi_mosi_out.arvalid <= '1';
                    end if;
                end if;

                --defaults
                wb_miso_out.ack <= '0';
                wb_miso_out.err <= '0';

                if axi_miso_in.bvalid = '1' then -- response, clear STALL
                    wb_miso_out.stall <= '0';
                    wb_miso_out.ack   <= '1' when axi_miso_in.bresp = b"00" else '0';
                    wb_miso_out.err   <= '1' when axi_miso_in.bresp /= b"00" else '0';
                end if;

                if axi_miso_in.rvalid = '1' then -- response, clear STALL
                    wb_miso_out.stall <= '0';
                    wb_miso_out.ack   <= '1' when axi_miso_in.rresp = b"00" else '0';
                    wb_miso_out.err   <= '1' when axi_miso_in.rresp /= b"00" else '0';
                end if;

            end if;
        end if;
    end process;

end architecture;