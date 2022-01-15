

# swaps the endianness of an ASCII-hex file
# with 32 bits per line

# Eg:
# input  = "76543210"
# output = "10325476"
#

import sys

infile = sys.argv[1]
outfile = sys.argv[2]


# 32-bit endianness swap
def swap_bytes(in_str):
    return in_str[6:8] + in_str[4:6] + in_str[2:4] + in_str[0:2]


test="10002117"
out = swap_bytes(test)
print(f"{test} => {out}")


with open(infile, "r") as fin:
    with open(outfile, "w") as fout:
        for line in fin:
            fout.writelines(swap_bytes(line) + "\n")
