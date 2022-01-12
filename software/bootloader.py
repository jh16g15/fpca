
# Serial Ports on WSL2 don't currently work on Windows 10
# so call this python script through Powershell


import sys
import serial
import array

# ASCII hex file of the new program
main_hex = "./hex/main.hex"

COM_ID = sys.argv[1]


# convert hex string to bytes
# bytes.fromhex(hex_string)         # immutable
# bytearray.fromhex(hex_string)     # mutable

test_hex = "123456ef"   # should transmit as ef,56,34,12
test_hex_bytearray = bytearray.fromhex(test_hex)

print(f"hex={test_hex}, bytearr={test_hex_bytearray}")
print("normal bytearr")
for byte in test_hex_bytearray:
    print(f"{byte}")
print("reversed")
for byte in reversed(test_hex_bytearray):
    print(f"{byte}")


start_address = "10000000"  # GPIO_LEDS
start_address_bytes = bytearray.fromhex(start_address)

data= ["FFFFFFFF"]  # set all LEDs on
data_bytes = bytearray.fromhex(data[0])

XON = b'\x11'
XOFF = b'\x13'

SOH = b'\x01'
STX = b'\x02'
ETX = b'\x03'
EOT = b'\x04'

## Looks like we are loading to the wrong address here... after reprogramming we lock up at PC=0x4


print(f"Opening Serial Port {COM_ID}")
# defaults: 9600 baud, 8,N,1
# with serial.Serial(COM_ID, timeout = 5) as uart:
with serial.Serial(COM_ID) as uart:
    print(f"{COM_ID} Open!, waiting to enter Bootloader (Reset with SW15=1)")

    num_bytes_rcvd = uart.read_until(XON)   # we probably want a timeout here, as it locks up the whole terminal!
    print(f"Received {num_bytes_rcvd} bytes")
    if (len(num_bytes_rcvd) == 0):
        input ("no response from FPCA!")


    print("Received XON!")
    print(f"Sending Start Address {start_address}...")
    print("Sending SOH...")
    uart.write(SOH)
    input("> 01")


    # input("check ILAs for SOH (x01)")
    # print(f"Begin sending start address {start_address_bytes}")
    # for byte in reversed(start_address_bytes):
    #     print(f"sending {byte}")
    #     uart.write(byte)
    #     input(f"Check ILAs for {byte}")
    # input("Check ILAs of RW2/3 for that start address")
    # print("Sending STX...")
    # uart.write(STX)
    # input("check ILAs for STX (x02)")
    # for byte in reversed(data_bytes):
    #     print(f"sending {byte}")
    #     uart.write(byte)
    #     input(f"Check ILAs for {byte}")


    # write start address x1000_0000 LSByte first (so x00, x00, x00, x10)
    print("writing start address x1000_0000 ")
    uart.write(b'\x00')
    input("> 00")
    uart.write(b'\x00')
    input("> 00")
    uart.write(b'\x00')
    input("> 00")
    uart.write(b'\x10')
    input("> 10")

    print("writing STX x02 ")
    uart.write(STX)
    input("> 02")
    # write Data xffff_ffff LSByte first (so xff, xff, xff, xff)
    print("writing data xffff_ffff (LED's)")
    uart.write(b'\xff')
    input("> ff")
    uart.write(b'\xff')
    input("> ff")
    uart.write(b'\xff')
    input("> ff")
    uart.write(b'\xff')
    input("> ff")
    print("Sending second word  xc001_c0de (to seven seg)...")
    #input(">")

    uart.write(b'\xde')
    input("> de")
    uart.write(b'\xc0')
    input("> c0")
    uart.write(b'\x01')
    input("> 01")
    uart.write(b'\xc0')
    input("> c0")

    print("Sending ETX...")
    uart.write(ETX)
    input("> 03")
    print("Bootloader Ended, program Uploaded!")
    print("set SW15 to 0 and reset to start updated program")






