#ifndef _SSD1306_H_
#define _SSD1306_H_

void i2c_delay(void);
void i2c_start(void);
void i2c_write_byte(char data);
void i2c_stop(void);

void ssd1306_display_init(void);
void ssd1306_display_sleep(void);

void ssd1306_whole_display_on(void);
void ssd1306_resume_ram_content(void);

void ssd1306_set_cursor(char x, char y);
void ssd1306_advance_cursor(char *x_ptr, char *y_ptr);

void ssd1306_write_solid_char(void);
void ssd1306_write_glyph(char id);
void ssd1306_clear_screen(void);
void ssd1306_fill_screen(char d);

void ssd1306_write_gram_byte(char d);

void ssd1306_set_address_mode(char mode);
void ssd1306_set_page_start_end(char start_page, char end_page);
void ssd1306_set_col_start_end(char start_col, char end_col);



#endif // _SSD1306_H_