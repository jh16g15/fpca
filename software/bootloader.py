
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
with serial.Serial(COM_ID, timeout = 10) as uart:
    print("COM8 Open!, waiting to enter Bootloader (Reset with SW15=1)")
    uart.read_until(XON)   # we probably want a timeout here, as it locks up the whole terminal!
    print("Received XON!")
    print(f"Sending Start Address {start_address}...")
    print("Sending SOH...")
    uart.write(SOH)
    for byte in reversed(start_address_bytes):
        uart.write(byte)
    print("Sending STX...")
    uart.write(STX)
    for byte in reversed(data_bytes):
        uart.write(byte)
    print("Sending ETX...")
    uart.write(ETX)
    print("Bootloader Ended, program Uploaded!")
    print("set SW15 to 0 and reset to start updated program")






