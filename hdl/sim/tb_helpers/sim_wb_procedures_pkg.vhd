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
        rdata : out std_logic_vector(31 downto 0);
        sel : in std_logic_vector(3 downto 0) := x"f"
    );

    procedure sim_wb_check (
        signal clk : in std_logic;
        signal wb_mosi_out : out t_wb_mosi;
        signal wb_miso_in : in t_wb_miso;
        address : in std_logic_vector(31 downto 0);
        exp_rdata : in std_logic_vector(31 downto 0);
        sel : in std_logic_vector(3 downto 0) := x"f"
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
        constant checker : checker_t := new_checker("WB BFM");
    begin
        info("WB Write to " & to_hstring(address) & " wdata= " & to_hstring(wdata) & " sel= " & to_string(sel));
        check(checker, address(1 downto 0) = b"00", "Check for bottom 2 bits of address being 0", warning);
        check(checker, sel /= x"0", "Check for sel not 0", error);
        wb_mosi_out <= C_WB_MOSI_INIT;
        wb_mosi_out.cyc <= '1';
        wb_mosi_out.stb <= '1';
        wb_mosi_out.we <= '1';
        wb_mosi_out.adr(address'left downto address'right) <= address;
        wb_mosi_out.wdat(wdata'left downto wdata'right) <= wdata;
        wb_mosi_out.sel <= sel;
        wait until rising_edge(clk) and wb_miso_in.stall = '0';
        wb_mosi_out <= C_WB_MOSI_INIT;
        wb_mosi_out.cyc <= '1'; -- leave CYC high until response
        info("WB Waiting for ACK");
        if wb_miso_in.ack = '0' then
            wait until rising_edge(clk) and wb_miso_in.ack = '1';
        end if;
        wb_mosi_out.cyc <= '0';
        info("WB Write Complete");
    end procedure;

    procedure sim_wb_read (
        signal clk : in std_logic;
        signal wb_mosi_out : out t_wb_mosi;
        signal wb_miso_in : in t_wb_miso;
        address : in std_logic_vector(31 downto 0);
        rdata : out std_logic_vector(31 downto 0);
        sel : in std_logic_vector(3 downto 0) := x"f"
    ) is
        constant checker : checker_t := new_checker("WB BFM");
    begin
        info("WB Read from " & to_hstring(address) & " sel= " & to_string(sel));
        check(checker, address(1 downto 0) = b"00", "Check for bottom 2 bits of address being 0", warning);
        check(checker, sel /= x"0", "Check for sel not 0", error);
        wb_mosi_out <= C_WB_MOSI_INIT;
        wb_mosi_out.cyc <= '1';
        wb_mosi_out.stb <= '1';
        wb_mosi_out.we <= '0';
        wb_mosi_out.adr(address'left downto address'right) <= address;
        wb_mosi_out.sel <= sel;
        wait until rising_edge(clk) and wb_miso_in.stall = '0';
        wb_mosi_out <= C_WB_MOSI_INIT;
        wb_mosi_out.cyc <= '1'; -- leave CYC high until response
        info("WB Waiting for ACK");
        if wb_miso_in.ack = '0' then
            wait until rising_edge(clk) and wb_miso_in.ack = '1';
        end if;
        rdata := wb_miso_in.rdat;
        wb_mosi_out.cyc <= '0';
        info("WB Read Complete with rdata= " & to_hstring(rdata));
    end procedure;

    procedure sim_wb_check (
        signal clk : in std_logic;
        signal wb_mosi_out : out t_wb_mosi;
        signal wb_miso_in : in t_wb_miso;
        address : in std_logic_vector(31 downto 0);
        exp_rdata : in std_logic_vector(31 downto 0);
        sel : in std_logic_vector(3 downto 0) := x"f"
    ) is
        variable rdata : std_logic_vector(31 downto 0);
    begin
        sim_wb_read(clk, wb_mosi_out, wb_miso_in, address, rdata, sel);
        -- only check selected bytes
        for i in 0 to 3 loop
            if sel(i) = '1' then
                check_equal(rdata(8*i+7 downto 8*i), exp_rdata(8*i+7 downto 8*i), "check byte " & to_string(i));
            end if;
        end loop;
    end procedure;

end package body;
