
#include "uart.h"
#include "gpio.h"
#include "utils.h"

#define NUL 0x00    // Null
#define SOH 0x01    // Start of Heading
#define STX 0x02    // Start of Text
#define ETX 0x03    // End of Text
#define EOT 0x04    // End of Transmission

// Software Flow Control
#define XON 0x11    // Ready to receive
#define XOFF 0x13   // Not ready to receive


#define RW0 (*((volatile unsigned long *)0x10000000))   // LEDs
#define RW1 (*((volatile unsigned long *)0x10000004))   // QSSEG
#define RW2 (*((volatile unsigned long *)0x10000008))
#define RW3 (*((volatile unsigned long *)0x1000000C))

void launch_fpca_bootloader(void)
{
    uart_set_baud(9600);
    uart_puts("Bootloader Ready!");
    uart_put_char(XON);
    _SET_BIT(RW0, 15);

    // receive the start address (in 4 bytes, LSByte first)
    char gotc = uart_get_char();
    if (gotc != SOH)
    {
        uart_puts("did not receive 'SOH'!");
        _SET_BIT(RW0, 14);
    }
    unsigned int start_address = uart_get_32u();
    char *mem = (char*)start_address;  // char pointer so 1 byte increment

    RW2 = (unsigned long)mem;  // set the start address to RW2 (see on ILA)
    gotc = uart_get_char();
    if (gotc != STX)
    {
        uart_puts("did not receive 'STX'!");
    }
    // store the subsequent bytes into memory one at a time, incrementing each time
    gotc = uart_get_char(); // get the first byte
    while (gotc != ETX) { // check for End Of Text
        *mem = gotc;    // store it to memory
        mem++;          // increase memory address by 1 byte
        gotc = uart_get_char(); // get next byte
    };
    uart_puts("ETX Received!");
    uart_puts("Bootloader Done, set SW15 back to 0 and reset!");
    while(1){}; // do nothing and wait for reset

    //volatile asm("JALR 0(x0)"); // jump to __start
}