// SD card settings

#ifndef _MMC_DEVICE_H_
#define _MMC_DEVICE_H_

#include "cpu.h"
#include "utils.h"

#define SPI_MAX_SPEED (REFCLK/2)

#define SPI_INIT_SPEED 200000 // 200KHz (100KHz - 400KHz)

#define SPI_THROTTLE_INIT ((SPI_MAX_SPEED/SPI_INIT_SPEED) - 1)
#define SPI_THROTTLE_RUN 0

void sd_command(u8 cmd, u32 arg, u8 crc);
u8 sd_response_r1();

#endif // _MMC_DEVICE_H_
