
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

/// @brief  Converts a u32 to a fixed length hex string
/// @param data u32 to convert
/// @param buf pointer to character buffer
/// @param buf_len length of character buffer
void u32_to_hstring(u32 data, u8 *buf, u8 buf_len){

    // psuedocode:

    // fill with null chars (end of string)
    u8 i;
    for (i = 0; i < buf_len - 1; i++)
    {
        buf[i] = '\0';
    }
    // Add "0x" prefix
    buf[0] = '0';
    buf[1] = 'x';
    const u8 start = 2;
    const u8 chars = 8; // bits/4
    // for each 4 bits, convert to hex char
    for (i = 0; i < chars; i++)
    {
        u32 mask = 0xF << (i * 4);
        u8 nibble = (data & mask) >> (i * 4);
        buf[start+chars-1-i] = nibble_to_hex_char(nibble);
    }
}

char nibble_to_hex_char(u8 nibble){
    nibble = nibble & 0xF;  // select bottom 4 bits only
    if (nibble > 9) {   // A (65) to F (70)
        return nibble + 55;
    }
    // 0 (48) to 9 (57)
    return nibble + 48;
}