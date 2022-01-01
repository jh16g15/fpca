
// 32 bit references
// IE: get the contents (deference) of this 32 bit memory address
#define GPIO_LED    (*((volatile unsigned long *) 0x10000000 ))
#define Q_SSEG      (*((volatile unsigned long *) 0x10000004 ))
#define GPIO_BTN    (*((volatile unsigned long *) 0x10000100 ))
#define GPIO_SW     (*((volatile unsigned long *) 0x10000104 ))

#define DELAY 10000

// set up the Stack Pointer to x0000_1000
// x0000_1FFF is technically the top of our memory, but 
// we need a way of loading FFF without causing a subtraction
asm("lui sp, 0x00001");
//asm("addi sp, zero, 0xFFF");  

// function declarations
// void main(void);
// void delay(int dly);

// make sure this is at address x0000_0000
void main(void){
    int count = 0;
    while (1)
    {
        GPIO_LED = 1;
        // delay(DELAY);
        GPIO_LED = 0;
        // delay(DELAY);
        // count++;
        // Q_SSEG = count;
    }
}


// // TODO: characterise this delay
// void delay(int dly){
//     int i = 0;
//     while (i < dly){
//         i++;
//     }
// }

