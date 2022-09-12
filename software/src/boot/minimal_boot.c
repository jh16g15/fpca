
#include "../cpu.h"

#define NUL 0x00    // Null
#define SOH 0x01    // Start of Heading
#define STX 0x02    // Start of Text
#define ETX 0x03    // End of Text
#define EOT 0x04    // End of Transmission

// Software Flow Control
#define XON 0x11    // Ready to receive
#define XOFF 0x13   // Not ready to receive

#ifndef REFCLK
#define REFCLK 50000000
#endif
#define UART_TX_BYTE (*((volatile unsigned long *)0x20000000))
#define UART_TX_IDLE (*((volatile unsigned long *)0x20000004))
#define UART_DIVISOR (*((volatile unsigned long *)0x20000008))
#define UART_RX_BYTE (*((volatile unsigned long *)0x2000000C))
#define UART_RX_VALID (*((volatile unsigned long *)0x20000010))

#define GPIO_LED (*((volatile unsigned long *)0x10000000))
#define SSEG (*((volatile unsigned long *)0x10000004))
#define RW2 (*((volatile unsigned long *)0x10000008))
#define RW3 (*((volatile unsigned long *)0x1000000C))

#define MAIN_RAM_LEN 16384   // bytes


// prints a char to the UART
void uart_put_char(char c)
{
    // wait for UART to go idle
    while (UART_TX_IDLE == 0)
    {
    }
    UART_TX_BYTE = c;
}

unsigned char uart_get_char(void){
    while(UART_RX_VALID == 0){}
    return UART_RX_BYTE;
}

void main(void)
{
    // set Baud rate to 9600
    UART_DIVISOR = REFCLK / 9600;   // compile - time

    GPIO_LED = 0x2;

    // wipe the old memory contents (32bits at a time)
    volatile unsigned int *wipe_ptr = 0;
    for (int i; i < MAIN_RAM_LEN/4; i++)
    // for (int i=0; i < 100; i++)
    {
        *wipe_ptr = 0x0000000;  // fill with NO-OPs
        wipe_ptr++;  // adr+4
    }
    GPIO_LED = 0x1;
    // tell PC that we are ready
    uart_put_char(XON);
    char gotc;
    do {
        gotc = uart_get_char();
    } while (gotc != SOH);
    // receive the start address (in 4 bytes, LSByte first)
    unsigned int start_address;
    start_address = uart_get_char();
    start_address += uart_get_char() << 8;
    start_address += uart_get_char() << 16;
    start_address += uart_get_char() << 24;
    char *mem = (char *)start_address; // char pointer so 1 byte increment

    // wait until STX received
    do {
        gotc = uart_get_char();
    } while (gotc != STX);

    // store the subsequent bytes into memory one at a time, incrementing each time
    // Keep doing this until we are reset (with SW15=0 to skip the bootloader)
    gotc = uart_get_char(); // get the first byte
    while (1) {
        *mem = gotc;    // store it to memory
        mem++;          // increase memory address by 1 byte
        gotc = uart_get_char(); // get next byte
    };
    GPIO_LED = 0x3;
}