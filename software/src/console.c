
#include "terminal.h"
#include "text_display.h"

// global variables to statically allocate

// Terminal object used for the console
// make static to limit to just in this file
static t_terminal t; // allocate space for a terminal object
static char t_buf[TEXT_W * (TEXT_H)]; // also allocate space for the terminal buffer

// set up the primary console (using return value is optional)
t_terminal* console_init(){
    t.w = TEXT_W;
    t.h = TEXT_H;
    t.x = 0;
    t.y = 0;
    t.buf = t_buf;
    t.line_at_top = 1;
    return &t;
}

// write a char to the output console (used by printf_() function)
void putchar_(char c){
    terminal_write_char(&t, c);
    // terminal_write_string(t, &c);
    text_refresh_from_terminal(&t); // flush to screen after every character (a bit ew really, but oh well)
}

void cls(){
    for (int i = 0; i < (TEXT_W * TEXT_H);i++){
        t.buf[i] = 0;
    }
    t.x = 0;
    t.y = 0;
    t.line_at_top = 1;
    text_refresh_from_terminal(&t);
}