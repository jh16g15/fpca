

#include "ssd1306_i2c.h"
#include "utils.h"


// using bit-bang GPIO I2C at approx 100KHz (SSD1306 supports up to 400KHz)
#define I2C_SCL (*((volatile unsigned long *)0x10000008))
#define I2C_SDA (*((volatile unsigned long *)0x1000000C))

#define SSD1306_ADDR_W 0x78
#define SSD1306_ADDR_R 0x79

// #define SSD1306_ADDR_W 0x7a
// #define SSD1306_ADDR_R 0x7b

// Bit 7: Continuation (only valid for DATA control words)
//  Co=0 for just data bytes following
//  Co=1 for alternating control/data

// Bit 6: D/C# (Data/Command byte)
// D = 1 for next byte DATA (for GDDRAM)
// D = 0 for next byte COMMAND
// #define SSD1306_CONTROL_COMMAND 0x80            // one command byte (also try 0x00 from QMK oled_driver.c)
#define SSD1306_CONTROL_COMMAND 0x00            // one command byte (also try 0x00 from QMK oled_driver.c)
#define SSD1306_CONTROL_DATA 0xC0               // one data byte follows
#define SSD1306_CONTROL_DATA_CONTINUOUS 0x40    //  Continuous data follows


/*  This should give us a delay suitable for use in 100KHz I2C
    100KHz I2C will use a period of 50,000ns
    We want to toggle our clock every 25,000ns
    But, for safety may want to update SDA halfway through SCL being LOW
    so lets have an I2C delay every 12,500ns.

    At a 50MHz SYSCLK, this is a period of 20ns per cycle

    A NOP (ADDI) takes 5 cycles (s0 100ns)

    so excluding the loop maintenance, we need 125 NOPs between I2C 'events'

*/
// quarter I2C clock period
void i2c_delay(void){
    for (int i = 13; i>0; i--){
        asm volatile(       // 5 cycles
            "NOP"
        );
        /* -O0 loop maintenance:
        LW i                // 10 cycles
        ADDI i, -1          //  5 cycles
        SW i                // 10
        LW i                // 10
        BGTZ i              //  5

        so each loop is 40+work cycles long, (=45 in this case)

        This adds up to 45 * 20ns = 900 ns

        So for our 12500 ns delay, we need approx 13 loops (will still be slightly too long, but close enough)

        */

    }
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
}

void ssd1306_display_sleep(void){
    i2c_start();
    i2c_write_byte(SSD1306_ADDR_W);
    i2c_write_byte(SSD1306_CONTROL_COMMAND);
    i2c_write_byte(0xae);
    i2c_stop();
}