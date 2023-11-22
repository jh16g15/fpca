#include "cpu.h"
#include "uart.h"

#include "utils.h"

// #define UART_TX_BYTE (*((volatile unsigned long *)0x20000000))
// #define UART_TX_IDLE (*((volatile unsigned long *)0x20000004))
// #define UART_DIVISOR (*((volatile unsigned long *)0x20000008))
// #define UART_RX_BYTE (*((volatile unsigned long *)0x2000000C))
// #define UART_RX_VALID (*((volatile unsigned long *)0x20000010))

// 4 byte registers (which when used to index a 32bit pointer through the array syntax gives the correct address)
#define UART_REG_TX_BYTE 0
#define UART_REG_TX_IDLE 1
#define UART_REG_DIVISOR 2
#define UART_REG_RX_BYTE 3
#define UART_REG_RX_VALID 4

// define in main.c
// #ifndef REFCLK
// #define REFCLK 50000000
// #endif

// initialise a UART struct with the base address so we can access the registers
void uart_init(struct uart *module, volatile void* base_address){
    module->registers = (volatile uint32_t *)base_address;
}

void uart_set_baud(struct uart *module, int rate){
    module->registers[UART_REG_DIVISOR] = REFCLK / rate;
}

// consider checking for frame errors
char uart_get_char(struct uart *module){
    while(module->registers[UART_REG_RX_VALID] == 0){}
    return module->registers[UART_REG_RX_BYTE];
}

// prints a string to the UART, followed by a newline \n
void uart_puts(struct uart *module, char *s)
{
    char c;
    do
    {
        c = *s;  // character of string (contents of s mem)
        uart_put_char(module, c); // print this char
        s++;     // increment pointer to move through array
    } while (c != '\0');
    uart_put_char(module, '\r');    // for PUTTY compat
    uart_put_char(module, '\n');
}

// prints a char to the UART
void uart_put_char(struct uart *module, char c)
{
    // wait for UART to go idle
    while (module->registers[UART_REG_TX_IDLE] == 0)
    {
    }
    module->registers[UART_REG_TX_BYTE] = c;
}

// sends the lowest byte of an int to the UART
void uart_put_byte(struct uart *module, s32 b)
{
    // wait for UART to go idle
    while (module->registers[UART_REG_TX_IDLE] == 0)
    {
    }
    module->registers[UART_REG_TX_BYTE] = b;
}

// Receive 32bit unsigned, LSByte first
u32 uart_get_32u(struct uart *module){
    u32 ret;
    ret = uart_get_char(module);
    ret += uart_get_char(module) << 8;
    ret += uart_get_char(module) << 16;
    ret += uart_get_char(module) << 24;
    return ret;
}
// Receive 32bit signed, LSByte first
s32 uart_get_32i(struct uart *module){
    s32 ret;
    ret = uart_get_char(module);
    ret += uart_get_char(module) << 8;
    ret += uart_get_char(module) << 16;
    ret += uart_get_char(module) << 24;
    return ret;
}