#ifndef _CONSOLE_H_
#define _CONSOLE_H_

#include "terminal.h"

t_terminal* console_init();
void putchar_(char c);  // for printf support
void cls();

#endif // _CONSOLE_H_