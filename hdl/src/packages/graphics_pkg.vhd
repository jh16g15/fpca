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


    function func_combine_pixel_or(a : t_pixel; b : t_pixel) return t_pixel;


end package;

package body graphics_pkg is
    function func_combine_pixel_or(a : t_pixel; b : t_pixel) return t_pixel is
        variable v_pixel : t_pixel;
    begin
        v_pixel := (red => a.red or b.red, green => a.green or b.green, blue => a.blue or b.blue);
        return v_pixel;
    end function;

end package body;