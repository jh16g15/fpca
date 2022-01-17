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

#endif // _SSD1306_H_