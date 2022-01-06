
#define SIM

#define BASYS3
#define REFCLK 50000000

#define _BV(n)  (1 << (n))
// set bit:  value = value | _BV(n)
// clr bit:  value = value & ~_BV(n)
// tst bit:  if (value &  _BV(n) != 0){}
#define _SET_BIT(reg, n)    (reg) = (reg) | _BV((n))
#define _CLR_BIT(reg, n)    (reg) = (reg) &  ~_BV((n))

// 32 bit references
// IE: get the contents (deference) of this 32 bit memory address
#define GPIO_LED    (*((volatile unsigned long *) 0x10000000 ))
#define Q_SSEG      (*((volatile unsigned long *) 0x10000004 ))
#define GPIO_BTN    (*((volatile unsigned long *) 0x10000100 ))
#define GPIO_SW     (*((volatile unsigned long *) 0x10000104 ))

// get the bit values for each switch
#ifdef BASYS3
    #define BTN_U 3
    #define BTN_L 2
    #define BTN_R 1
    #define BTN_D 0
#endif

#define UART_TX_BYTE     (*((volatile unsigned long *) 0x20000000 ))
#define UART_TX_IDLE     (*((volatile unsigned long *) 0x20000004 ))
#define UART_DIVISOR     (*((volatile unsigned long *) 0x20000008 ))

// program specific states
#define DISP_MODE_SW 14
#define DISP_MODE_TX 0
#define DISP_MODE_DIV 1
// override with
#define DISP_BAUD_BTN   BTN_L

#define INPUT_MODE_SW 15
#define INPUT_MODE_TX 0
#define INPUT_MODE_DIV 1

#define TX_BTN      BTN_R


// function prototypes
void delay_ms(int dly_ms);
int get_bit(int reg, int bitnum);

void putc(char c);
void put_byte(int c);   // so we can avoid casting

void main(void){

    // test some bit manip functions
    // for (int i = 0; i < 32;i++){
    //     delay_ms(100);
    //     _SET_BIT(GPIO_LED, i);
    // }
    // for (int i = 0; i < 32;i++){
    //     delay_ms(100);
    //     _CLR_BIT(GPIO_LED, i);
    // }

    // int input_mode = 0;
    // int display_mode = 0;
    int tx_byte = 0;
    // int div_setting;

    int count = 0;
    while (1)
    {

        // put_byte(0xFF);
        // put_byte(0x00);
        // put_byte(0x55);
        // put_byte(0xAA);

        putc('H');
        putc('e');
        putc('l');
        putc('l');
        putc('o');
        putc('\n');

        count = count + 1;
        Q_SSEG = count;
        // while(1){}
        // for (int i = 0; i < 256; i++)
        // {
        //     put_byte(i);
        // }
    }
}

// int get_bit(int reg, int bitnum){
//     if (reg & _BV(bitnum) == 0) {
//         return 0;
//     } else {
//         return 1;
//     }
// }

void putc(char c){
    // wait for UART to go idle
    GPIO_LED = 1;
    while (UART_TX_IDLE == 0) {}
    UART_TX_BYTE = c;
    GPIO_LED = 0;
}

// only the lowest byte is valid here
void put_byte(int b){
    // wait for UART to go idle
    GPIO_LED = 2;
    while (UART_TX_IDLE == 0) {}
    UART_TX_BYTE = b;
    GPIO_LED = 0;
}

#ifdef SIM
void delay_ms(int dly){
    int i = 0;
    while (i < 10){
        i++;
    }
}
#endif
#ifndef SIM
    // this is approximate
    void delay_ms(int dly_ms){
        const int ms_reps = 0x3A8;
        for (int i = 0; i < dly_ms; i++){
            for (int j = 0; j < ms_reps; j++){
                asm("nop");
            }
        }
    }
#endif