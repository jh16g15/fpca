
#include "mmc_device.h"
#include "spi.h"
#include "utils.h"

#include "printf.h"

// #include "timer.h"
#include "ff.h"    // for typedefs
#include "diskio.h"

// -I must be included for this to work
#include "ff.h"
#include "diskio.h"

// based on http://elm-chan.org/docs/mmc/mmc_e.html and http://www.rjhcoding.com/avrc-sd-interface-1.php

#define CMD0 0
#define CMD0_ARG 0x00000000
#define CMD0_CRC 0x94   // precalculated



DSTATUS disk_initialize (BYTE pdrv){
    printf_("Starting Disk Initialisation!\n");

    printf_("Setting SPI Speed to ~200KHz\n");
    // set speed to 200KHz for SD card initialisation
    spi_set_throttle(SPI_THROTTLE_INIT);

    // TODO wait for 1ms after power on
    // not important right now as we take way more than 1ms to program the FPGA

    printf_("Entering SD Card Native Mode\n");

    spi_write_byte(0xff);
    spi_stop(); // set CS high
    spi_write_byte(0xff);

    for (int i = 0; i < 10;i++){ // over 74 "dummy clocks" with DI and CS high
        spi_write_byte(0xff);   // to enter Native operating mode
    }

    printf_("Entering SD Card SPI Mode\n");
    // send CMD0 (software reset) with CS low to enter SPI operating mode



    spi_write_byte(0xff);
    spi_start(); // set CSn low
    spi_write_byte(0xff);

    sd_command(CMD0, CMD0_ARG, CMD0_CRC);
    printf_("Waiting for SD Card Response...\n");
    u8 res1 = sd_response_r1();
    printf_("SD Card Response %x\n", res1);

    spi_write_byte(0xff);
    spi_stop(); // set CSn high again
    spi_write_byte(0xff);

    printf_("How did that go?\n");
}

void sd_command(u8 cmd, u32 arg, u8 crc){
    //transmit command
    spi_write_byte(0x40 | cmd); // set start bit (0) and transmission bit (1)

    //transmit argument
    spi_write_byte((u8)(arg>>24));  // MSB first
    spi_write_byte((u8)(arg>>16));
    spi_write_byte((u8)(arg>>8));
    spi_write_byte((u8)arg);

    //transmit crc and stop bit
    spi_write_byte(crc | 0x01); // set stop bit (1)
}

u8 sd_response_r1(){
    u8 i = 0, res1;

    // poll until response data received
    while((res1 = spi_read_byte()) == 0xFF){
        printf_("spi read byte: 0x%x\n", res1);
        i++;
        if(i > 8) break; // timeout and return 0xFF
    }
    return res1;
}