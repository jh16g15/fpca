
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

    Q_SSEG = 0xc0de;

    // Enable the charge pump and turn the display on
    ssd1306_display_init();

    int count = 0;
    while (1)
    {
        // ssd1306_display_on();

        count = count - 1;

        GPIO_LED = count;
        if (get_bit(GPIO_BTN, BTN_L))
        {
            uart_puts("Turning Whole Display On!");
            ssd1306_whole_display_on();
        }
        if (get_bit(GPIO_BTN, BTN_R))
        {
            uart_puts("Reverting back to GDDRAM contents!");
            ssd1306_resume_ram_content();
        }

        // uart_set_baud(9600);

        // uart_puts("\r\n");
        // uart_puts("The FPCA has booted!");

        // while (1)
        // {
        //     // test the buttons are being filled correctly
        //     GPIO_LED = GPIO_BTN;

        //     // simple UART echo server
        //     if (uart_rx_valid()){
        //         uart_put_char(uart_get_char());
        //     }

        //     if (get_bit(GPIO_BTN, BTN_L))
        //     {
        //         uart_puts("Left Button Pressed");
        //         uart_puts("Setting Baud Rate to 9600");
        //         uart_set_baud(9600);
        //     }
        //     if (get_bit(GPIO_BTN, BTN_R))
        //     {
        //         uart_puts("Right Button Pressed");
        //         uart_puts("Setting Baud Rate to 115200");
        //         uart_set_baud(115200);
        //     }
        //     if (get_bit(GPIO_BTN, BTN_U))
        //     {
        //         uart_puts("Up Button Pressed");
        //         uart_puts("Setting Baud Rate to 921600");
        //         uart_set_baud(921600);
        //     }
        //     if (get_bit(GPIO_BTN, BTN_D))
        //     {
        //         uart_puts("Down Button Pressed");
        //     }

        //     count = count + 1;
        //     Q_SSEG = count;
        // }
    }
}
