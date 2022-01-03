
// 32 bit references
// IE: get the contents (deference) of this 32 bit memory address
#define GPIO_LED    (*((volatile unsigned long *) 0x10000000 ))
#define Q_SSEG      (*((volatile unsigned long *) 0x10000004 ))
#define GPIO_BTN    (*((volatile unsigned long *) 0x10000100 ))
#define GPIO_SW     (*((volatile unsigned long *) 0x10000104 ))

// #define DELAY 10000000  // 10 million
#define DELAY 10  // 10 million


// function declarations
// void delay(int dly);
int return_thing(void);

void main(void){
    Q_SSEG = return_thing();
}

int return_thing(void) {
    return 21;
}

//// with functions
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

