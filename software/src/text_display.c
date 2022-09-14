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

void text_fill(int x1, int y1, int x2, int y2, char col){
    // fill top to bottom
    for (int y = y1; y <= y2; y++){
        // fill left to right
        for (int x = x1; x <= x2; x++){
            text_set(x, y, 0, BLACK, col);
        }
    }
}