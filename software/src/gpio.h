#ifndef _GPIO_H_
#define _GPIO_H_


// 32 bit references
// IE: get the contents (deference) of this 32 bit memory address
#define GPIO_LED (*((volatile unsigned long *)0x10000000))
#define Q_SSEG (*((volatile unsigned long *)0x10000004))
#define Q_SSEG_LOWER (*((volatile unsigned char *)0x10000004))
#define Q_SSEG_UPPER (*((volatile unsigned char *)0x10000005))
#define GPIO_BTN (*((volatile unsigned long *)0x10000100))
#define GPIO_SW (*((volatile unsigned long *)0x10000104))
#define GPIO_SOC_FREQ (*((volatile unsigned long *)0x10000108))
#define GPIO_SOC_MEM (*((volatile unsigned long *)0x1000010C))


#endif // _GPIO_H_