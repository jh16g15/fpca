library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Package with various ways to manipulate and evaluate addresses.

package addr_pkg is
    --! Returns a '1' if the address matches the (masked) target pattern
    function addr_match (
        addr : std_logic_vector(31 downto 0);
        tar  : std_logic_vector(31 downto 0);
        mask : std_logic_vector(31 downto 0) := x"FFFF_FFFF"
    ) return std_logic;

    --! Returns the input address, with the masked bits replaced with bits from the target pattern
    function addr_displace (
        addr : std_logic_vector(31 downto 0);
        tar  : std_logic_vector(31 downto 0);
        mask : std_logic_vector(31 downto 0) := x"FFFF_FFFF"
    ) return std_logic_vector;

end package;

package body addr_pkg is
    --! Returns a '1' if the address matches the (masked) target pattern
    function addr_match (
        addr : std_logic_vector(31 downto 0);
        tar  : std_logic_vector(31 downto 0);
        mask : std_logic_vector(31 downto 0) := x"FFFF_FFFF"
    ) return std_logic is
    begin
        if (addr and mask) = (tar and mask) then
            return '1';
        else
            return '0';
        end if;
    end function;

    --! Returns the input address, with the masked bits replaced with bits from the target pattern
    function addr_displace (
        addr : std_logic_vector(31 downto 0);
        tar  : std_logic_vector(31 downto 0);
        mask : std_logic_vector(31 downto 0) := x"FFFF_FFFF"
    ) return std_logic_vector is
    begin
        return (tar and mask) and (addr and not mask);
    end function;

end package body;