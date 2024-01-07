

#include "terminal.h"
#include <stdlib.h>

/*
 * Private funcs
 */
inline int clamp_cursor_x(t_terminal *t)
{
    if (t->x >= t->w)
    {
        t->x = t->w - 1;
    }
}
inline int clamp_cursor_y(t_terminal *t)
{
    if (t->y >= t->h)
    {
        t->y = t->h - 1;
    }
}
// if x > w, set x=0 and increment y
int wrap_cursor(t_terminal *t)
{
}

/*
 * Public funcs
 */

// allocate memory for a new "terminal" object of width `w` chars, and height `h` chars.
t_terminal *terminal_create(unsigned int w, unsigned int h)
{
    // get a pointer to some allocated memory for our char buffer
    char *mem = malloc(w * h * sizeof(char));

    // get a pointer to a new "t_terminal" struct
    t_terminal *term = malloc(sizeof(t_terminal));

    term->w = w;
    term->h = h;
    term->buf = mem;
    // init cursor to 0
    term->x = 0;
    term->y = 0;
    term->line_at_top = 1; // text is entered on the bottom visible line, so start of visible area is one more (wraps round)
    return term;
}

// free all memory used by terminal
void terminal_destroy(t_terminal *t)
{
    // free the memory allocated to the terminal buffer
    free(t->buf);
    t->buf = NULL;
    // free the memory used by the struct itself
    free(t);
    t = NULL;
}

// zero the terminal char buffer
void terminal_clear(t_terminal *t)
{
    int buflen = t->w * t->h;
    for (int i = 0; i < buflen; i++)
    {
        t->buf[i] = 0;
    }
}

// Increase the cursor x, wrapping onto the next line if necessary
void terminal_advance_cursor(t_terminal *t)
{
    t->x = t->x + 1; // increase the cursor x
    if (t->x >= t->w)
    {                    // if x overflow (max = w-1)
        t->x = 0;        // set x to 0
        t->y = t->y + 1; // inc cursor y
        terminal_scroll_one_line(t); // as we've increased Y, scroll the screen
        if (t->y >= t->h)
        {             // if y overflow (max = h-1)
            t->y = 0; // set y to 0
        }
    }
}

// Set the cursor position (clamp at w, h)
void terminal_set_cursor(t_terminal *t, unsigned int x, unsigned int y){
    // modulo operator without hardware divide likely to be expensive!
    t->x = x % t->w;
    t->y = y % t->h;
    // alternative:
    // t->x = x;
    // t->y = y;
    // clamp_cursor_x(t);
    // clamp_cursor_y(t);
}

// write a byte at the current cursor position (optional call to terminal_advance_cursor)
void terminal_write_raw_char(t_terminal *t, char c, char auto_adv)
{
    int index = (t->y * t->w) + t->x;
    t->buf[index] = c;
    if (auto_adv && c) // if auto-advance and not null char
    {
        terminal_advance_cursor(t);
    }
}

// write a byte at the current cursor position (interpret \r and \n as control chars)
void terminal_write_char(t_terminal *t, char c)
{
    unsigned int y;
    switch (c)
        {
        case '\n':
            y = (t->y + 1) % t->h; // x=0, increment y
            terminal_scroll_one_line(t); // as we've increased Y, scroll the screen
            terminal_set_cursor(t, 0, y);
            break;
        case '\r':
            terminal_set_cursor(t, 0, t->y);    // x=0
            break;
        case '\t':
            // TODO: implement tab stops
            // for now, fall through to `default`
        default:
            terminal_write_raw_char(t, c, 1);  // print this char
            break;
        }
}

// write a string to the terminal
void terminal_write_raw_string(t_terminal *t, char *s)
{
    char c;
    do
    {
        c = *s; // character of string (contents of s mem)
        terminal_write_raw_char(t, c, 1);  // print this char
        s++;                           // increment pointer to move through array
    } while (c != '\0');
}

// write a string to the terminal (interpret \r and \n as control chars)
void terminal_write_string(t_terminal *t, char *s)
{
    char c;
    do
    {
        c = *s; // character of string (contents of s mem)
        terminal_write_char(t, c);
        s++; // increment pointer to move through array
    } while (c != '\0');
}

void terminal_scroll_one_line(t_terminal *t)
{
    // clear the line that's about to wrap round
    unsigned int start_loc = t->line_at_top * t->w;
    for (int i = 0; i < t->w; i++)
    {
        t->buf[start_loc+i] = 0;
    }

    // move the pointer to the top of the screen
    t->line_at_top++;
    if (t->line_at_top >= t->h){
        t->line_at_top = 0;
    }
}