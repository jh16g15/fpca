
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

// alignment safe way of reading u32 from a byte array
u32 u32_from_u8s(u8 *buf){
    u32 dat = buf[0];
    dat = dat | (buf[1] << 8);
    dat = dat | (buf[2] << 16);
    dat = dat | (buf[3] << 24);
    return dat;
}
// alignment safe way of reading u16 from a byte array
u16 u16_from_u8s(u8 *buf){
    u16 dat = buf[0];
    dat = dat | (buf[1] << 8);
    return dat;
}

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

/// @brief Converts a u32 to a fixed length decimal string (right-aligned)
/// @param data u32 to convert
/// @param buf pointer to character buffer
/// @param buf_len length of character buffer
void u32_to_string(u32 data, u8* buf, u8 buf_len){
    // max value of u32 = 4,294,967,295
    u32 digit_val;
    u32 digit;
    u32 next_place_val = 10;
    u32 place_val = 1;
    u32 digit_pos = 0;
    // fill the buf with spaces
    for (u32 i = 0; i < buf_len; i++){
        buf[i] = ' ';
    }

    buf[buf_len - 1] = '\0'; // end the string
    while(data != 0){
        digit_val = data % next_place_val;   // get the value in that place (eg 40)
        data = data - digit_val;        // subtract this from the value left to convert
        digit = digit_val / place_val;  // get the digit in that place
        buf[buf_len - 2 - digit_pos] = digit + 48;  // convert to ASCII
        // move to next place
        place_val *= 10;
        next_place_val *= 10;
        digit_pos++;
    }
}