library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package graphics_pkg is
    type t_pixel is record
        red : std_logic_vector(7 downto 0);
        green : std_logic_vector(7 downto 0);
        blue: std_logic_vector(7 downto 0);
    end record;

    type t_apixel is record
        alpha : std_logic_vector(7 downto 0);
        red : std_logic_vector(7 downto 0);
        green : std_logic_vector(7 downto 0);
        blue: std_logic_vector(7 downto 0);
    end record;

    type t_colour_depth is record
        RED : natural range 1 to 8;
        GRN : natural range 1 to 8;
        BLU : natural range 1 to 8;
    end record;

    constant COLOUR_BITS_8_BPP : t_colour_depth := (RED=>3, GRN => 3, BLU => 2);
    constant COLOUR_BITS_12_BPP : t_colour_depth := (RED=>4, GRN => 4, BLU => 4);
    constant COLOUR_BITS_16_BPP : t_colour_depth := (RED=>5, GRN => 6, BLU => 5);
    constant COLOUR_BITS_24_BPP : t_colour_depth := (RED=>8, GRN => 8, BLU => 8);

    function func_combine_pixel_or(a : t_pixel; b : t_pixel) return t_pixel;

    function to_string(pixel : t_pixel) return string;

end package;

package body graphics_pkg is
    function func_combine_pixel_or(a : t_pixel; b : t_pixel) return t_pixel is
        variable v_pixel : t_pixel;
    begin
        v_pixel := (red => a.red or b.red, green => a.green or b.green, blue => a.blue or b.blue);
        return v_pixel;
    end function;

    function to_string(pixel : t_pixel) return string is 
    begin
        return "R=0x" & to_hstring(pixel.red) & ", G=0x" & to_hstring(pixel.green) & ", B=0x" & to_hstring(pixel.blue);
    end function;
end package body;