#include <stdio.h>

#define CURSOR_MAX_X 16
#define CURSOR_MAX_Y 4

// pass x and y by reference to modify
void ssd1306_advance_cursor(char *x_ptr, char *y_ptr)
{
    printf("x = %d, y= %d\n", *x_ptr, *y_ptr);
    printf("Advancing Cursor\n");
    *x_ptr++;
    if (*x_ptr > CURSOR_MAX_X){ // handle X wrapping
        printf("Handling cursor x overflow\n");
        *x_ptr = 0;
        *y_ptr++;
        if (*y_ptr > CURSOR_MAX_Y){ // handle Y wrapping
            printf("Handling cursor y overflow\n");
            *y_ptr = 0;
        }
    }
    printf("Setting new page/col limits\n");
    printf("x = %d, y= %d\n", *x_ptr, *y_ptr);
    //ssd1306_set_cursor(*x_ptr, *y_ptr);
    printf("Done\n");
}

int main(void)
{
    char x = 0;
    char y = 0;
    ssd1306_advance_cursor(&x, &y);
    ssd1306_advance_cursor(&x, &y);
    ssd1306_advance_cursor(&x, &y);
    ssd1306_advance_cursor(&x, &y);
}