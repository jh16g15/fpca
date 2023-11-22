
#ifndef _UART_H_
#define _UART_H_

#include "utils.h"

//
struct uart
{
    volatile u32 *registers;
};

void uart_init(struct uart *module, volatile void *base_address);

void uart_set_baud(struct uart *module, int rate);
char uart_get_char(struct uart *module);
void uart_puts(struct uart *module, char *s);
void uart_put_char(struct uart *module, char c);
void uart_put_byte(struct uart *module, s32 c); // so we can avoid casting
u32 uart_get_32u(struct uart *module);
s32 uart_get_32i(struct uart *module);

#endif //_UART_H_