library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all;

--! Simpler Wishbone single transactions (to B4 Pipelined spec) that don't 
--! rearrange wdata/rdata according to the SEL lines (for systems that
--! want to do their own realignment)
entity wb_master_noalign is
    port(
        wb_clk : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_out : out t_wb_mosi;
        wb_miso_in  : in t_wb_miso;

        -- command bus
        cmd_addr_in          : in std_logic_vector(C_WB_ADDR_W - 1 downto 0);
        cmd_wdata_in         : in std_logic_vector(C_WB_DATA_W - 1 downto 0);
        cmd_sel_in           : in std_logic_vector(C_WB_SEL_W - 1 downto 0); --! positions of read/write data
        cmd_we_in            : in std_logic;
        cmd_req_in           : in std_logic;
        cmd_stall_out        : out std_logic;

        -- response bus
        rsp_rdata_out : out std_logic_vector(C_WB_DATA_W - 1 downto 0);
        rsp_valid_out : out std_logic;
        -- rsp_stall     : in std_logic;    -- RDATA backpressure not implemented
        rsp_err_out : out std_logic
    );
end entity wb_master_noalign;

architecture RTL of wb_master_noalign is
    signal cmd_stall : std_logic := '0';
    signal wb_cyc    : std_logic := '0';
    signal wb_stb    : std_logic := '0';

    type t_state is (WB_IDLE, WB_ACTIVE);
    signal state : t_state := WB_IDLE;
begin
    cmd_stall_out <= cmd_stall;

    wb_mosi_out.cyc <= wb_cyc;
    wb_mosi_out.stb <= wb_stb;

    -- handle responses straight off the bus

    rsp_valid_out <= wb_miso_in.ack or wb_miso_in.err;
    rsp_err_out   <= wb_miso_in.err;
    rsp_rdata_out <= wb_miso_in.rdat;
    

    process (wb_clk)
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                state     <= WB_IDLE;
                wb_cyc    <= '0';
                wb_stb    <= '0';
                cmd_stall <= '0';
            else
                case state is
                    when WB_IDLE => -- Wait for next transaction request
                        if cmd_req_in = '1' and cmd_stall = '0' then
                            state <= WB_ACTIVE;
                            cmd_stall          <= '1';
                            wb_cyc             <= '1';
                            wb_stb             <= '1';
                            wb_mosi_out.adr    <= cmd_addr_in(C_WB_ADDR_W-1 downto 2) & b"00";  -- force 32 bit aligned addresses
                            wb_mosi_out.sel    <= cmd_sel_in;
                            wb_mosi_out.we     <= cmd_we_in;
                            wb_mosi_out.wdat   <= cmd_wdata_in;
                        end if;
                    when WB_ACTIVE =>
                        if wb_miso_in.stall = '0' then
                            wb_stb <= '0'; -- only deassert STB once transaction accepted
                        end if;

                        if rsp_valid_out = '1' then -- end bus cycle
                            state     <= WB_IDLE;
                            cmd_stall <= '0';
                            wb_cyc    <= '0';
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

end architecture RTL;
