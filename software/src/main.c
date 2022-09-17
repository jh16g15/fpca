
//#define SIM
#include "cpu.h"

// get the bit values for each switch
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
#include "zynq_ps_uart.h"


// function prototypes

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

    ssd1306_display_sleep();
    // Enable the charge pump and turn the display on
    ssd1306_display_init();
    ssd1306_whole_display_on();
    ssd1306_resume_ram_content();
    ssd1306_clear_screen();

    int counter = 0;

    zynq_ps_uart_setup();
    zynq_ps_uart_putc('J');
    zynq_ps_uart_puts(" Hello there");

    GPIO_LED = 0xF;
    text_fill(0, 0, TEXT_MAX_X, TEXT_MAX_Y, GREY);
    while (1)
    {
        uart_puts("Hello there, this acts as a delay\n");
        char fg_colour = 5;
        char bg_colour = 1;
        char charcode = 'c';


        // text_fill(0, 0, TEXT_MAX_X, TEXT_MAX_Y, GREY);

        text_string(1, 1, "=======================================", 39, WHITE, GREY);
        text_string(1, 2, "Friendly Programmable Computing Asset  ", 39, WHITE, GREY);
        text_string(1, 3, "=======================================", 39, WHITE, GREY);
        text_string(1, 4, "Architecture: RISC-V RV32I            ", 38, WHITE, GREY);
        text_string(1, 5, "Frequency: 25MHz                      ", 38, WHITE, GREY);
        text_string(1, 6, "Memory: 16KB                          ", 38, WHITE, GREY);
        text_string(1, 7, "Font Test:                            ", 38, WHITE, GREY);
        text_string(1, 8, "Colour Test:                          ", 38, WHITE, GREY);

        // add smiley
        text_set(39, 2, CHAR_SMILEY_INV, YELLOW, GREY);

        // colour test
        for (char i = 0; i < 8; i++){
            text_set(14 + i, 8, 0, BLACK, i);
        }

        // font test
        counter++;
        if (counter > 128)
        {
            counter = 0;
        }
        text_set(12, 7, counter, BLACK, GREY);
        delay_ms(100);
        // uart_putc(charcode);
    }

    // int tmp=0;
    // while (1)
    // {
    //     Q_SSEG = tmp;
    //     terminal_write_char(oled_term, tmp, 1);
    //     ssd1306_refresh(oled_term);
    //     tmp++;
    // }

    //*/

    /*     SSD1306 Font Test
    char x = 0;
    char y = 0;
    ssd1306_set_cursor(x, y);
    for (int i = 0; i < 64; i++){
        // ssd1306_write_glyph(y * 16 + x);
        ssd1306_write_glyph(i);
        ssd1306_advance_cursor(&x, &y);
        Q_SSEG_UPPER = x;
        Q_SSEG_LOWER = y;
        delay_ms(10);
    }
    delay_ms(1000);
    ssd1306_clear_screen();
    x = 0;
    y = 0;
    ssd1306_set_cursor(x, y);
    for (int i = 65; i < 128; i++){
        ssd1306_write_glyph(i);
        ssd1306_advance_cursor(&x, &y);
        Q_SSEG_UPPER = x;
        Q_SSEG_LOWER = y;
        delay_ms(10);
    }
    delay_ms(1000);
    ssd1306_clear_screen();
    x = 0;
    y = 0;
    ssd1306_set_cursor(x, y);
    ssd1306_puts("The FPCA has booted!", &x, &y);
    ssd1306_newline(&x, &y);
    ssd1306_putc(0x1, &x, &y);
    while (1)
    {
    }
    //*/

    uart_puts("ERR: Should never get here!");
}
