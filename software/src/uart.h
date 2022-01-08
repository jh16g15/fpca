
#ifndef _UART_H_
#define _UART_H_

#define UART_TX_BYTE (*((volatile unsigned long *)0x20000000))
#define UART_TX_IDLE (*((volatile unsigned long *)0x20000004))
#define UART_DIVISOR (*((volatile unsigned long *)0x20000008))


void puts(char *s);
void putc(char c);
void put_byte(int c); // so we can avoid casting

// prints a string to the UART, followed by a newline \n
void puts(char *s)
{
    char c;
    do
    {
        c = *s;  // character of string (contents of s mem)
        putc(c); // print this char
        s++;     // increment pointer to move through array
    } while (c != '\0');
    putc('\n');
}

// prints a char to the UART
void putc(char c)
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

#endif //_UART_H_