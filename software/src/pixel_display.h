#ifndef _PIXEL_DISPLAY_H_
#define _PIXEL_DISPLAY_H_

#include "utils.h"

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
    u32 addr = FRAMEBUF_BASE_ADDR + x * 4 + (y << CLOG2_X_PIXELS);
    // zynq_ps_uart_puts("addr:\r\n");

    write_u32(addr, col);

    // volatile unsigned long *pixel_loc = (volatile unsigned long *)addr; // cast to pointer
    // *pixel_loc = col;
}

// from working Zynq code
u32 pixel_address_calc(u32 x, u32 y){
	u32 addr = FRAMEBUF_BASE_ADDR + x*4 + (y << CLOG2_X_PIXELS);
	return addr;
}

// from working Zynq code
void clear_screen(void){
	for(int y =0; y<PIXELS_Y;y++){
		for(int x =0; x<PIXELS_X;x++){
			write_u32(pixel_address_calc(x, y), COL_GREY);
			// write_u32(pixel_address_calc(x, y), COL_BLUE);
			// write_u32(pixel_address_calc(x, y), COL_BLACK);
		}
	}
}


#endif //_PIXEL_DISPLAY_H_
