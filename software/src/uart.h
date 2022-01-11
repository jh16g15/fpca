
#ifndef _UART_H_
#define _UART_H_

int uart_tx_ready(void);
int uart_rx_valid(void);
void uart_set_baud(int rate);
char uart_get_char(void);
void uart_puts(char *s);
void uart_put_char(char c);
void uart_put_byte(int c); // so we can avoid casting
unsigned int uart_get_32u(void);
int uart_get_32i(void);

#endif //_UART_H_