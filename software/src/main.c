
//#define SIM

#define BASYS3
#define REFCLK 50000000

// get the bit values for each switch
#ifdef BASYS3
#define BTN_U 3
#define BTN_L 2
#define BTN_R 1
#define BTN_D 0
#endif

// program specific states
#define DISP_MODE_SW 14
#define DISP_MODE_TX 0
#define DISP_MODE_DIV 1
// override with
#define DISP_BAUD_BTN BTN_L

#define INPUT_MODE_SW 15
#define INPUT_MODE_TX 0
#define INPUT_MODE_DIV 1

#define TX_BTN BTN_R

#include "uart.h"
#include "gpio.h"
#include "utils.h"
#include "ssd1306_i2c.h"

// function prototypes

void main(void)
{
    // if SW15 set on reset, jump to the bootloader
    // TODO: Move this to the crt0.s Startup script
    if (get_bit(GPIO_SW, 15))
    {
        // Jump to bootloader _start
        asm(
            "la t0,0xf0000000;"
            "jr t0;");
    }

    Q_SSEG = 0xc001;

    ssd1306_display_sleep();
    // Enable the charge pump and turn the display on
    ssd1306_display_init();

    ssd1306_clear_screen();
    while (1)
    {
        // ssd1306_clear_screen();
        for (int i = 0; i < 128 * 8; i++)
        {
            ssd1306_write_gram_byte(0x00);
        }
        // ssd1306_fill_screen(0xFF);
        for (int i = 0; i < 128 * 8; i++)
        {
            ssd1306_write_gram_byte(0xff);
        }
    }

    // char x = 0;
    // char y = 0;
    // ssd1306_set_cursor(x, y);
    // ssd1306_write_solid_char();
    // // update cursor
    // x++;
    // ssd1306_set_cursor(x, y);

    // int count = 0;
    // while (1)
    // {
    //     count = count + 1;

    //     GPIO_LED = count;
    //     if (get_bit(GPIO_BTN, BTN_L))
    //     {
    //         uart_puts("L pressed (solid)");

    //         ssd1306_write_glyph(0);
    //         // update cursor
    //         x++;
    //         ssd1306_set_cursor(x, y);
    //         //ssd1306_advance_cursor(&x, &y);

    //         while (get_bit(GPIO_BTN, BTN_L))
    //         {
    //         } // wait until button released
    //         uart_puts("L released");

    //     }
    //     if (get_bit(GPIO_BTN, BTN_R))
    //     {
    //         uart_puts("R pressed (empty)");
    //         ssd1306_write_glyph(1);
    //         // update cursor
    //         x++;
    //         ssd1306_set_cursor(x, y);
    //         // ssd1306_advance_cursor(&x, &y);

    //         while (get_bit(GPIO_BTN, BTN_R)){} // wait until button released
    //         uart_puts("R released");
    //     }
    //     if (get_bit(GPIO_BTN, BTN_U))
    //     {
    //         uart_puts("U pressed (checkers)");
    //         ssd1306_write_glyph(2);
    //         // update cursor
    //         x++;
    //         ssd1306_set_cursor(x, y);
    //         // ssd1306_advance_cursor(&x, &y);
    //         while (get_bit(GPIO_BTN, BTN_U)){} // wait until button released
    //         uart_puts("U released");
    //     }
    //     if (get_bit(GPIO_BTN, BTN_D))
    //     {
    //         uart_puts("D pressed (borders)");
    //         ssd1306_write_glyph(3);
    //         // update cursor
    //         x++;
    //         ssd1306_set_cursor(x, y);
    //         // ssd1306_advance_cursor(&x, &y);
    //         while (get_bit(GPIO_BTN, BTN_D)){} // wait until button released
    //         uart_puts("D released");
    //     }

    // }
}
