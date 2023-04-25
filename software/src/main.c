#include "cpu.h"

#ifdef BASYS3
#define BTN_U 3
#define BTN_L 2
#define BTN_R 1
#define BTN_D 0
#endif

#include "uart.h"
#include "gpio.h"
#include "utils.h"
#include "ssd1306_i2c.h"
#include "terminal.h"
#include "text_display.h"

void main(void)
{
    // if SW0 set on reset, jump to the bootloader
    // TODO: Move this to the crt0.s Startup script
    if (get_bit(GPIO_SW, 0))
    {
        // Jump to bootloader _start
        asm(
            "la t0,0xf0000000;"
            "jr t0;");
    }

    Q_SSEG = 0xc0de;
    uart_set_baud(9600);
    GPIO_LED = 0xF;

    text_fill(0, 0, TEXT_MAX_X, TEXT_MAX_Y, GREY);

    for (u32 i = 0; i < 16; i++)
    {
        write_u32((u32)0x10000000, i); // GPIO_LED
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
    }

    text_string(1, 1, "=======================================", 39, WHITE, GREY);
    text_string(1, 2, "Friendly Programmable Computing Asset  ", 39, WHITE, GREY);
    text_string(1, 3, "=======================================", 39, WHITE, GREY);
    text_string(1, 4, "Architecture: RISC-V RV32I            ", 38, WHITE, GREY);
    text_string(1, 5, "Frequency: 25MHz                      ", 38, WHITE, GREY);
    text_string(1, 6, "Memory: 16KB                          ", 38, WHITE, GREY);
    text_string(1, 7, "Font Test:                            ", 38, WHITE, GREY);
    text_string(1, 8, "Colour Test:                          ", 38, WHITE, GREY);

    while(1){
        uart_puts("A\n");
        Q_SSEG = 0xc001;
        uart_puts("B\n");
        Q_SSEG = 0xc0de;
    }
}