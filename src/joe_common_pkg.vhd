library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package joe_common_pkg is

    --! Common array types
    type t_slv64_arr is array (integer range <>) of std_logic_vector(63 downto 0);
    type t_slv32_arr is array (integer range <>) of std_logic_vector(31 downto 0);
    type t_slv16_arr is array (integer range <>) of std_logic_vector(15 downto 0);
    type t_slv8_arr is array (integer range <>) of std_logic_vector(7 downto 0);
    
    --! Sign Extends a std_logic_vector
    function extend_slv(in_vec : std_logic_vector; new_len : integer := 32) return std_logic_vector;
    --! converts integer to "signed" slv 
    function int2slv(in_int : integer; new_len : integer := 32) return std_logic_vector;
    --! converts integer to "unsigned" slv 
    function uint2slv(in_uint : integer; new_len : integer := 32) return std_logic_vector;
    --! converts "unsigned" slv to integer
    function slv2uint(in_vec : std_logic_vector) return integer;
    --! converts "signed" slv to integer
    function slv2int(in_vec : std_logic_vector) return integer;
    --! adds two std_logic_vectors as "unsigned" and returns as a slv
    function u_add(a, b : std_logic_vector) return std_logic_vector;
    --! adds two std_logic_vectors as "signed" and returns as a slv
    function s_add(a, b : std_logic_vector) return std_logic_vector;
    function s_sub(a, b : std_logic_vector) return std_logic_vector;

    --! Returns the Ceiling of Log2(a)
    function clog2(a : positive) return positive;

end package;

package body joe_common_pkg is

    --! Returns the Ceiling of Log2(a)
    function clog2(a : positive) return positive is
    begin
        return positive(ceil(log2(real(a))));
    end function;

    --! Sign Extends a std_logic_vector
    function extend_slv(in_vec : std_logic_vector; new_len : integer := 32) return std_logic_vector is
    begin
        return std_logic_vector(resize(signed(in_vec), new_len));
    end function;

    --! converts integer to "signed" slv 
    function int2slv(in_int : integer; new_len : integer := 32) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(in_int, new_len));
    end function;
    --! converts integer to "unsigned" slv 
    function uint2slv(in_uint : integer; new_len : integer := 32) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(in_uint, new_len));
    end function;

    --! converts "unsigned" slv to integer
    function slv2uint(in_vec : std_logic_vector) return integer is
    begin
        return to_integer(unsigned(in_vec));
    end function;

    --! converts "signed" slv to integer
    function slv2int(in_vec : std_logic_vector) return integer is
    begin
        return to_integer(signed(in_vec));
    end function;

    --! adds two std_logic_vectors as "unsigned" and returns as a slv
    function u_add(a, b : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(unsigned(a) + unsigned(b));
    end function;

    --! adds two std_logic_vectors as "signed" and returns as a slv
    function s_add(a, b : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(signed(a) + signed(b));
    end function;

    --! subtracts two std_logic_vectors as "signed" and returns as a slv
    function s_sub(a, b : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector(signed(a) - signed(b));
    end function;

end package body;