
# Serial Ports on WSL2 don't currently work on Windows 10
# so call this python script through Powershell


import sys
import serial
import array
import time


# ASCII hex file of the new program
main_hex = "./hex/main.hex"
# LSByte-first per word binary file
main_bin = "./hex/main.bin"

COM_ID = sys.argv[1]

TEST_COM = "COM6"



XON = b'\x11'
XOFF = b'\x13'

SOH = b'\x01'
STX = b'\x02'
ETX = b'\x03'
EOT = b'\x04'


def send_bin_file(bin_file, uart):
    print(f"Opening {bin_file} binary...")
    log_file = "log.txt"
    with open(bin_file, "rb") as f:
        with open(log_file, "w") as log:
            #get the length of the bin file
            contents = bytearray(f.read())
            lenfile = len(contents)
            print(f"read {lenfile} bytes from {bin_file}...")
            ten_percent = int(lenfile/10)
            count = 0
            f.seek(0)   # return to the start of the file
            print("Sending: ")
            for i in range(lenfile):
                uart.write(f.read(1))
                count = count + 1
                if (count >= ten_percent):
                    print(".", end="", flush=True)
                    count = 0
            print(f"sent {lenfile} bytes!")



print(f"Opening Serial Port {COM_ID}")
# defaults: 9600 baud, 8,N,1
with serial.Serial(COM_ID, timeout = 5) as uart:
# with serial.Serial(COM_ID) as uart:
    print(f"{COM_ID} Open!, waiting to enter Bootloader (Reset with SW0=1)")

    # don't wait for response when testing with logic analyser
    if (COM_ID != TEST_COM):
        num_bytes_rcvd = uart.read_until(XON)   # we probably want a timeout here, as it locks up the whole terminal!
        print(f"Received {num_bytes_rcvd} bytes")
        if (len(num_bytes_rcvd) == 0):
            print ("no response from FPCA!")
            sys.exit()
        elif XON in num_bytes_rcvd:
            print("Received XON!")
        else:
            print("Did not receive XON!")
            sys.exit()


    print(f"Sending Start Address...")
    print("Sending SOH...")
    uart.write(SOH)
    # write start address x0000_0000 LSByte first (so x00, x00, x00, x00)
    print("writing start address x0000_0000 ")
    uart.write(b'\x00')
    uart.write(b'\x00')
    uart.write(b'\x00')
    uart.write(b'\x00')

    # write Start TeXt
    print("writing STX x02 ")
    uart.write(STX)

    # send the program data
    send_bin_file(main_bin, uart)

    print("Bootloader Ended, program Uploaded!")
    print("set SW0 to 0 and reset to start updated program")






