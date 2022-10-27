#include <stdio.h>
#include <stdint.h>

#define CURSOR_MAX_X 16
#define CURSOR_MAX_Y 4

typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t u8;

typedef int32_t s32;
typedef int16_t s16;
typedef int8_t s8;

// pass x and y by reference to modify
void ssd1306_advance_cursor(char *x_ptr, char *y_ptr)
{
    printf("\n\nAdvancing Cursor\n\n");
    printf("x = %d, y= %d, &x = %p, &y= %p\n", *x_ptr, *y_ptr, x_ptr, y_ptr);
    *x_ptr = *x_ptr + 1;
    if (*x_ptr > CURSOR_MAX_X){ // handle X wrapping
        printf("Handling cursor x overflow\n");
        *x_ptr = 0;
        *y_ptr = *y_ptr + 1;
        if (*y_ptr > CURSOR_MAX_Y){ // handle Y wrapping
            printf("Handling cursor y overflow\n");
            *y_ptr = 0;
        }
    }
    printf("Setting new page/col limits\n");
    printf("x = %d, y= %d, &x = %p, &y= %p\n", *x_ptr, *y_ptr, x_ptr, y_ptr);
    //ssd1306_set_cursor(*x_ptr, *y_ptr);
    printf("Done\n");
}

void u32_to_string(u32 data, u8* buf, u8 buf_len){
    // max value of u32 = 4,294,967,295
    u32 digit_val;
    u32 digit;
    u32 next_place_val = 10;
    u32 place_val = 1;
    u32 digit_pos = 0;
    // fill the buf with spaces
    for (u32 i = 0; i < buf_len; i++){
        buf[i] = ' ';
    }

    buf[buf_len - 1] = '\0'; // end the string
    while(data != 0){
        digit_val = data % next_place_val;   // get the value in that place (eg 40)
        data = data - digit_val;        // subtract this from the value left to convert
        digit = digit_val / place_val;  // get the digit in that place
        buf[buf_len - 2 - digit_pos] = digit + 48;  // convert to ASCII
        // move to next place
        place_val *= 10;
        next_place_val *= 10;
        digit_pos++;
    }
}

int main(void)
{
    u8 buf[20];
    u32_to_string(473589345, buf, 12);
    printf("\r\n=== OUTPUT ===\r\n");
    printf("%s", buf);
    printf("\r\n=== DONE ===\r\n");
}