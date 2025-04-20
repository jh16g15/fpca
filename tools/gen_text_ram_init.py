#!/usr/bin/env python3.8

import string as s

outfile = "text_ram.txt"


fg_colour_map = {
    "black"   : 0,
    "red"     : 1,
    "green"   : 2,
    "blue"    : 3,
    "yellow"  : 4,
    "magenta" : 5,
    "cyan"    : 6,
    "white"   : 7,
    "grey"    : 8
}
bg_colour_map = {
    "black"   : 0,
    "red"     : 1,
    "green"   : 2,
    "blue"    : 3,
    "yellow"  : 4,
    "magenta" : 5,
    "cyan"    : 6,
    "white"   : 7,
    "grey"    : 8
}

# Constants
CHAR_W = 8  # pixels
CHAR_H = 16 # pixels
# SCREEN_X = 1280
# SCREEN_Y = 1024

SCREEN_X = 1024
SCREEN_Y = 600




CHARS_X = int(SCREEN_X/CHAR_W)
CHARS_Y = int(SCREEN_Y/CHAR_H)

TOTAL_CHARS = CHARS_X * CHARS_Y

print("Resolution: " + str(SCREEN_X) + "x" + str(SCREEN_Y))
print("Characters: " + str(CHARS_X) + "x" + str(CHARS_Y))

def char_item_to_bin_string(item):
    charcode = item['char']
    fg_code = item['fg']
    bg_code = item['bg']
    #print(charcode)
    #print(fg_code)
    #print(bg_code)
    #input(">")
    return(get_18b_string(charcode, fg_code, bg_code))

def get_18b_string(charcode, fg_code, bg_code):
    # 17:12 Foreground Colour
    # 11:8  Background Colour
    # 7:0   Charcode
    fg_str = format(fg_code, '06b')
    bg_str = format(bg_code, '04b')
    charcode_str = format(charcode, '08b')
    return fg_str + bg_str + charcode_str


# Create Initial blank list to write
# Array of rows, each row is an array of char_dicts{char, fg, bg}
screen_array = [[{"char" : 0, "fg" : fg_colour_map["white"], "bg" : bg_colour_map["red"]} for i in range (CHARS_X)] for j in range(CHARS_Y)]

 # This lets us iterate over the whole screen array
# for row_num, row in enumerate(screen_array):
    # for col_num, item in enumerate(row):
        # print("r" + str(row_num) + "c" + str(col_num) + "\t" +str(item))


#print(fg_colour_map["black"])

#print("Hello World")
#print(chr(1))       ## could also use \x01 for hex ascii chars
# for i in range(10240):
    # get_18b_string(ord('A'), 1, 0)

# print(get_18b_string(ord('A'), 1, 0))

# top half of the screen
for i in range(0, int(CHARS_Y/2)):
    for j in range(CHARS_X):
        screen_array[i][j]['bg'] = bg_colour_map["blue"]
# bottom half of the screen
for i in range(int(CHARS_Y/2), CHARS_Y):
    for j in range(CHARS_X):
        screen_array[i][j]['bg'] = bg_colour_map["black"]

# Test chars down side of the screen
screen_array[0][0]['char'] = ord('A')
screen_array[0][0]['fg'] = fg_colour_map["white"]
screen_array[0][0]['bg'] = bg_colour_map["blue"]
screen_array[1][0]['char'] = ord('B')
screen_array[1][0]['fg'] = fg_colour_map["white"]
screen_array[1][0]['bg'] = bg_colour_map["green"]
screen_array[2][0]['char'] = ord('\\')
screen_array[2][0]['fg'] = fg_colour_map["white"]
screen_array[2][0]['bg'] = bg_colour_map["red"]
screen_array[3][0]['char'] = ord('D')
screen_array[3][0]['fg'] = fg_colour_map["white"]
screen_array[3][0]['bg'] = bg_colour_map["magenta"]
screen_array[4][0]['char'] = ord('E')
screen_array[4][0]['fg'] = fg_colour_map["white"]
screen_array[4][0]['bg'] = bg_colour_map["cyan"]
screen_array[5][0]['char'] = ord('F')
screen_array[5][0]['fg'] = fg_colour_map["white"]
screen_array[5][0]['bg'] = bg_colour_map["red"]

# Top Row Chars
screen_array[0][1]['char'] = ord('A')
screen_array[0][1]['fg'] = fg_colour_map["magenta"]
screen_array[0][1]['bg'] = bg_colour_map["cyan"]
screen_array[0][2]['char'] = ord('A')
screen_array[0][2]['fg'] = fg_colour_map["yellow"]
screen_array[0][3]['bg'] = bg_colour_map["grey"]

# other corners
screen_array[0]         [CHARS_X-1]  ['bg'] = bg_colour_map["grey"]
screen_array[CHARS_Y-1] [0]          ['bg'] = bg_colour_map["grey"]
screen_array[CHARS_Y-1] [CHARS_X-1]  ['bg'] = bg_colour_map["grey"]


for i in range(CHARS_X):
    i_str = format(i, '03d')
    screen_array[5][i]['char'] = ord(i_str[0]) # hundreds
    screen_array[6][i]['char'] = ord(i_str[1]) # tens
    screen_array[7][i]['char'] = ord(i_str[2]) # units

# for i in range(CHARS_X):
#     i_str = format(i, '03d')
#     screen_array[40][i]['char'] = ord(i_str[0]) # hundreds
#     screen_array[41][i]['char'] = ord(i_str[1]) # tens
#     screen_array[42][i]['char'] = ord(i_str[2]) # units







print(f"Writing to \"{outfile}\"...")
with open(outfile, mode='w') as f:
    for row_num, row in enumerate(screen_array):
        for col_num, item in enumerate(row):
            # input("bg_col " + str(item['bg']))
            f.write(char_item_to_bin_string(item) + "\n")

    print("Done")