#ifndef _SSD1306_H_
#define _SSD1306_H_

#include "terminal.h"

// TODO: Clean this up into "public" and "private" prototypes
//       Only public prototypes should be visible here

/*
 *  Bitbanged I2C functions
 */
void i2c_delay(void);
void i2c_start(void);
void i2c_write_byte(char data);
void i2c_stop(void);


/*
 *  SSD1306 Hardware Control
 */
void ssd1306_display_init(void);
void ssd1306_display_sleep(void);

void ssd1306_whole_display_on(void);
void ssd1306_resume_ram_content(void);

void ssd1306_set_address_mode(char mode);
void ssd1306_set_page_start_end(char start_page, char end_page);
void ssd1306_set_col_start_end(char start_col, char end_col);

void ssd1306_write_gram_byte(char d);
void ssd1306_write_gram_bytes(char d, char num);

/*
 *  Deprecated SSD1306 text display functions
 */
void ssd1306_set_cursor(char x, char y);
void ssd1306_advance_cursor(char *x_ptr, char *y_ptr);

void ssd1306_write_solid_char(void);
void ssd1306_write_glyph(char id);
void ssd1306_clear_screen(void);
void ssd1306_fill_screen(char d);

void ssd1306_putc(char c, char *x_ptr, char *y_ptr);
void ssd1306_puts(char *s, char *x_ptr, char *y_ptr);
void ssd1306_newline(char *x_ptr, char *y_ptr);
void ssd1306_carriage_return(char *x_ptr, char *y_ptr);
void ssd1306_clearline(char *x_ptr, char *y_ptr);


/*
 *  New "terminal.h" support
 */
// flush the contents of a terminal buffer to the SSD1306
void ssd1306_refresh(t_terminal *t);

#endif // _SSD1306_H_