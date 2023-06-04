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
#include "terminal.h"
#include "text_display.h"

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
    // if SW0 set on reset, jump to the bootloader
    // TODO: Move this to the crt0.s Startup script
    if (get_bit(GPIO_SW, 0))
    {
        // Jump to bootloader _start
        asm(
            "la t0,0xf0000000;"
            "jr t0;");
    }

    Q_SSEG = 0xc0de;
    uart_set_baud(9600);
    GPIO_LED = 0xF;

    spi_test();


    // initial setup of text framebuffer
    text_fill(0, 0, TEXT_MAX_X, TEXT_MAX_Y, GREY);
    text_string(1, 1, "=======================================", 39, WHITE, GREY);
    text_string(1, 2, "Friendly Programmable Computing Asset  ", 39, WHITE, GREY);
    text_string(1, 3, "=======================================", 39, WHITE, GREY);
    text_string(1, 4, "Architecture: RISC-V RV32I            ", 38, WHITE, GREY);
    text_string(1, 5, "Frequency: 25MHz                      ", 38, WHITE, GREY);
    text_string(1, 6, "Memory: 16KB                          ", 38, WHITE, GREY);
    text_string(1, 7, "Font Test:                            ", 38, WHITE, GREY);
    text_string(1, 8, "Colour Test:                          ", 38, WHITE, GREY);

    for (u32 i = 0; i < 16; i++)
    {
        write_u32((u32)0x10000000, i); // GPIO_LED
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
        uart_puts("Hello there, this acts as a delay\n");
    }

    // allocate a terminal for the text display
    t_terminal *t = terminal_create(TEXT_W, TEXT_H);

    u8* linebuf[80];
    u32 count = 0;
    terminal_clear(t);
    while(1){
        uart_puts("A");
        Q_SSEG = 0xc001;
        uart_puts("B");

        // add line number at start
        u32_to_hstring(count, linebuf, 80);
        terminal_write_string(t, linebuf);
        count++;

        terminal_write_string(t, " This is a string");
        terminal_write_string(t, " - Ahoy\n");

        Q_SSEG = 0xbeef;
        text_refresh_from_terminal(t);
    }
}