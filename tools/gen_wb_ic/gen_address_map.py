import json

# TODO:
#   - add contextual comments to C header
#   - some kind of VHDL output for a wishbone interconnect (maybe package/function based?)
#

def int2hexstr(int_in):
    """converts int to 32b hex string"""
    return f"0x{int_in:08x}"

def hexstr2int(hexstr):
    """converts hex string to integer. Supports  "_" separator"""
    hexstr = hexstr.strip("_")
    return int(hexstr,0)

def parseSize(sizestr):
    """Parses a size in bytes, which can be in decimal or hex format. Supports a "unit" suffix
    eg B, W, K, M, G
    """
    units = {
        "B": 1,
        "W": 4,         # 4 bytes per word
        "K": 1024,
        "M": 1024 * 1024,
        "G": 1024 * 1024 * 1024,
    }
    if sizestr[-1] in units:
        unit = sizestr[-1].upper()
        sizestr = sizestr[:-1]  # NB: python list slicing does not include the RHS element
        return int(sizestr) * units[unit]
    elif sizestr[:2] == "0x":
        return hexstr2int(sizestr)
    else:
        return int(sizestr)

def outputCHeader(file, addr_map):
    c_map = []
    for seg, details in addr_map.items():
        c_map.append(f"#define {seg.upper()}_OFFSET {int2hexstr(details['start'])}\n")
    with open(file, "w") as fp:
        print(c_map)
        fp.writelines(c_map)

def main(cfg_json, c_file):
    with open(cfg_json, "r") as fp:
        settings = json.load(fp)
    print(f"{settings}")

    MIN_SIZE = parseSize(settings["min_size"])

    START_ADDR = hexstr2int(settings["start_address"])
    current_addr = START_ADDR

    addr_map = {}

    for seg_name, seg_details in settings["segments"].items():
        addr_map[seg_name] = {"start": current_addr}    # will probably need more info added here
        seg_size = parseSize(seg_details["size"])
        if seg_size < MIN_SIZE:
            seg_size = MIN_SIZE
        current_addr += seg_size

    print(f"=== ADDR MAP ===")
    print(f"{addr_map}")

    outputCHeader(c_file, addr_map)


if __name__ == "__main__":
    main("example.json", "example.h")