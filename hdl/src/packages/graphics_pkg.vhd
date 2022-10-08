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

end package;
