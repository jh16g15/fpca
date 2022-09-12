#include "text_display.h"

void text_set(int x, int y, char charcode, char fg_col, char bg_col){
    volatile unsigned long *text_display = (volatile unsigned long *)0x40000000; // cast to pointer
    unsigned long newval = (fg_col << 12) + (bg_col << 8) + charcode;
    text_display[(y * TEXT_W) + x] = newval;
}

void text_string(int x, int y, char* string, unsigned int length, char fg_col, char bg_col){
    for (int i = 0; i < length; i++)
    {
        text_set(x + i, y, string[i], fg_col, bg_col);
    }
}