
// 32 bit references
// IE: get the contents (deference) of this 32 bit memory address
#define GPIO_LED    (*((volatile unsigned long *) 0x10000000 ))
#define Q_SSEG      (*((volatile unsigned long *) 0x10000004 ))
#define GPIO_BTN    (*((volatile unsigned long *) 0x10000100 ))
#define GPIO_SW     (*((volatile unsigned long *) 0x10000104 ))

// #define DELAY 10000000  // 10 million
#define DELAY 10  // 10 million

// set up the Stack Pointer to x0000_1FFC (32-bit aligned)
asm("li sp, 0x00001FFC");

// function declarations
// void delay(int dly);

// // without functions
void main(void){
    int count = 0x1000;
    volatile int tmp = 0;
    int i = 0;
    while (1)
    {
        GPIO_LED = 1;
        for (i = 0; i < 10; ++i){
            tmp = i;
        }
        GPIO_LED = 0;
        count = count + 1;
        Q_SSEG = count;
        for (i = 0; i < 10; i++){
            tmp = i;
        }
    }
}



// void main(void){
//     int count = 0;
//     while (1)
//     {
//         GPIO_LED = 1;
//         delay(DELAY);
//         GPIO_LED = 0;
//         delay(DELAY);
//         count = count + 1;
//         Q_SSEG = count;
//     }
// }


// // TODO: characterise this delay
// void delay(int dly){
//     asm("");
//     int i = 0;
//     while (i < dly){
//         i++;
//     }
// }

