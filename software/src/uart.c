#include "cpu.h"
#include "uart.h"

#define UART_TX_BYTE (*((volatile unsigned long *)0x20000000))
#define UART_TX_IDLE (*((volatile unsigned long *)0x20000004))
#define UART_DIVISOR (*((volatile unsigned long *)0x20000008))
#define UART_RX_BYTE (*((volatile unsigned long *)0x2000000C))
#define UART_RX_VALID (*((volatile unsigned long *)0x20000010))

// define in main.c
#ifndef REFCLK
#define REFCLK 50000000
#endif

int uart_tx_ready(void){
    return UART_TX_IDLE;
}
int uart_rx_valid(void){
    return UART_RX_VALID;
}

void uart_set_baud(int rate){
    UART_DIVISOR = REFCLK / rate;
}

// consider checking for frame errors
char uart_get_char(void){
    while(UART_RX_VALID == 0){}
    return UART_RX_BYTE;
}

// prints a string to the UART, followed by a newline \n
void uart_puts(char *s)
{
    char c;
    do
    {
        c = *s;  // character of string (contents of s mem)
        uart_put_char(c); // print this char
        s++;     // increment pointer to move through array
    } while (c != '\0');
    uart_put_char('\r');    // for PUTTY compat
    uart_put_char('\n');
}

// prints a char to the UART
void uart_put_char(char c)
{
    // wait for UART to go idle
    while (UART_TX_IDLE == 0)
    {
    }
    UART_TX_BYTE = c;
}

// sends the lowest byte of an int to the UART
void uart_put_byte(int b)
{
    // wait for UART to go idle
    while (UART_TX_IDLE == 0)
    {
    }
    UART_TX_BYTE = b;
}

// Receive 32bit unsigned, LSByte first
unsigned int uart_get_32u(void){
    unsigned int ret;
    ret = uart_get_char();
    ret += uart_get_char() << 8;
    ret += uart_get_char() << 16;
    ret += uart_get_char() << 24;
    return ret;
}
// Receive 32bit signed, LSByte first
int uart_get_32i(void){
    int ret;
    ret = uart_get_char();
    ret += uart_get_char() << 8;
    ret += uart_get_char() << 16;
    ret += uart_get_char() << 24;
    return ret;
}