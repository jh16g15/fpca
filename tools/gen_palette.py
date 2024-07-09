
RED = 3
GREEN = 3
BLUE = 2

BITS = RED + GREEN + BLUE

PALETTE_ENTRIES = 256

PIXEL_BITS_PER_COLOUR = 8    # 24-bit colour out


def scaleVal(val:int, bits:int):
    """scale an n-bit value across a range from 0 to PIXEL_MAX"""
    old_range = (1 << bits) - 1
    new_range = (1 << PIXEL_BITS_PER_COLOUR) - 1
    new_val  = int(((val - 0) * new_range)/old_range) + 0
    return new_val

for i in range(8):
    newval = scaleVal(i, 3)
    print(f"{i} {i:03b} {newval:08b} {newval}")

print()

for i in range(4):
    newval = scaleVal(i, 2)
    print(f"{i} {i:02b} {newval:08b} {newval}")

with open("palette_pkg.vhd", "w") as f:
    f.write("library ieee;\n")
    f.write("use ieee.std_logic_1164.all;\n")
    f.write("use ieee.numeric_std.all;\n")
    f.write("use work.graphics_pkg.all;\n")
    f.write("\n")
    f.write("-- Colour and Greyscale palettes AUTO GENERATED by gen_palette.py --\n")
    f.write(f"--{PALETTE_ENTRIES} Entries in each palette\n")
    f.write("package palette_pkg is\n")
    f.write(f"\ttype t_8b_palette is array(0 to {PALETTE_ENTRIES-1}) of t_pixel;\n")

    f.write("\tconstant C_DEFAULT_PALETTE : t_8b_palette := (\n")
    palette_list = []
    for r in range(1<<RED):
        for g in range(1<<GREEN):
            for b in range(1<<BLUE):
                red=scaleVal(r, RED)
                green=scaleVal(g, GREEN)
                blue=scaleVal(b, BLUE)
                palette_list.append(f'\t\t(red => x"{red:02x}", green => x"{green:02x}", blue => x"{blue:02x}")')
    f.write(",\n".join(palette_list))
    f.write("\n\t);\n")

    f.write("\tconstant C_GREYSCALE_PALETTE : t_8b_palette := (\n")
    palette_list = []
    for i in range(PALETTE_ENTRIES):
        grey = scaleVal(i, PIXEL_BITS_PER_COLOUR)
        palette_list.append(f'\t\t(red => x"{grey:02x}", green => x"{grey:02x}", blue => x"{grey:02x}")')
    f.write(",\n".join(palette_list))
    f.write("\n\t);\n")

    f.write("end package;")




    