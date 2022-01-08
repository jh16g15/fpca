
#ifndef _UART_H_
#define _UART_H_

#define UART_TX_BYTE (*((volatile unsigned long *)0x20000000))
#define UART_TX_IDLE (*((volatile unsigned long *)0x20000004))
#define UART_DIVISOR (*((volatile unsigned long *)0x20000008))
#define UART_RX_BYTE (*((volatile unsigned long *)0x2000000C))
#define UART_RX_VALID (*((volatile unsigned long *)0x20000010))

// define in main.c
#ifndef REFCLK
#define REFCLK 50000000
#endif

void set_baud(int rate);
void uart_puts(char *s);
void uart_putc(char c);
void put_byte(int c); // so we can avoid casting



#endif //_UART_H_