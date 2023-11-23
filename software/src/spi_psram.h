
#ifndef _SPI_PSRAM_H_
#define _SPI_PSRAM_H_

#include "utils.h"
#include "spi.h"

void psram_init(void);
void psram_write_byte(u32 addr, u8 data);
u8 psram_read_byte(u32 addr);
void psram_read_id(void);

#endif // _SPI_PSRAM_H_