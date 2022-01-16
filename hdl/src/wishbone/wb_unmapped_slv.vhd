

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;
entity wb_unmapped_slv is
port (
    wb_mosi_in  : in t_wb_mosi;
    wb_miso_out : out t_wb_miso
);
end entity;

architecture rtl of wb_unmapped_slv is

begin
    -- if access is attempted, return a "Decode Bus Err"
    wb_miso_out.ack <= '0';
    wb_miso_out.err <= wb_mosi_in.stb;
    wb_miso_out.rty <= '0';
    wb_miso_out.rdat  <= x"DEC0DEFF";   -- "decode death"
    wb_miso_out.stall <= '0';

end architecture;
