
// 32 bit references
// IE: get the contents (deference) of this 32 bit memory address
#define GPIO_LED (*((volatile unsigned long *) 0x10000000 ))
#define GPIO_BTN (*((volatile unsigned long *) 0x10000100 ))
#define GPIO_SW (*((volatile unsigned long *) 0x10000104 ))

void main(void){
    while(1){
        GPIO_LED = 1;
        GPIO_LED = 0;
    }
}