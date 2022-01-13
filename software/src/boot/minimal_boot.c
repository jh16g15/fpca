
#define NUL 0x00    // Null
#define SOH 0x01    // Start of Heading
#define STX 0x02    // Start of Text
#define ETX 0x03    // End of Text
#define EOT 0x04    // End of Transmission

// Software Flow Control
#define XON 0x11    // Ready to receive
#define XOFF 0x13   // Not ready to receive

#define REFCLK 50000000
#define UART_TX_BYTE (*((volatile unsigned long *)0x20000000))
#define UART_TX_IDLE (*((volatile unsigned long *)0x20000004))
#define UART_DIVISOR (*((volatile unsigned long *)0x20000008))
#define UART_RX_BYTE (*((volatile unsigned long *)0x2000000C))
#define UART_RX_VALID (*((volatile unsigned long *)0x20000010))

// prints a char to the UART
void uart_put_char(char c)
{
    // wait for UART to go idle
    while (UART_TX_IDLE == 0)
    {
    }
    UART_TX_BYTE = c;
}

char uart_get_char(void){
    while(UART_RX_VALID == 0){}
    return UART_RX_BYTE;
}

void main(void)
{
    // set Baud rate to 9600
    UART_DIVISOR = REFCLK / 9600;   // compile - time

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
    gotc = uart_get_char(); // get the first byte
    while (gotc != ETX) { // check for End Of Text
        *mem = gotc;    // store it to memory
        mem++;          // increase memory address by 1 byte
        gotc = uart_get_char(); // get next byte
    };
    while(1){}; // do nothing and wait for reset

    //volatile asm("JALR 0(x0)"); // jump to __start
}