library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all; -- 32 bit port, 8 bit granularity

--! A simple wishbone master that can read and write to a 32-bit Wishbone bus
--!
--! Supports Single Transactions only (B4 pipelined)
--!
entity wb_master is
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_out : out t_wb_mosi;
        wb_miso_in  : in t_wb_miso;

        -- command bus
        cmd_addr_in     : in std_logic_vector(C_WB_ADDR_W - 1 downto 0);
        cmd_wdata_in    : in std_logic_vector(C_WB_DATA_W - 1 downto 0);
        cmd_sel_in      : in std_logic_vector(C_WB_SEL_W - 1 downto 0); --! positions of read/write data
        cmd_we_in       : in std_logic;
        cmd_req_in      : in std_logic;
        cmd_stall_out   : out std_logic;
        cmd_sign_ext_in : in std_logic; --! for sub 32-bit reads, perform sign extension, or zero extension?
        -- response bus
        rsp_rdata_out : out std_logic_vector(C_WB_DATA_W - 1 downto 0);
        rsp_valid_out : out std_logic;
        -- rsp_stall     : in std_logic;    -- RDATA backpressure not implemented
        rsp_err_out : out std_logic
    );
end entity;

architecture rtl of wb_master is
    signal cmd_stall : std_logic := '0';
    signal wb_cyc    : std_logic := '0';
    signal wb_stb    : std_logic := '0';

    type t_state is (WB_IDLE, WB_WAIT, WB_RSP);
    signal state : t_state := WB_IDLE;
begin
    cmd_stall_out <= cmd_stall;

    wb_mosi_out.cyc <= wb_cyc;
    wb_mosi_out.stb <= wb_stb;

    -- handle responses straight off the bus
    
    rsp_valid_out <= wb_miso_in.ack or wb_miso_in.err;
    rsp_err_out   <= wb_miso_in.err;
    
    -- receive reply from slave (and sign extend where necessary)
    process (all)
    begin
        case (cmd_sel_in) is
                -- LW
            when "1111" => rsp_rdata_out <= wb_miso_in.rdat;
                -- LH(U)
            when "0011" => rsp_rdata_out <= extend_slv(wb_miso_in.rdat(15 downto 0), new_len => 32, sign_ext => cmd_sign_ext_in);
            when "1100" => rsp_rdata_out <= extend_slv(wb_miso_in.rdat(31 downto 16), new_len => 32, sign_ext => cmd_sign_ext_in);
                -- LB(U)
            when "0001" => rsp_rdata_out <= extend_slv(wb_miso_in.rdat(7 downto 0), new_len => 32, sign_ext => cmd_sign_ext_in);
            when "0010" => rsp_rdata_out <= extend_slv(wb_miso_in.rdat(15 downto 8), new_len => 32, sign_ext => cmd_sign_ext_in);
            when "0100" => rsp_rdata_out <= extend_slv(wb_miso_in.rdat(23 downto 16), new_len => 32, sign_ext => cmd_sign_ext_in);
            when "1000" => rsp_rdata_out <= extend_slv(wb_miso_in.rdat(31 downto 24), new_len => 32, sign_ext => cmd_sign_ext_in);
            when others => rsp_rdata_out <= wb_miso_in.rdat;
        end case;
    end process;

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
                    when WB_IDLE =>
                        if cmd_req_in = '1' and cmd_stall = '0' then
                            state            <= WB_WAIT;
                            cmd_stall        <= '1';
                            wb_cyc           <= '1';
                            wb_stb           <= '1';
                            wb_mosi_out.adr  <= cmd_addr_in;
                            wb_mosi_out.sel  <= cmd_sel_in;
                            wb_mosi_out.we   <= cmd_we_in;
                            wb_mosi_out.wdat <= cmd_wdata_in;

                        end if;
                    when WB_WAIT =>
                        wb_stb <= '0';        -- now deassert (single read/write)
                        if rsp_valid_out then -- end bus cycle
                            state     <= WB_IDLE;
                            cmd_stall <= '0';
                            wb_cyc    <= '0';
                        end if;
                    when WB_RSP =>
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

end architecture;