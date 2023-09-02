#include "cpu.h"

#ifdef BASYS3
#define BTN_U 3
#define BTN_L 2
#define BTN_R 1
#define BTN_D 0
#endif

#include "uart.h"
#include "gpio.h"
#include "utils.h"
// #include "ssd1306_i2c.h"
#include "spi.h"
#include "console.h"

#include "printf.h"
// #include "ff.h"
#include "diskio.h"

void wait_for_btn_press(int btn){
    while(get_bit(GPIO_BTN, btn) != 0){} // wait for 0
    while(get_bit(GPIO_BTN, btn) != 1){} // wait for 1
    while(get_bit(GPIO_BTN, btn) != 0){} // wait for 0
}

u8 spi_ram_read(u32 addr){
    spi_start();
    spi_write_byte(0x3); // send Read instruction
    // send 24-bit address
    spi_write_byte((0xFF0000 & addr) >> 16);
    spi_write_byte((0x00FF00 & addr) >> 8);
    spi_write_byte((0x0000FF & addr));
    // read byte
    u8 data = spi_read_byte();
    spi_stop();
    return data;
}

void spi_ram_write(u32 addr, u8 data){
    spi_start();
    spi_write_byte(0x2); // send Write instruction
    // send 24-bit address
    spi_write_byte((0xFF0000 & addr) >> 16);
    spi_write_byte((0x00FF00 & addr) >> 8);
    spi_write_byte((0x0000FF & addr));
    // write byte
    spi_write_byte(data);
    spi_stop();
}

void spi_check(u32 addr){
    u8 rdata;
    rdata = spi_ram_read(addr);
    Q_SSEG = rdata;
    GPIO_LED = addr;
    wait_for_btn_press(BTN_L);
}

void spi_test(){
    spi_ram_write(0x0, 0x00);
    spi_ram_write(0x1, 0x11);
    spi_ram_write(0x2, 0x22);
    spi_ram_write(0x3, 0x33);
    spi_ram_write(0x4, 0x44);
    spi_ram_write(0x5, 0x55);

    spi_check(0x0);
    spi_check(0x1);
    spi_check(0x2);
    spi_check(0x3);
    spi_check(0x4);
    spi_check(0x5);
}


void main(void)
{
    Q_SSEG = 0xc1de;
    uart_set_baud(9600);
    GPIO_LED = 0xF;

    // test SPI ram on PMOD B (working!!!)
    // spi_test();

    Q_SSEG = 0x0;
    // pointer to initial terminal created on the stack, containing the static address of the terminal
    console_init();
    cls();

    printf_("Hello World\n");

    disk_initialize(0);

    printf_("Console is working!\n");
    printf_("CPU Arch      : %s\n", "RISC-V RV32I");
    printf_("CPU Frequency : %i MHz\n", GPIO_SOC_FREQ/1000000);
    printf_("CPU Memory    : %i KB\n", GPIO_SOC_MEM/1024);


    int tmp = 21;
    int test_var = 0;

    printf_("Happy days! Test Var location (on stack): %p\n", &test_var);
    putchar_(1);
    putchar_(' ');
    putchar_(' ');
    putchar_(1);
    putchar_(' ');
    while(1){}
    while(1){
        putchar_(test_var);
        printf_("test_var=%i\n", test_var);
        test_var++;

        // cls();
    }


}