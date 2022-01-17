#ifndef _DELAY_H_
#define _DELAY_H_

#define _BV(n) (1 << (n))
// set bit:  value = value | _BV(n)
// clr bit:  value = value & ~_BV(n)
#define _SET_BIT(reg, n) (reg) = (reg) | _BV((n))
#define _CLR_BIT(reg, n) (reg) = (reg) & ~_BV((n))

void delay_ms(int dly_ms);
int get_bit(int reg, int bitnum);
char get_bit_char(char reg, int bitnum);

#endif // _DELAY_H_