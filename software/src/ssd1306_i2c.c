

#include "ssd1306_i2c.h"
#include "utils.h"
#include "uart.h"


// using bit-bang GPIO I2C at approx 100KHz (SSD1306 supports up to 400KHz)
#define I2C_SCL (*((volatile unsigned long *)0x10000008))
#define I2C_SDA (*((volatile unsigned long *)0x1000000C))

#define CURSOR_MAX_X 16
#define CURSOR_MAX_Y 4

#define SSD1306_ADDR_W 0x78
#define SSD1306_ADDR_R 0x79

// #define SSD1306_CONTROL_COMMAND 0x80            // one command byte follows
#define SSD1306_CONTROL_COMMAND 0x00            // Continuous command bytes follow
#define SSD1306_CONTROL_DATA 0xC0               // one data byte follows
#define SSD1306_CONTROL_DATA_CONTINUOUS 0x40    //  Continuous data follows


#define SSD1306_ADDR_MODE_HORIZONTAL 0x0    // autoincrement to next page
#define SSD1306_ADDR_MODE_VERTICAL 0x1
#define SSD1306_ADDR_MODE_PAGE 0x2          // wrap around to start of same page

#define NUM_GLPYHS 4
/* Each glyph consists of 2 strips of 8 bytes (each byte is 8 pixels tall)
 * Total is 16 bytes
 */
char font_data[NUM_GLPYHS * 16] = {
    // solid block
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    // empty block
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    //checkerboard
    0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA,
    0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA,
    // borders
    0xff, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0xff,
    0xff, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0xff};

/*  This should give us a delay suitable for use in 100KHz I2C
    100KHz I2C will use a period of 50,000ns
    We want to toggle our clock every 25,000ns
    But, for safety may want to update SDA halfway through SCL being LOW
    so lets have an I2C delay every 12,500ns.

    At a 50MHz SYSCLK, this is a period of 20ns per cycle
    A NOP (ADDI) takes 5 cycles (s0 100ns)

*/
// Using `-O0`
// 13 for ~19KHz
// 6 for ~33KHz
// 5 for ~37KHz
// 4 for ~40KHz
// 3 for ~48KHz
// 1 for ~70KHz
#define I2C_DELAY_LOOP_COUNT 1

// Without LOOP, number of NO-OPs
// 3 NOPs for ~100KHz (peak 154KHz)
// 2 NOPs for ~108KHz (peak 170KHz)
// 1 NOPs for ~114KHz (peak 181KHz)
// quarter I2C clock period
void i2c_delay(void){
    // for (int i = I2C_DELAY_LOOP_COUNT; i>0; i--){
    // asm volatile( // 5 cycles each
    //     // "NOP;"
    //     // "NOP;"
    //     // "NOP;"

    // );
        /* -O0 loop maintenance:
        LW i                // 10 cycles
        ADDI i, -1          //  5 cycles
        SW i                // 10
        LW i                // 10
        BGTZ i              //  5

        so each loop is 40+work cycles long, (=45 in this case)

        This adds up to 45 * 20ns = 900 ns

        So for our 12500 ns delay, we need approx 13 loops for 100KHz (will still be slightly too long, but close enough)

        For 400KHz, we need a delay of

        */

    //}
}

void i2c_start(void){
    I2C_SCL = 1;
    I2C_SDA = 1;
    // full clock cycle delay
    i2c_delay();
    i2c_delay();
    i2c_delay();
    i2c_delay();
    I2C_SDA = 0;
    // full clock cycle delay
    i2c_delay();
    i2c_delay();
    i2c_delay();
    i2c_delay();
}

void i2c_write_byte(char data){
    char bit;   // transmit MSB first

    I2C_SCL = 0;
    for (int i = 7; i > -1; i--){   // i = 7,6,5...1,0
        i2c_delay();
        // now set SDA
        I2C_SDA = get_bit_char(data, i);
        i2c_delay();
        // rising edge of SCL
        I2C_SCL = 1;
        i2c_delay();
        i2c_delay();
        // falling edge of SCL
        I2C_SCL = 0;
    }
    // ACK/NACK
    i2c_delay();
    // if (NACK = 1){
    //     I2C_SDA = 1;
    // }
    i2c_delay();
    I2C_SCL = 1;
    i2c_delay();
    // read SDA now for ACK (not implemented)
    i2c_delay();
    I2C_SCL = 0;
    i2c_delay();
    I2C_SDA = 0;    // reset SDA to 0 ready for STOP condition
    i2c_delay();
}

void i2c_stop(void){
    I2C_SDA = 0;
    I2C_SCL = 1;
    // full clock cycle delay
    i2c_delay();
    i2c_delay();
    i2c_delay();
    i2c_delay();
    I2C_SDA = 1;
    // full clock cycle delay
    i2c_delay();
    i2c_delay();
    i2c_delay();
    i2c_delay();
}

void ssd1306_whole_display_on(void){
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0xa5);
    i2c_stop();
}

void ssd1306_resume_ram_content(void){
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0xa4);
    i2c_stop();
}

void ssd1306_display_init(void){
    // Charge pump setting -> Enable Charge Pump
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0x8d);
    i2c_write_byte(0x14);
    i2c_stop();
    // Display ON
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0xaf);
    i2c_stop();

    // set to Horizontal Address mode (wrap to next line/page)
    ssd1306_set_address_mode(SSD1306_ADDR_MODE_HORIZONTAL);
}

void ssd1306_display_sleep(void){
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0xae);
    i2c_stop();
}


void ssd1306_set_address_mode(char mode)
{
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0x20);   // set memory addressing mode
    i2c_write_byte(mode);
    i2c_stop();
}

// x and y is the character "coordinate" in the text-mode screen buffer
// the screen has 8 pages and 128 columns of pixels.

// each text-mode char is 8x16, so 8 columns `wide` and 2 pages `tall`

// this means that in text-mode, we have 4 lines of 16 character text,
// so x is range(0, 15) and y is range(0, 3)

// HORIZONTAL/VERTICAL ADDRESS MODE ONLY

void ssd1306_set_cursor(char x, char y)
{
    // 0-15 => 0-127
    char start_col = 8 * x;
    char end_col = start_col + 7;
    ssd1306_set_col_start_end(start_col, end_col);

    // 0-3 => 0-7
    char start_page = 2 * y;
    char end_page = start_page + 1;
    ssd1306_set_page_start_end(start_page, end_page);
}

void ssd1306_set_page_start_end(char start_page, char end_page)
{
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0x22);   // setup page start and end address
    i2c_write_byte(start_page);
    i2c_write_byte(end_page);
    i2c_stop();
}
void ssd1306_set_col_start_end(char start_col, char end_col)
{
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0x21);   // setup column start and end address
    i2c_write_byte(start_col);
    i2c_write_byte(end_col);
    i2c_stop();
}




void ssd1306_write_solid_char(void)
{
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_DATA_CONTINUOUS);
    // two `page` rows of 8 columns, so 16 bytes for a glyph
    for (int i = 0; i < 16;i++)
    {
        i2c_write_byte(0xff);
    }
    i2c_stop();
}

// TODO: is this data getting corrupted?
// Try splitting across multiple transactions
void ssd1306_write_glyph(char id)
{
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_DATA_CONTINUOUS);
    // two `page` rows of 8 columns, so 16 bytes for a glyph
    uart_puts("1");
    int index = id * 16;
    uart_puts("2");
    for (int i = 0; i < 16; i++)
    {
        i2c_write_byte(font_data[index+i]);
        // uart_puts(".");
    }
    uart_puts("3");
    i2c_stop();
}


void ssd1306_clear_screen(void)
{
    // 0 - 127
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0x21);   // setup column start and end address
    i2c_write_byte(0);
    i2c_write_byte(127);
    i2c_stop();
    // 0 - 7
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0x22);   // setup page start and end address
    i2c_write_byte(0);
    i2c_write_byte(7);
    i2c_stop();

    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_DATA_CONTINUOUS);
    int total_bytes = 128 * 8;
    for (int i = 0; i < total_bytes; i++){
        i2c_write_byte(0x00);
    }
    i2c_stop();
}

void ssd1306_fill_screen(char d)
{
    // 0 - 127
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0x21);   // setup column start and end address
    i2c_write_byte(0);
    i2c_write_byte(127);
    i2c_stop();
    // 0 - 7
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0x22);   // setup page start and end address
    i2c_write_byte(0);
    i2c_write_byte(7);
    i2c_stop();

    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_DATA_CONTINUOUS);
    int total_bytes = 128 * 8;
    for (int i = 0; i < total_bytes; i++){
        i2c_write_byte(d);
    }
    i2c_stop();
}

void ssd1306_write_gram_byte(char d)
{
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_DATA_CONTINUOUS);
    i2c_write_byte(d);
    i2c_stop();
}

// void ssd1306_write_gram_bytes(char *d, char num)
void ssd1306_write_gram_bytes(char d, char num)
{
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_DATA_CONTINUOUS);
    for (int i = 0; i < num; i++){
        // i2c_write_byte(d[i]);
        i2c_write_byte(d);
    }
    i2c_stop();
}

// pass x and y by reference to modify
void ssd1306_advance_cursor(char *x_ptr, char *y_ptr)
{
    uart_puts("Advancing Cursor");
    *x_ptr++;
    if (*x_ptr > CURSOR_MAX_X){ // handle X wrapping
        uart_puts("Handling cursor x overflow");
        *x_ptr = 0;
        *y_ptr++;
        if (*y_ptr > CURSOR_MAX_Y){ // handle Y wrapping
            uart_puts("Handling cursor y overflow");
            *y_ptr = 0;
        }
    }
    uart_puts("Setting new page/col limits");
    ssd1306_set_cursor(*x_ptr, *y_ptr);
    uart_puts("Done");
}