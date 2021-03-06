
#define SIM

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

// function prototypes
void delay_ms(int dly_ms);


void main(void)
{

    int tx_byte = 0;
    // int div_setting;

    int count = 0;
    puts("\r\n");
    puts("The FPCA has booted!");


    while (1)
    {
        // test the buttons are being filled correctly
        GPIO_LED = GPIO_BTN;

        if (get_bit(GPIO_BTN, BTN_L))
        {
            puts("Left Button Pressed");
        }
        if (get_bit(GPIO_BTN, BTN_R))
        {
            puts("Right Button Pressed");
        }
        if (get_bit(GPIO_BTN, BTN_U))
        {
            puts("Up Button Pressed");
        }
        if (get_bit(GPIO_BTN, BTN_D))
        {
            puts("Down Button Pressed");
        }

        count = count + 1;
        Q_SSEG = count;
    }
}





#ifdef SIM
void delay_ms(int dly)
{
    int i = 0;
    while (i < 10)
    {
        i++;
    }
}
#endif
#ifndef SIM
// this is approximate
void delay_ms(int dly_ms)
{
    const int ms_reps = 0x3A8;
    for (int i = 0; i < dly_ms; i++)
    {
        for (int j = 0; j < ms_reps; j++)
        {
            asm("nop");
        }
    }
}
#endif