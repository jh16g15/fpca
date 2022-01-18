library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;
--! Simple 2:1 Wishbone Arbiter controlling access to a shared Wishbone bus
--!
--! "simple"    : Arbiter stays at the last accessed master
--! "priority"  : Arbiter always moves back to wb_master_0 after each access to
--!               prevent an extra cycle of latency when accessing one master more
--!               frequently than the other
entity wb_arbiter is
    generic (
        G_ARBITER : string := "simple" -- "simple" or "priority" only
    );
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        -- master 0 in (slave port)
        wb_master_0_mosi_in  : in t_wb_mosi;
        wb_master_0_miso_out : out t_wb_miso;
        -- master 1 in (slave port)
        wb_master_1_mosi_in  : in t_wb_mosi;
        wb_master_1_miso_out : out t_wb_miso;
        -- selected master out
        wb_master_sel_mosi_out : out t_wb_mosi;
        wb_master_sel_miso_in  : in t_wb_miso
    );
end entity wb_arbiter;

architecture rtl of wb_arbiter is

    type t_state is (IDLE, SEL0, SEL1);
    signal state : t_state := IDLE;

begin

    -- Wishbone Mux
    process (all)
    begin
        case(state) is
            when IDLE   => wb_master_sel_mosi_out   <= C_WB_MOSI_INIT; -- IDLE
            when SEL0   => wb_master_sel_mosi_out   <= wb_master_0_mosi_in;
            when SEL1   => wb_master_sel_mosi_out   <= wb_master_1_mosi_in;
            when others => wb_master_sel_mosi_out <= C_WB_MOSI_INIT; -- ERROR
        end case;
    end process;

    wb_master_0_miso_out <= wb_master_sel_miso_in when state = SEL0 else C_WB_MISO_INIT; -- INIT has stall = '1'
    wb_master_1_miso_out <= wb_master_sel_miso_in when state = SEL1 else C_WB_MISO_INIT; -- INIT has stall = '1'
    process (wb_clk)
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                -- default back to IDLE
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        if wb_master_0_mosi_in.cyc = '1' then
                            state <= SEL0;
                        elsif wb_master_1_mosi_in.cyc = '1' then
                            state <= SEL1;
                        end if;
                    when SEL0 =>
                        -- if we have stopped using the bus, and the other master is requesting access
                        if wb_master_0_mosi_in.cyc = '0' and wb_master_1_mosi_in.cyc = '1' then
                            state <= SEL1;
                        end if;
                    when SEL1 =>
                        if G_ARBITER = "simple" then
                            -- if we have stopped using the bus, and the other master is requesting access
                            if wb_master_0_mosi_in.cyc = '1' and wb_master_1_mosi_in.cyc = '0' then
                                state <= SEL0;
                            end if;
                        end if;
                        if G_ARBITER = "priority" then
                            -- if we have stopped using the bus, switch back to SEL0 automatically
                            if wb_master_1_mosi_in.cyc = '0' then
                                state <= SEL0;
                            end if;
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;
end architecture;