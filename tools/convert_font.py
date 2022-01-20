

## Convert a "rows font" text file to a "columns font" suitable for the SSD1306



## The existing font I have is the IBM VGA 8x16, which is 8 bits wide and 16 bits tall.
#   This means we need 16 bytes per glyph
#

rows_first_font_file = "font_rom_rows.txt"
cols_first_font_file = "font_rom_cols.txt"

with open(rows_first_font_file, "r") as rf:
    with open(cols_first_font_file, "w") as wf:
        # read the whole file in
        old_font_rom = rf.readlines()

        total_glyphs = int(len(old_font_rom)/16)    # each glpyh 16 pixels high

        ## REDUCE FONT ROM SIZE TO SEE STUFF IN THE TERMINAL (TEMPORARY)
        total_glyphs = int(total_glyphs/2)



        print(f"total_glyphs = {total_glyphs}")


        # Each char in the new font is 8 bytes, with 1 byte per column
        new_font = []


        for i in range(total_glyphs):
            # get the relevant 16 lines
            old_char = old_font_rom[16*i:16*i+16]  # python slicing is not like HDL!



            # iterate over each row 8 times, assembling each column dynamically
            print(f"Starting font glyph {i}")
            for row in old_char:
                print(f"{row[:-1]}")

            # outer loop: iterate through each character in all the line strings
            for char in range(8):

                column = ""

                # Inner Loop: iterate through each row's selected character in turn
                for row in range(16):
                    # print(f"row={row}, col={char}")
                    column += old_char[row][char]

                col_bin = int(column, 2)
                col_hex = hex(col_bin)

                print(f"Column {char}: {column} ({col_hex})")

                new_font.append(col_hex)








