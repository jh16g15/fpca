# python script to generate INIT commands to clock through

TEMPLATE = "aps6404_init_pkg_template.txt"
OUTFILE = "aps6404_init_pkg.vhd"

# globals
tick_count = 0
header = []
contents = []
CSn = "1" # start deasserted
OutEn = "1" # start in output mode

CMD_RST_EN = 0x66
CMD_RST = 0x99
CMD_ENTER_QUAD = 0x35
CMD_FAST_QUAD_READ = 0xEB
CMD_QUAD_WRITE = 0x38

READ_WAIT_CYCLES = 6

def addtick(CLK="0", SIO="0000", last=False):
    if not last:
        contents.append(f'    b"{CSn}{CLK}{OutEn}{SIO}",\n')
    else:
        contents.append(f'    b"{CSn}{CLK}{OutEn}{SIO}"\n')  # no comma
        # add trailer
        contents.append(");\n")
        contents.append("end package;")

    global tick_count
    tick_count = tick_count + 1

def deassert_CSn():
    global CSn
    CSn = "1"
    addtick()

def assert_CSn():
    global CSn
    CSn = "0"
    addtick()

def set_mode_output():
    global OutEn
    OutEn = "1"
    # print("Output")

def set_mode_input():
    global OutEn
    OutEn = "0"
    # print("Input")

def xchg_spi_byte(byte):
    for i in reversed(range(8)):  # only SIO0 used (MSbit first)  
        addtick("0", f"000{(byte >> i) & 0x1:01b}")  # ensure data is set for the rising edge
        addtick("1", f"000{(byte >> i) & 0x1:01b}")      
    # print("Byte")

def xchg_qpi_byte(byte):
    for i in reversed(range(2)):  # SIO3:0 used (MSbits first)  
        addtick("0", f"{(byte >> 4*i) & 0xf:04b}")  # ensure data is set for the rising edge
        addtick("1", f"{(byte >> 4*i) & 0xf:04b}")  
    # print("Byte")

def single_byte_spi_command(cmd):
    set_mode_output()
    assert_CSn()
    xchg_spi_byte(cmd)
    deassert_CSn()

def quad_write(start_addr, byte_list):
    set_mode_output()
    assert_CSn()
    xchg_qpi_byte(CMD_QUAD_WRITE)
    xchg_qpi_byte((start_addr >> 16) & 0xff)
    xchg_qpi_byte((start_addr >>  8) & 0xff)
    xchg_qpi_byte((start_addr >>  0) & 0xff)
    for byte in byte_list:
        xchg_qpi_byte(byte)
    deassert_CSn()

def quad_read(start_addr, num_bytes):
    set_mode_output()
    assert_CSn()
    xchg_qpi_byte(CMD_FAST_QUAD_READ)
    xchg_qpi_byte((start_addr >> 16) & 0xff)
    xchg_qpi_byte((start_addr >>  8) & 0xff)
    xchg_qpi_byte((start_addr >>  0) & 0xff)
    # wait states
    set_mode_input()
    for byte in range(READ_WAIT_CYCLES):
        xchg_qpi_byte(0x00)

    for byte in range(num_bytes):
        xchg_qpi_byte(0xff)

    deassert_CSn()

def write_then_read(byte_arr):
    quad_write(0, byte_arr)
    quad_read(0, len(byte_arr))

if __name__ == "__main__":
    with open(TEMPLATE, "r") as template_file:
        header = template_file.readlines()   # header stored in template file
        
    # add contents
    single_byte_spi_command(CMD_RST_EN)
    single_byte_spi_command(CMD_RST)
    single_byte_spi_command(CMD_ENTER_QUAD)
    write_then_read([0xf0])
    write_then_read([0x0f])
    # write_then_read([0x00, 0x01, 0x02, 0x03, 0x04])
    write_then_read([0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80])
    write_then_read([0xfe, 0xfd, 0xfb, 0xf7, 0xef, 0xdf, 0xbf, 0x7f])
    

    # add last tick
    addtick(CLK="0", SIO="0000", last=True)    
    with open(OUTFILE, "w") as file:
        file.writelines(header)
        file.writelines(f"constant C_APS6404_INIT_TICKS : integer := {tick_count};\n")
        file.writelines(f"type t_init_arr is array (0 to C_APS6404_INIT_TICKS-1) of std_logic_vector(1+1+1+4-1 downto 0);\n")
        file.writelines(f"constant C_APS6404_INIT_ARR : t_init_arr := (\n")
        file.writelines(contents)

    print(f"Wrote {tick_count} ticks to file {OUTFILE}")