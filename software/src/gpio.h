#ifndef _GPIO_H_
#define _GPIO_H_

#define _BV(n) (1 << (n))
// set bit:  value = value | _BV(n)
// clr bit:  value = value & ~_BV(n)
// tst bit:  if (value &  _BV(n) != 0){}
#define _SET_BIT(reg, n) (reg) = (reg) | _BV((n))
#define _CLR_BIT(reg, n) (reg) = (reg) & ~_BV((n))

// 32 bit references
// IE: get the contents (deference) of this 32 bit memory address
#define GPIO_LED (*((volatile unsigned long *)0x10000000))
#define Q_SSEG (*((volatile unsigned long *)0x10000004))
#define GPIO_BTN (*((volatile unsigned long *)0x10000100))
#define GPIO_SW (*((volatile unsigned long *)0x10000104))

int get_bit(int reg, int bitnum);

int get_bit(int reg, int bitnum)
{
    return (reg >> bitnum) & 0x1;
}


#endif // _GPIO_H_