#ifndef _GPIO_H_
#define _GPIO_H_


// 32 bit references
// IE: get the contents (deference) of this 32 bit memory address
#define GPIO_LED (*((volatile unsigned long *)0x10000000))
#define Q_SSEG (*((volatile unsigned long *)0x10000004))
#define GPIO_BTN (*((volatile unsigned long *)0x10000100))
#define GPIO_SW (*((volatile unsigned long *)0x10000104))





#endif // _GPIO_H_