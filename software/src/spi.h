/*
  -- Register Map
    -- x0: Read/Write byte trigger (7:0)
    -- x4: Chip Select (0)
    -- x8: SPI Throttle (7:0)
*/
#ifndef _SPI_H_
#define _SPI_H_

#include "utils.h"


struct spi
{
    volatile u32 *registers;
};

void spi_init(struct spi *module, volatile void *base_address);

void spi_start(struct spi *module);
void spi_stop(struct spi *module);

// TEST BYTE WRITE
void spi_write_byte(struct spi *module, char);
char spi_read_byte(struct spi *module);
void spi_set_throttle(struct spi *module, char throttle);

#endif // _SPI_H_