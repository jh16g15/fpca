
#include "terminal.h"
#include "text_display.h"

// global variables to statically allocate

// Terminal object used for the console
t_terminal *t;
char t_buf[TEXT_W * TEXT_H];

// set up the primary console
void console_init(){
    t->w = TEXT_W;
    t->h = TEXT_H;
    t->x = 0;
    t->y = 0;
    t->buf = t_buf;
    t->line_at_top = 1;
}

// print a string to the console and refresh the screen
void print(char *s){
    terminal_write_string(t, s);
    text_refresh_from_terminal(t);
}

void cls(){
    for (int i = 0; i < (TEXT_W * TEXT_H);i++){
        t->buf[i] = 0;
    }
    t->x = 0;
    t->y = 0;
    t->line_at_top = 1;
    text_refresh_from_terminal(t);
}