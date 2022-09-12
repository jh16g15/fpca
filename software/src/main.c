
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

    GPIO_LED = 0xF;
    while (1)
    {
        uart_puts("Greetings\n");
        char fg_colour = 5;
        char bg_colour = 1;
        char charcode = 'c';

        text_set(0, 0, 'c', BLACK, WHITE);
        text_string(0, 1, "Hello", 5, BLACK, WHITE);

        counter++;
        if (counter > 256)
        {
            counter = 0;
        }
        charcode = counter;

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
