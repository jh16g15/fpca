

# swaps the endianness of an ASCII-hex file
# with 32 bits per line

# Eg:
# input  = "76543210"
# output = "10325476"
#

import sys

infile = sys.argv[1]
outfile = sys.argv[2]


def swap_bytes(in_str):
    # if len(in_str) != 8:
    #     raise ValueError(f"Incorrect input string length, expected 8, got {len(in_str)}")
    # outstr[0:2] = in_str[6:8]
    # outstr[2:4] = in_str[4:6]
    # outstr[4:6] = in_str[2:4]
    # outstr[6:8] = in_str[0:2]
    # return outstr
    return in_str[6:8] + in_str[4:6] + in_str[2:4] + in_str[0:2]



test="10002117"
out = swap_bytes(test)
print(f"{test} => {out}")


with open(infile, "r") as fin:
    with open(outfile, "w") as fout:
        for line in fin:
            fout.writelines(swap_bytes(line) + "\n")
