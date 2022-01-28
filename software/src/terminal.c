

#include "terminal.h"
#include <stdlib.h>


t_terminal* create_terminal(int w, int h)
{
    // get a pointer to some allocated memory for our char buffer
    char *mem = malloc(w * h * sizeof(char));

    // get a pointer to a new "t_terminal" struct
    t_terminal *term = malloc(sizeof(t_terminal));

    term->w = w;
    term->h = h;
    term->terminal_mem = mem;

}
