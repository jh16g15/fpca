# FPCA
The FPCA (Friendly Programmable Computing Asset) is a RISC-V SoC design with accompanying peripherals.

# Current CPU Status
- RV32I Implemented (Except ECALL, EBREAK, FENCE)
- Multicycle, non-pipelined
    - 50 MHz on Artix-7
    - ALU/BRANCH 5 CPI
    - LOAD 9 CPI
    - STORE 8 CPI
- Wishbone B4 Instruction Fetch and Data Access

# Current Peripherals
- 16K combined program ROM/RAM
- UART Peripheral (up to 921600 baud, no FIFOs)
- GPIO
    - Switches / Buttons
    - LEDs
    - Quad Seven Segment display
    - Software I2C for SSD1306 OLED
- Separate Bootloader RAM to upload new programs over the UART
- DVI output (640x480, 80x30 text mode only using 8x16 font)

# UART Bootloader instructions
1. Build the new software with "cd software" and "make"
2. Set SW0 to 1 (PYNQ-Z2 and BASYS-3) to enable bootloader entry on reset
3. Run bootloader.py using the COM port as an argument
    If on Windows Subsystem for Linux, serial port passthrough is not supported, so use "upload.sh" to call a powershell script to launch 'windows-python' to get round this
4. When prompted, reset the FPCA by pressing BTN3 (PYNQ-Z2)
5. Wait for the upload to complete
6. Set SW0 to 0 to disable bootloader entry
7. Press BTN3 to reset the FPCA and start running the new software