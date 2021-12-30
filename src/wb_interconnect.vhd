library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;
--! Simple 1:N Wishbone Interconnect controlling access to a shared Wishbone bus 
--!
entity wb_interconnect is
    generic (
        G_NUM_SLAVES : integer := 16 -- max 16
        -- Select the width of segment used for address decoding
        -- G_ADR_MAP_H : integer := 31;
        -- G_ADR_MAP_L: integer := 28
    );
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        -- master in (slave port)
        wb_master_mosi_in  : in t_wb_mosi;
        wb_master_miso_out : out t_wb_miso;

        -- Slave Wishbone buses out
        wb_slave_mosi_arr_out : out t_wb_mosi_arr(G_NUM_SLAVES - 1 downto 0);
        wb_slave_miso_arr_in  : in t_wb_miso_arr(G_NUM_SLAVES - 1 downto 0)
    );
end entity wb_interconnect;

architecture rtl of wb_interconnect is
    constant C_MAX_SLAVES : integer := 16;
    signal adr_decode     : std_logic_vector(3 downto 0);

    signal slave_sel : std_logic_vector(C_MAX_SLAVES - 1 downto 0); -- one hot encoding (0=error/unmapped)
    constant C_NULL_SELECTED : std_logic_vector(C_MAX_SLAVES - 1 downto 0) := (others => '0');

    signal returned_acks : std_logic_vector(G_NUM_SLAVES - 1 downto 0) := (others => '0');
    signal returned_errs : std_logic_vector(G_NUM_SLAVES - 1 downto 0) := (others => '0');
    signal returned_rtys : std_logic_vector(G_NUM_SLAVES - 1 downto 0) := (others => '0');

    signal global_ack : std_logic;
    signal global_err : std_logic;
    signal global_rty : std_logic;
begin
    -- Two approaches here for MOSI signals
    -- 1. OR the ACK signals
    -- 2. Mux the ACK signals
    -- The other, Non-ACK signals should all be muxed

    adr_decode <= wb_master_mosi_in.adr(31 downto 28);
    -- NUM_SLAVES = 1, gen 0
    -- NUM_SLAVES = 2, gen 0, 1
    -- NUM_SLAVES = 3, gen 0, 1, 2

    -- Change this process to modify the address decoding
    -- For unused address segments, comment out and they will automatically respond with ERR
    -- TODO: Use G_NUM_SLAVES to parameterise this
    addr_decode : process (all)
    begin
        -- default to all 0's, then override 1 bit
        slave_sel <= (others => '0');
        case(adr_decode) is
            when x"0" => slave_sel(0) <= '1';
            when x"1" => slave_sel(1) <= '1';
            -- when x"2" => slave_sel(2) <= '1';
            -- when x"3" => slave_sel(3) <= '1';
            -- when x"4" => slave_sel(4) <= '1';
            -- when x"5" => slave_sel(5) <= '1';
            -- when x"6" => slave_sel(6) <= '1';
            -- when x"7" => slave_sel(7) <= '1';
            -- when x"8" => slave_sel(8) <= '1';
            -- when x"9" => slave_sel(9) <= '1';
            -- when x"A" => slave_sel(10) <= '1';
            -- when x"B" => slave_sel(11) <= '1';
            -- when x"C" => slave_sel(12) <= '1';
            -- when x"D" => slave_sel(13) <= '1';
            -- when x"E" => slave_sel(14) <= '1';
            -- when x"F" => slave_sel(15) <= '1';
            when others => null;
        end case;
    end process addr_decode;

    slave_stb : for i in 0 to G_NUM_SLAVES - 1 generate
        -- set the Slave STB signal based on the address decoding
        wb_slave_mosi_arr_out(i).stb <= wb_master_mosi_in.cyc and wb_master_mosi_in.stb and slave_sel(i);

        -- set the other Slave signals
        wb_slave_mosi_arr_out(i).adr  <= wb_master_mosi_in.adr;
        wb_slave_mosi_arr_out(i).wdat <= wb_master_mosi_in.wdat;
        wb_slave_mosi_arr_out(i).we   <= wb_master_mosi_in.we;
        wb_slave_mosi_arr_out(i).sel  <= wb_master_mosi_in.sel;
        wb_slave_mosi_arr_out(i).adr  <= wb_master_mosi_in.adr;

        -- assemble the slave response status
        returned_acks(i) <= wb_slave_miso_arr_in(i).ack;
        returned_errs(i) <= wb_slave_miso_arr_in(i).err;
        returned_rtys(i) <= wb_slave_miso_arr_in(i).rty;

    end generate;

    -- OR the returned ACK, ERR and RTY signals
    global_ack <= or returned_acks;
    global_err <= or returned_errs;
    global_rty <= or returned_rtys;

    reply_mux : process (all)
    begin
        -- defaults
        wb_master_miso_out.ack <= global_ack;
        wb_master_miso_out.err <= global_err;
        wb_master_miso_out.rty <= global_rty;
        wb_master_miso_out.rdat  <= x"DEC0DEFF";   -- "decode death"
        wb_master_miso_out.stall <= '0';

        -- this unrolls to our prev "case" statement
        if slave_sel = C_NULL_SELECTED then
            wb_master_miso_out.err <= wb_master_mosi_in.stb; -- override with ERR response for unmapped slave
        else
            for i in 0 to G_NUM_SLAVES - 1 loop 
                if test_bit(slave_sel, i) then -- if this slave selected
                    wb_master_miso_out.rdat  <= wb_slave_miso_arr_in(i).rdat;
                    wb_master_miso_out.stall <= wb_slave_miso_arr_in(i).stall;
                end if;
            end loop;
        end if;
    end process reply_mux;

end architecture;