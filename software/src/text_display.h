
#ifndef _TEXT_DISPLAY_H_
#define _TEXT_DISPLAY_H_

/* this support library lets us display characters on the screen (640x480)
//
// TODOs:
//*/

/* constants */

//colours (as defined in display_colour_ram.vhd)
#define BLACK 0
#define RED 1
#define GREEN 2
#define BLUE 3
#define YELLOW 4
#define MAGENTA 5
#define CYAN 6
#define WHITE 7
#define GREY 8

#define TEXT_W 80
#define TEXT_H 30
#define TEXT_MAX_X 79
#define TEXT_MAX_Y 29

#define CHAR_SMILEY 1
#define CHAR_SMILEY_INV 2
#define CHAR_HEART 3
#define CHAR_DIAMOND 4
#define CHAR_CLUB 5
#define CHAR_SPADE 6

/* memory addressres */
// #define TEXT_BASE_ADDR 0x40000000

/* global variables */
#define TEXT_BASE (*((volatile unsigned long *)0x40000000))

/* function prototypes */
void text_set(int x, int y, char charcode, char fg_col, char bg_col);
void text_string(int x, int y, char *string, unsigned int length, char fg_col, char bg_col);
void text_fill(int x1, int y1, int x2, int y2, char col);

#endif  //_TEXT_DISPLAY_H_