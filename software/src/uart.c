#include "uart.h"

void set_baud(int rate){
    UART_DIVISOR = REFCLK / rate;
}

// prints a string to the UART, followed by a newline \n
void uart_puts(char *s)
{
    char c;
    do
    {
        c = *s;  // character of string (contents of s mem)
        uart_putc(c); // print this char
        s++;     // increment pointer to move through array
    } while (c != '\0');
    uart_putc('\n');
}

// prints a char to the UART
void uart_putc(char c)
{
    // wait for UART to go idle
    // GPIO_LED = 1;
    while (UART_TX_IDLE == 0)
    {
    }
    UART_TX_BYTE = c;
    // GPIO_LED = 0;
}

// sends the lowest byte of an int to the UART
void put_byte(int b)
{
    // wait for UART to go idle
    // GPIO_LED = 2;
    while (UART_TX_IDLE == 0)
    {
    }
    UART_TX_BYTE = b;
    // GPIO_LED = 0;
}