/*
  -- Register Map
    -- x0: Read/Write byte trigger (7:0)
    -- x4: Chip Select (0)
    -- x8: SPI Throttle (7:0)
*/
#ifndef _SPI_H_
#define _SPI_H_


#define SPI_DATA (*((volatile unsigned long *)0x50000000))
#define SPI_CSN (*((volatile unsigned long *)0x50000004))
#define SPI_THROTTLE (*((volatile unsigned long *)0x50000008))

void spi_start(void);
void spi_stop(void);

// TEST BYTE WRITE
void spi_write_byte(char);
char spi_read_byte(void);
void spi_set_throttle(char throttle);

#endif // _SPI_H_