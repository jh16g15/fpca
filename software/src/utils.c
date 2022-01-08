
#include "utils.h"

int get_bit(int reg, int bitnum)
{
    return (reg >> bitnum) & 0x1;
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