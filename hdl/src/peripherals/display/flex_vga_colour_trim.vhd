library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.graphics_pkg.all;

--! Trim 24-bit colour to a lower number of bits for video output
--! Also handles masking off during blanking periods
entity flex_vga_colour_trim is
    generic (
        COL_DEPTH : t_colour_depth := COLOUR_BITS_8_BPP;
        -- RED_BITS : natural range 1 to 8 := COLOUR_BITS_8_BPP.RED;
        -- GRN_BITS : natural range 1 to 8 := COLOUR_BITS_8_BPP.GRN;
        -- BLU_BITS : natural range 1 to 8 := COLOUR_BITS_8_BPP.BLU;
        REG_OUTPUT : boolean := true
    );
    port (
        pixelclk   : in std_logic := '0';   -- not used if REG_OUTPUT is false
        -- inputs
        pixel   : in t_pixel;
        hsync   : in std_logic;
        vsync   : in std_logic;
        blank   : in std_logic;
        -- output to monitor
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_blank : out std_logic;
        vga_red : out std_logic_vector(COL_DEPTH.RED-1 downto 0);
        vga_grn : out std_logic_vector(COL_DEPTH.GRN-1 downto 0);
        vga_blu : out std_logic_vector(COL_DEPTH.BLU-1 downto 0)
        
    );
end entity flex_vga_colour_trim;

architecture rtl of flex_vga_colour_trim is
    
begin
    gen_reg : if REG_OUTPUT generate
        process (pixelclk)
        begin
            if rising_edge(pixelclk) then
                vga_hsync <= hsync;
                vga_vsync <= vsync;
                vga_blank <= blank;
                vga_red <= pixel.red(7 downto 7+1 - COL_DEPTH.RED) when blank = '0' else (others => '0');
                vga_grn <= pixel.green(7 downto 7+1 - COL_DEPTH.GRN) when blank = '0' else (others => '0');
                vga_blu <= pixel.blue(7 downto 7+1 - COL_DEPTH.BLU) when blank = '0' else (others => '0');
            end if;
        end process;
    end generate;

    gen_noreg : if not REG_OUTPUT generate
        vga_hsync <= hsync;
        vga_vsync <= vsync;
        vga_blank <= blank;
        vga_red <= pixel.red(7 downto 7+1 - COL_DEPTH.RED) when blank = '0' else (others => '0');
        vga_grn <= pixel.green(7 downto 7+1 - COL_DEPTH.GRN) when blank = '0' else (others => '0');
        vga_blu <= pixel.blue(7 downto 7+1 - COL_DEPTH.BLU) when blank = '0' else (others => '0');
    end generate;
  

end architecture;