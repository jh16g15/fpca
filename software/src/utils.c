
#include "utils.h"

int get_bit(int reg, int bitnum)
{
    return (reg >> bitnum) & 0x1;
}

char get_bit_char(char reg, int bitnum)
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
// this is approximate: valid for -O0 only!
// TODO: replace with use of timer
void delay_ms(int dly_ms)
{
    const int ms_reps = 1220-1;
    // 36 + (1220*41) cycles per iteration, so subract 1 iteration
    for (int i = 0; i < dly_ms; i++)
    {
        // 36+5 cycles per iteration
        // at 50MHz (0.02us), each iter is 41*0.02us = 0.82us
        // So we want 1000/0.82=1220 iterations for a 1ms delay
        for (int j = 0; j < ms_reps; j++)
        {
            asm volatile("nop");
        }
    }
}
#endif