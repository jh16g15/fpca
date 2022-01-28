#ifndef _TERMINAL_H_
#define _TERMINAL_H_

// declare a new struct type
typedef struct
{
    int w;     // width
    int h;     // height;
    char *terminal_mem;
} t_terminal;

t_terminal *create_terminal(int w, int h);

#endif // _TERMINAL_H_