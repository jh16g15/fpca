library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

package joe_common_pkg is

    procedure msg(msg: in string; show : boolean := true; unit : time := ns);

    --! Common array types
    type t_slv64_arr is array (integer range <>) of std_logic_vector(63 downto 0);
    type t_slv32_arr is array (integer range <>) of std_logic_vector(31 downto 0);
    type t_slv16_arr is array (integer range <>) of std_logic_vector(15 downto 0);
    type t_slv8_arr is array (integer range <>) of std_logic_vector(7 downto 0);

    function ascii2nibble(ascii:std_logic_vector(7 downto 0)) return std_logic_vector;
    function nibble2ascii(nibble:std_logic_vector(3 downto 0)) return std_logic_vector;

    --! Simple stream types (ready is optional and can be implemented separately)
    type t_stream8 is record
        data : std_logic_vector(7 downto 0);
        valid : std_logic;
    end record;
    type t_stream16 is record
        data : std_logic_vector(15 downto 0);
        valid : std_logic;
    end record;
    type t_stream32 is record
        data : std_logic_vector(31 downto 0);
        valid : std_logic;
    end record;

    type t_stream8_arr is array (integer range <>) of t_stream8;
    type t_stream16_arr is array (integer range <>) of t_stream16;
    type t_stream32_arr is array (integer range <>) of t_stream32;
    constant NULL_STREAM8 : t_stream8 := (data => (others => 'X'), valid => '0');
    constant NULL_STREAM16 : t_stream16 := (data => (others => 'X'), valid => '0');
    constant NULL_STREAM32 : t_stream32 := (data => (others => 'X'), valid => '0');

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
    impure function clog2(a : positive) return positive;
    -- function clog2(a : positive) return positive;

    --! Initialises a 32bit wide RAM from the contents of a file
    --! Supports "hex" and "bin" modes
    --! Adapted From https://vhdlwhiz.com/initialize-ram-from-file/
    impure function init_mem32(filepath : string; depth: integer := 512; hex_mode : std_logic := '1') return t_slv32_arr;

    --! Initialise an 8-bit wide RAM from the contents of a file containing 32bit wide data
    -- impure function init_mem32_bytes(filepath : string; depth: integer := 2048; byte_index : integer := 0; hex_mode : std_logic := '1') return t_slv8_arr;

    function test_bit(in_vec : std_logic_vector; i : integer) return boolean;

    function byte_swap(in_vec : std_logic_vector; swap : boolean := true) return std_logic_vector;

    
end package;

package body joe_common_pkg is
    procedure msg(msg: in string; show : boolean := true; unit : time := ns) is
    begin
        if show then
            write(OUTPUT, to_string(now, unit) & " " & msg & LF);
        end if;
    end procedure msg;

    --! Converts (lower-case only!) ASCII to a hex nibble
    function ascii2nibble(ascii:std_logic_vector(7 downto 0)) return std_logic_vector is
    begin
        case(ascii) is
            when x"30" => return x"0";
            when x"31" => return x"1";
            when x"32" => return x"2";
            when x"33" => return x"3";
            when x"34" => return x"4";
            when x"35" => return x"5";
            when x"36" => return x"6";
            when x"37" => return x"7";
            when x"38" => return x"8";
            when x"39" => return x"9";
            when x"61" => return x"a";
            when x"62" => return x"b";
            when x"63" => return x"c";
            when x"64" => return x"d";
            when x"65" => return x"e";
            when x"66" => return x"f";
            when others => return x"0";
        end case;
    end function;

    --! Converts  a hex nibble to lower-case ASCII
    function nibble2ascii(nibble:std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case(nibble) is
            when x"0"  => return x"30";
            when x"1"  => return x"31";
            when x"2"  => return x"32";
            when x"3"  => return x"33";
            when x"4"  => return x"34";
            when x"5"  => return x"35";
            when x"6"  => return x"36";
            when x"7"  => return x"37";
            when x"8"  => return x"38";
            when x"9"  => return x"39";
            when x"a"  => return x"61";
            when x"b"  => return x"62";
            when x"c"  => return x"63";
            when x"d"  => return x"64";
            when x"e"  => return x"65";
            when x"f"  => return x"66";
            when others => return x"00"; -- unecessary
        end case;
    end function;


    --! Returns the Ceiling of Log2(a)
    -- function clog2(a : positive) return positive is
    impure function clog2(a : positive) return positive is
    begin
        report "clog2 called on " & to_string(a);
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
    impure function init_mem32(filepath : string; depth: integer := 512; hex_mode : std_logic  := '1') return t_slv32_arr is
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
            if not endfile(init_file) then
                -- report "reading line " & to_string(i+1) severity note;
                readline(init_file, text_line);
                case(hex_mode) is
                    when '1' => hread(text_line, mem_contents(i));
                    when '0' => bread(text_line, mem_contents(i));
                    when others => hread(text_line, mem_contents(i));
                end case;
            end if;
        end loop;
        return mem_contents;
    end function;

    --! Initialise an 8-bit wide RAM from the contents of a file containing 32bit wide data
    -- impure function init_mem32_bytes(filepath : string; depth: integer := 2048; byte_index : integer := 0; hex_mode : std_logic := '1') return t_slv8_arr is
    --     file init_file : text; -- open read_mode is filepath;
    --     variable text_line : line;
    --     variable mem_contents : t_slv8_arr( 0 to depth-1) := (others => (others => '0'));
    --     variable line_contents : std_logic_vector(31 downto 0);
    -- begin
    --     if filepath = "" then
    --         return mem_contents;
    --     else
    --         file_open(init_file, filepath, read_mode);
    --     end if;
    --     for i in 0 to depth-1 loop
    --         readline(init_file, text_line);
    --         case(hex_mode) is
    --             when '1' => hread(text_line, line_contents);
    --             when '0' => bread(text_line, line_contents);
    --             when others => hread(text_line, line_contents);
    --         end case;
    --         mem_contents(i) := line_contents( 8*(byte_index+1)-1 downto 8*(byte_index));
    --     end loop;
    --     return mem_contents;
    -- end function;

    function test_bit(in_vec : std_logic_vector; i : integer) return boolean is
    begin
        return (in_vec(i) = '1');   -- True if '1'
    end function;

    function byte_swap(in_vec : std_logic_vector; swap : boolean := true) return std_logic_vector is 
        constant NUM_BYTES : integer := in_vec'length / 8;
        variable tmp_vec : std_logic_vector(in_vec'length-1 downto 0);
        variable tmp_byte : std_logic_vector(7 downto 0);
    begin
        report "Byte swap of " & to_string(NUM_BYTES) & " bytes";
        if swap then            
            for i in 0 to NUM_BYTES-1 loop
                tmp_byte := in_vec((NUM_BYTES-1-i)*8+7 downto (NUM_BYTES-1-i)*8);                
                tmp_vec(i*8+7 downto i*8) := tmp_byte;
            end loop;
            return tmp_vec;
        else
            return in_vec;
        end if;
    end function;
end package body;