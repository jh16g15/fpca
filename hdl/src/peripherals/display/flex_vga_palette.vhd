library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.graphics_pkg.all;
use work.palette_pkg.all;

--! 8-bit rewriteable palette lookup
--! Supports 2 palettes
--! Outputs 24-bit colour pixels which can be trimmed later by flex_vga_colour_trim.vhd for different output colour depths as needed
entity flex_vga_palette is
    generic
    (
        -- REG_OUTPUT : boolean := true;        
        MEM_ACCESS : boolean := true --! Generate read/write memory interface to palette RAM
    );
    port
    (
        byte_in        : in std_logic_vector(7 downto 0);
        pixel_out      : out t_pixel;
        palette_select : in std_logic := '0'; --! 0 for colour, 1 for greyscale

        -- read/write access port
        memclk : in std_logic                     := '0';
        addr   : in std_logic_vector(8 downto 0)  := (others => '0');
        stb    : in std_logic                     := '0';
        we     : in std_logic                     := '0';
        wdat   : in std_logic_vector(23 downto 0) := x"00_00_00"; -- RGB 8-8-8 format
        rdat   : out std_logic_vector(23 downto 0); -- RGB 8-8-8 format
        ack    : out std_logic
    );
end entity flex_vga_palette;

architecture rtl of flex_vga_palette is
    signal palette0 : t_8b_palette := C_DEFAULT_PALETTE;
    signal palette1 : t_8b_palette := C_GREYSCALE_PALETTE;
begin
    process (all)
    begin
        if palette_select = '0' then
            pixel_out <= palette0(slv2uint(byte_in));
        else
            pixel_out <= palette1(slv2uint(byte_in));
        end if;
    end process;

    gen_access : if MEM_ACCESS generate
        process (memclk)
            variable in_pixel  : t_pixel;
            variable out_pixel : t_pixel;
        begin
            if rising_edge(memclk) then
                -- defaults
                ack <= '0';
                if stb = '1' then
                    -- Write to palette memory
                    if we = '1' then
                        ack <= '1';
                        in_pixel.red   := wdat(23 downto 16);
                        in_pixel.green := wdat(15 downto 8);
                        in_pixel.blue  := wdat(7 downto 0);
                        if addr(8) = '0' then
                            palette0(slv2uint(addr(7 downto 0))) <= in_pixel;
                        else
                            palette1(slv2uint(addr(7 downto 0))) <= in_pixel;
                        end if;

                        -- Read from palette memory
                    else
                        ack <= '1';
                        if addr(8) = '0' then
                            out_pixel := palette0(slv2uint(addr(7 downto 0)));
                            rdat <= out_pixel.red & out_pixel.green & out_pixel.blue;
                        else
                            out_pixel := palette1(slv2uint(addr(7 downto 0)));
                            rdat <= out_pixel.red & out_pixel.green & out_pixel.blue;
                        end if;
                    end if;
                end if;
            end if;
        end process;
    end generate;
end architecture;