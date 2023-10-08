library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;


-- Package of Wishbone BFM procedures
-- designed to be imported into testbenches for easy wishbone testing
package sim_wb_procedures_pkg is
    procedure sim_wb_write (
        signal clk : in std_logic;
        signal wb_mosi_out : out t_wb_mosi;
        signal wb_miso_in : in t_wb_miso;
        address : in std_logic_vector(31 downto 0);
        wdata : in std_logic_vector(31 downto 0);
        sel : in std_logic_vector(3 downto 0) := x"f"
    );

    procedure sim_wb_read (
        signal clk : in std_logic;
        signal wb_mosi_out : out t_wb_mosi;
        signal wb_miso_in : in t_wb_miso;
        address : in std_logic_vector(31 downto 0);
        rdata : out std_logic_vector(31 downto 0)
    );
end package;

package body sim_wb_procedures_pkg is

    procedure sim_wb_write (
        signal clk : in std_logic;
        signal wb_mosi_out : out t_wb_mosi;
        signal wb_miso_in : in t_wb_miso;
        address : in std_logic_vector(31 downto 0);
        wdata : in std_logic_vector(31 downto 0);
        sel : in std_logic_vector(3 downto 0) := x"f"
    ) is
    begin
        info("WB Write to " & to_hstring(address) & " wdata= " & to_hstring(wdata) & " sel= " & to_hstring(sel));
        wb_mosi_out <= C_WB_MOSI_INIT;
        wb_mosi_out.cyc <= '1';
        wb_mosi_out.stb <= '1';
        wb_mosi_out.we <= '1';
        wb_mosi_out.adr(address'left downto address'right) <= address;
        wb_mosi_out.wdat(wdata'left downto wdata'right) <= wdata;
        wb_mosi_out.sel <= sel;
        wait until rising_edge(clk) and wb_miso_in.stall = '0';
        if wb_miso_in.ack = '0' then
            wait until rising_edge(clk) and wb_miso_in.ack = '1';
        end if;
        wb_mosi_out <= C_WB_MOSI_INIT;
        info("WB Write Complete");
    end procedure;

    procedure sim_wb_read (
        signal clk : in std_logic;
        signal wb_mosi_out : out t_wb_mosi;
        signal wb_miso_in : in t_wb_miso;
        address : in std_logic_vector(31 downto 0);
        rdata : out std_logic_vector(31 downto 0)
    ) is
    begin
        info("WB Read from " & to_hstring(address));
        wb_mosi_out <= C_WB_MOSI_INIT;
        wb_mosi_out.cyc <= '1';
        wb_mosi_out.stb <= '1';
        wb_mosi_out.we <= '0';
        wb_mosi_out.adr(address'left downto address'right) <= address;
        wb_mosi_out.sel <= x"f";
        wait until rising_edge(clk) and wb_miso_in.stall = '0';
        if wb_miso_in.ack = '0' then
            wait until rising_edge(clk) and wb_miso_in.ack = '1';
        end if;
        rdata := wb_miso_in.rdat;
        info("WB Read Complete with rdata= " & to_hstring(rdata));
    end procedure;


end package body;
