
#ifndef _ZYNQ_PS_UART_H
#define _ZYNQ_PS_UART_H

#include "cpu.h"

#ifdef PYNQ_Z2  // only valid code if running on a Zynq device

// Registers
#define ZYNQ_PS_UART_CR (*((volatile unsigned long *)0xE0000000))
#define ZYNQ_PS_UART_BAUDGEN (*((volatile unsigned long *)0xE0000018))
#define ZYNQ_PS_UART_BAUDDIV (*((volatile unsigned long *)0xE0000034))
#define ZYNQ_PS_UART_FIFO (*((volatile unsigned char *)0xE0000030)) // transmit and receive


void zynq_ps_uart_setup(){
    // default baud rate is 115200, fine for our purposes (ie general debug)
    ZYNQ_PS_UART_CR = 0x00000117;       // Enable Tx/Rx, soft reset FIFOs
}

// void zynq_ps_uart_set_baud(){
    // ZYNQ_PS_UART_BAUDGEN = 0x00000000;
    // ZYNQ_PS_UART_BAUDDIV = 0x00000000;
// }

void zynq_ps_uart_putc(char c){
    ZYNQ_PS_UART_FIFO = c;
}

void zynq_ps_uart_puts(char *s)
{
    char c;
    do
    {
        c = *s;  // character of string (contents of s mem)
        zynq_ps_uart_putc(c); // print this char
        s++;     // increment pointer to move through array
    } while (c != '\0');
    zynq_ps_uart_putc('\r');    // for PUTTY compat
    zynq_ps_uart_putc('\n');
}

char zynq_ps_uart_getc(){
    return ZYNQ_PS_UART_FIFO;
}

#endif // PYNQ_Z2

#endif  //_ZYNQ_PS_UART_H