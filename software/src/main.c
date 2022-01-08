
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

// function prototypes


void main(void)
{

    int tx_byte = 0;
    // int div_setting;

    int count = 0;
    uart_puts("\r\n");
    uart_puts("The FPCA has booted!");

    set_baud(9600);

    while (1)
    {
        // test the buttons are being filled correctly
        GPIO_LED = GPIO_BTN;

        if (get_bit(GPIO_BTN, BTN_L))
        {
            uart_puts("Left Button Pressed");
        }
        if (get_bit(GPIO_BTN, BTN_R))
        {
            uart_puts("Right Button Pressed");
        }
        if (get_bit(GPIO_BTN, BTN_U))
        {
            uart_puts("Up Button Pressed");
        }
        if (get_bit(GPIO_BTN, BTN_D))
        {
            uart_puts("Down Button Pressed");
        }

        count = count + 1;
        Q_SSEG = count;
    }
}



