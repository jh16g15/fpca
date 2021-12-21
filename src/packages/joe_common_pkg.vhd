library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

package joe_common_pkg is

    --! Common array types
    type t_slv64_arr is array (integer range <>) of std_logic_vector(63 downto 0);
    type t_slv32_arr is array (integer range <>) of std_logic_vector(31 downto 0);
    type t_slv16_arr is array (integer range <>) of std_logic_vector(15 downto 0);
    type t_slv8_arr is array (integer range <>) of std_logic_vector(7 downto 0);
    
    --! Sign Extends a std_logic_vector
    function extend_slv(in_vec : std_logic_vector; new_len : integer := 32; sign_ext : std_logic := '1') return std_logic_vector;
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

    --! Initialises a 32bit wide RAM from the contents of a file
    --! Supports "hex" and "bin" modes
    --! Adapted From https://vhdlwhiz.com/initialize-ram-from-file/
    impure function init_mem32(filepath : string; depth: integer := 512; mode : string := "hex") return t_slv32_arr;

    --! Initialise an 8-bit wide RAM from the contents of a file containing 32bit wide data
    impure function init_mem32_bytes(filepath : string; depth: integer := 2048; byte_index : integer := 0; mode : string := "hex") return t_slv8_arr;
end package;

package body joe_common_pkg is

    --! Returns the Ceiling of Log2(a)
    function clog2(a : positive) return positive is
    begin
        return positive(ceil(log2(real(a))));
    end function;

    --! Sign/Zero Extends a std_logic_vector
    function extend_slv(in_vec : std_logic_vector; new_len : integer := 32; sign_ext : std_logic := '1') return std_logic_vector is
    begin
        if sign_ext = '1' then
            return std_logic_vector(resize(signed(in_vec), new_len));
        else
            return std_logic_vector(resize(unsigned(in_vec), new_len));
        end if;
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

    --! Initialises a 32bit wide RAM from the contents of a file
    --! Supports "hex" and "bin" modes
    impure function init_mem32(filepath : string; depth: integer := 512; mode : string := "hex") return t_slv32_arr is
        file init_file : text;
        variable text_line : line;
        variable mem_contents : t_slv32_arr( 0 to depth-1) := (others => (others => '0'));
    begin
        report "FILEPATH: " & filepath;
        if filepath = "" then
            report "No filepath provided, returning blank array" severity warning;
            return mem_contents;
        else
            file_open(init_file, filepath, read_mode);
        end if;
        for i in 0 to depth-1 loop
            report "reading line " & to_string(i) severity note;
            if not endfile(init_file) then
                readline(init_file, text_line);
                case(mode) is
                    when "hex" => hread(text_line, mem_contents(i));
                    when "bin" => bread(text_line, mem_contents(i)); 
                    when others => hread(text_line, mem_contents(i));
                end case;
            end if;
        end loop;
        return mem_contents;
    end function;

    --! Initialise an 8-bit wide RAM from the contents of a file containing 32bit wide data
    impure function init_mem32_bytes(filepath : string; depth: integer := 2048; byte_index : integer := 0; mode : string := "hex") return t_slv8_arr is
        file init_file : text; -- open read_mode is filepath;
        variable text_line : line;
        variable mem_contents : t_slv8_arr( 0 to depth-1) := (others => (others => '0'));
        variable line_contents : std_logic_vector(31 downto 0);
    begin
        if filepath = "" then
            return mem_contents;
        else
            file_open(init_file, filepath, read_mode);
        end if;
        for i in 0 to depth-1 loop
            readline(init_file, text_line);
            case(mode) is
                when "hex" => hread(text_line, line_contents);
                when "bin" => bread(text_line, line_contents); 
                when others => hread(text_line, line_contents);
            end case;
            mem_contents(i) := line_contents( 8*(byte_index+1)-1 downto 8*(byte_index));
        end loop;
        return mem_contents;
    end function;

end package body;