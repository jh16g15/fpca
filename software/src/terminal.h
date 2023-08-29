#ifndef _TERMINAL_H_
#define _TERMINAL_H_
/*
 *  Terminal.h
 *  A reusable front-end for a text-based display, supporting
 *  multiple display hardware types (such as the SSD1306 OLED
 *  or a VGA screen)
 */

// This would probably be easier in C++!

// declare a new struct type
typedef struct
{
    unsigned int w;     // width     (x_max = w - 1)
    unsigned int h;     // height    (y_max = h - 1)
    char *buf;
    unsigned int x;      // cursor x
    unsigned int y;      // cursor y
    unsigned int line_at_top; // line in buffer that is the currently top of the display
} t_terminal;

/*
 * TERMINAL FUNCTIONS
 */

// allocate memory for a new "terminal" object of width `w` chars, and
// height `h` chars.
t_terminal* terminal_create(unsigned int w, unsigned int h);
// free all memory used by terminal
void terminal_destroy(t_terminal *t);
// zero the terminal char buffer
void terminal_clear(t_terminal *t);

/*
 * CURSOR FUNCTIONS
 */
// Increase the cursor x, wrapping onto the next line
void terminal_advance_cursor(t_terminal *t);
// Set the cursor position (clamp at w, h)
void terminal_set_cursor(t_terminal *t, unsigned int x, unsigned int y);

// scroll the window down one line
void terminal_scroll_one_line(t_terminal *t);

// write a byte at the current cursor position (optional call to terminal_advance_cursor)
void terminal_write_raw_char(t_terminal *t, char c, char auto_adv);
// write a byte at the current cursor position (interpret \r and \n as control chars)
void terminal_write_char(t_terminal *t, char c);

// write a string to the terminal
void terminal_write_raw_string(t_terminal *t, char *s);
// write a string to the terminal (interpret \r and \n as control chars)
void terminal_write_string(t_terminal *t, char *s);

#endif // _TERMINAL_H_