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
