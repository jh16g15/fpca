#ifndef _PIXEL_DISPLAY_H_
#define _PIXEL_DISPLAY_H_

// temp, remove after debug done
#include "zynq_ps_uart.h"

#define DDR3_BASE (*((volatile unsigned long *)0xD0000000)) // upper 256MB
#define FRAMEBUF_BASE DDR3_BASE
#define DDR3_BASE_ADDR 0xD0000000 // upper 256MB
#define FRAMEBUF_BASE_ADDR DDR3_BASE_ADDR

// 24 bit colour
#define COL_BLACK   0x00000000UL
#define COL_RED     0x00FF0000UL
#define COL_GREEN   0x0000FF00UL
#define COL_BLUE    0x000000FFUL
#define COL_YELLOW  0x00FFFF00UL
#define COL_MAGENTA 0x00FF00FFUL
#define COL_CYAN    0x0000FFFFUL
#define COL_WHITE   0x00FFFFFFUL
#define COL_GREY    0x00808080UL

#define PIXELS_X 640
#define PIXELS_Y 480
#define CLOG2_X_PIXELS 12

void pixel_set(int x, int y, int col){
    unsigned int addr = FRAMEBUF_BASE_ADDR + x * 4 + (y << CLOG2_X_PIXELS);
    // zynq_ps_uart_puts("addr:\r\n");
    volatile unsigned long *pixel_loc = (volatile unsigned long *)addr; // cast to pointer
    *pixel_loc = col;
}



#endif //_PIXEL_DISPLAY_H_
