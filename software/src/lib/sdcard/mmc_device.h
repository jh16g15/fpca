// SD card settings

#ifndef _MMC_DEVICE_H_
#define _MMC_DEVICE_H_

#include "cpu.h"
#include "utils.h"

#define SPI_MAX_SPEED (REFCLK/2)

#define SPI_INIT_SPEED 200000 // 200KHz (100KHz - 400KHz)

#define SPI_THROTTLE_INIT ((SPI_MAX_SPEED/SPI_INIT_SPEED) - 1)
#define SPI_THROTTLE_RUN 0

#define R1_MSB 0x80
#define R1_PARAM_ERR 0x40
#define R1_ADDR_ERR 0x20
#define R1_ERASE_ERR 0x10
#define R1_CRC_ERR 0x08
#define R1_ILLEGAL_CMD_ERR 0x04
#define R1_ERASE_RESET_ERR 0x02
#define R1_IDLE 0x01

// Voltage Accepted
#define VOLTAGE_ACC_2V7_3V6 0x01
#define VOLTAGE_ACC_LOW 0x02
#define VOLTAGE_ACC_RES1 0x04
#define VOLTAGE_ACC_RES2 0x08

#define OCR_POWER_UP_STATUS 0x80
#define OCR_CARD_CAPACITY_STATUS 0x40

void sd_command(u8 cmd, u32 arg, u8 crc);
u8 sd_response_r1();
u8 sd_response_r3r7(u8 *res);

void sd_power_up_init();
u8 sd_go_idle_state();
void sd_send_interface_condition(u8 *res);
void sd_read_operating_conditions_register(u8 *res);

void sd_print_r1(u8 res);
void sd_print_r3(u8 *res);
void sd_print_r7(u8 *res);

#endif // _MMC_DEVICE_H_
