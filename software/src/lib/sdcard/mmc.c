
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

#define CMD8 8
#define CMD8_ARG 0x000001AA    // 3v3 supplied, check pattern 0xAA
#define CMD8_CRC 0x86   // precalculated

#define CMD58 58
#define CMD58_ARG 0x00000000
#define CMD58_CRC 0x00   // not required

#define CMD55 55
#define CMD55_ARG 0x00000000
#define CMD55_CRC 0x00   // not required

#define ACMD41 41
#define ACMD41_ARG 0x40000000   // support High Capacity SD cards
#define ACMD41_CRC 0x00   // not required


DSTATUS disk_initialize (BYTE pdrv){
    printf_("Starting Disk Initialisation...\n");
    sd_power_up_init();
    u8 status = sd_go_idle_state();
    if (status != 0){
        return status;
    }

    u8 res[5]; // create buffer for R3/R7 responses etc
    sd_send_interface_condition(res);
    sd_print_r7(res);

    sd_read_operating_conditions_register(res);
    sd_print_r3(res);

    // TODO add a 1s timeout here to meet SD card spec
    while(1){
        res[0] = sd_send_operating_condition();
        sd_print_r1(res[0]);
        if(res[0] == R1_VALUE_READY){
            break;
        }
    }
    sd_read_operating_conditions_register(res);
    sd_print_r3(res);
    printf_("Disk Initialisation Complete!\n\n");
    return 0;
}

// set CSn low to start a transaction
void sd_spi_start(){
    spi_write_byte(0xff);
    spi_start();
    spi_write_byte(0xff);
}
// set CSn high to end a transaction
void sd_spi_stop(){
    spi_write_byte(0xff);
    spi_stop(); // set CSn high
    spi_write_byte(0xff);
}



void sd_power_up_init(){
    printf_("Setting SPI Speed to ~200KHz\n");
    // set speed to 200KHz for SD card initialisation
    spi_set_throttle(SPI_THROTTLE_INIT);

    // TODO wait for 1ms after power on
    // not important right now as we take way more than 1ms to program the FPGA

    printf_("Entering SD Card Native Mode\n");
    sd_spi_stop(); // set CS high

    for (int i = 0; i < 10;i++){ // over 74 "dummy clocks" with DI and CS high
        spi_write_byte(0xff);   // to enter Native operating mode
    }
}

// send CMD0 (software reset) with CS low to enter SPI operating mode
u8 sd_go_idle_state(){
    printf_("Entering SD Card SPI Mode\n");
    sd_spi_start();

    sd_command(CMD0, CMD0_ARG, CMD0_CRC);
    printf_("Waiting for SD Card Response...\n");
    u8 res1 = sd_response_r1();
    printf_("SD Card Response 0x%x\n", res1);
    sd_print_r1(res1);
    if (res1 != 1){
        return STA_NOINIT; // return error
    }
    sd_spi_stop(); // set CSn high again
    return 0;
}

// send CMD8 to inform SD card of supplied voltage. Fills a 5-byte "res" buffer with an R7 response
void sd_send_interface_condition(u8 *res){
    printf_("Sending Interface Condition to SD Card...\n");
    sd_spi_start();
    sd_command(CMD8, CMD8_ARG, CMD8_CRC);
    sd_response_r3r7(res);
    sd_spi_stop();
}

// send CMD58 to check SD card supported voltage and capacity. Fills a 5-byte "res" buffer with an R3 response
void sd_read_operating_conditions_register(u8 *res){
    printf_("Reading SD Card Operating Conditions Register...\n");
    sd_spi_start();
    sd_command(CMD58, CMD58_ARG, CMD58_CRC);
    sd_response_r3r7(res);
    sd_spi_stop();
}

// send ACMD41 to inford SD card of capacity support and begin initialisation
u8 sd_send_operating_condition(){
    printf_("Sending SD Card Operating Conditions to start init...\n");

    // send preceding CMD55 as ACMD41 is an application specific command
    sd_spi_start();
    sd_command(CMD55, CMD55_ARG, CMD55_CRC);
    sd_response_r1();
    sd_spi_stop;

    // send ACMD41 to start/query initialisation
    sd_spi_start();
    sd_command(ACMD41, ACMD41_ARG, ACMD41_CRC);
    u8 res = sd_response_r1();
    sd_spi_stop;
    return res;
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

// Get an R1 1-byte response from the SD card
u8 sd_response_r1(){
    u8 i = 0, res1;

    // poll until response data received
    while((res1 = spi_read_byte()) == 0xff){
        // printf_("spi read byte: 0x%x\n", res1);
        i++;
        if(i > 8) break; // timeout and return 0xFF
    }
    return res1;
}

// Get an R7 5-byte response from the SD card (first byte is R1 response)
u8 sd_response_r3r7(u8 *res){
    res[0] = sd_response_r1();
    if (res[0] > 1) // if error
    {
        return res[0];  // return early
    }
    res[1] = spi_read_byte();   // 31:24
    res[2] = spi_read_byte();   // 23:16
    res[3] = spi_read_byte();   // 15: 8
    res[4] = spi_read_byte();   //  7: 0
    return res[0];
}

void sd_print_r1(u8 res){
    if(res & R1_MSB){
        printf_("Error: MSB=1\n"); return;
    }
    if(res == 0){
        printf_("Card Ready\n"); return;
    }
    if(res & R1_PARAM_ERR){
        printf_("Parameter Error\n");
    }
    if(res & R1_ADDR_ERR){
        printf_("Address Error\n");
    }
    if(res & R1_ERASE_ERR){
        printf_("Erase Sequence Error\n");
    }
    if(res & R1_CRC_ERR){
        printf_("CRC Error\n");
    }
    if(res & R1_ILLEGAL_CMD_ERR){
        printf_("Illegal Command Error\n");
    }
    if(res & R1_ERASE_RESET_ERR){
        printf_("Erase Reset Error\n");
    }
    if(res & R1_IDLE){
        printf_("In Idle State\n");
    }
}
void sd_print_r3(u8 *res){
    sd_print_r1(res[0]);
    if (res[0] > 1) {
        return;
    }

    if (res[2] & OCR_VOLTAGE_WINDOW_2V8_3V6 == 0xff){
        printf_("Voltage window 2.8V - 3.6V supported\n");
    } else {
        printf_("Not all voltages in 2.8V - 3.6V supported by this card : 0x%x\n", res[2]);
    }

    if (res[1] & OCR_POWER_UP_STATUS){
        printf_("CCS: %i, SD card is ", (res[1] & OCR_CARD_CAPACITY_STATUS)>>6);
        if (!(res[1] & OCR_CARD_CAPACITY_STATUS)){
            printf_("not ");
        }
        printf_("SDHC or SDXC\n");
    } else {
        printf_("Card not initialised\n");
    }
}

void sd_print_r7(u8 *res){
    sd_print_r1(res[0]);
    if (res[0] > 1) {
        return;
    }
    printf_("Command Version : %i\n", (res[1] & 0xF0) >> 4);
    printf_("Voltage Accepted: ");
    if ((res[3] & 0x0F) == VOLTAGE_ACC_2V7_3V6){
        printf_("2.7V - 3.6V\n");
    } else {printf_("Other (ERR)\n");}
    printf_("Echo : 0x%X\n", res[4]);
}



