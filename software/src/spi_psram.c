#include "spi_psram.h"
#include "spi.h"
#include "printf.h"
#include "platform.h"

#define CMD_WRITE 0x02
#define CMD_READ 0x03
#define CMD_FAST_READ 0x0B

// #define CMD_QUAD_WRITE 0x38
// #define CMD_FAST_READ_QUAD 0xEB

#define CMD_RESET_ENABLE 0x66
#define CMD_RESET 0x99
#define CMD_READ_ID 0x9F

// 23 bit address
#define ADDR_HI_MASK 0x007F0000
#define ADDR_IN_MASK 0x0000FF00
#define ADDR_LO_MASK 0x000000FF

#define PSRAM_SPI_DATA (*((volatile unsigned long *)0x60000000))

static struct spi psram_spi;

void psram_init(void){
    spi_init(&psram_spi, (volatile void *)PLATFORM_PSRAM_BASE);
    // send reset-en => reset command?
    // psram_read_id();

}

// Writes a byte to PSRAM
void psram_write_byte(u32 addr, u8 data)
{
    // precalc address
    u8 addr_hi = (addr & ADDR_HI_MASK) >> 16;
    u8 addr_in = (addr & ADDR_IN_MASK) >> 8;
    u8 addr_lo = (addr & ADDR_LO_MASK);

    spi_stop(&psram_spi);
    spi_start(&psram_spi);
    PSRAM_SPI_DATA = CMD_WRITE;   // PSRAM Write

    PSRAM_SPI_DATA = addr_hi;   // PSRAM Address 22:16
    PSRAM_SPI_DATA = addr_in;   // PSRAM Address 15: 8
    PSRAM_SPI_DATA = addr_lo;   // PSRAM Address  7: 0
    PSRAM_SPI_DATA = data;
    spi_stop(&psram_spi);

    // printf_("Wrote byte 0x%x to   PSRAM address 0x%x\n", data, addr);
}

// Reads a byte from PSRAM
u8 psram_read_byte(u32 addr)
{

    // precalc address
    u8 addr_hi = (addr & ADDR_HI_MASK) >> 16;
    u8 addr_in = (addr & ADDR_IN_MASK) >> 8;
    u8 addr_lo = (addr & ADDR_LO_MASK);

    spi_stop(&psram_spi);
    spi_start(&psram_spi);
    PSRAM_SPI_DATA = CMD_READ;  // PSRAM Read (no wait states, max 33MHz)
    PSRAM_SPI_DATA = addr_hi;   // PSRAM Address 22:16
    PSRAM_SPI_DATA = addr_in;   // PSRAM Address 15: 8
    PSRAM_SPI_DATA = addr_lo;   // PSRAM Address  7: 0

    u8 data = (u8)PSRAM_SPI_DATA;
    spi_stop(&psram_spi);

    // printf_("Read  byte 0x%x from PSRAM address 0x%x\n", data, addr);
    return data;
}

// reads PSRAM ID register and confirms density
void psram_read_id(void)
{
    printf_("Reading PSRAM ID\n");
    spi_stop(&psram_spi);
    spi_start(&psram_spi);
    spi_write_byte(&psram_spi, CMD_READ_ID);   // PSRAM READ ID

    spi_write_byte(&psram_spi, 0xFF);   // PSRAM Address (unused for this cmd)
    spi_write_byte(&psram_spi, 0xFF);   // PSRAM Address (unused for this cmd)
    spi_write_byte(&psram_spi, 0xFF);   // PSRAM Address (unused for this cmd)

    u8 manu_id = spi_read_byte(&psram_spi);
    u8 kgd = spi_read_byte(&psram_spi);
    u8 eid[6];
    eid[5] = spi_read_byte(&psram_spi);
    eid[4] = spi_read_byte(&psram_spi);
    eid[3] = spi_read_byte(&psram_spi);
    eid[2] = spi_read_byte(&psram_spi);
    eid[1] = spi_read_byte(&psram_spi);
    eid[0] = spi_read_byte(&psram_spi);

    spi_stop(&psram_spi);
    u8 density = eid[5] >> 5;  // top 3 bits represent density
    u8 density_Mb = 2 << (density + 3);
    eid[5] = eid[5] & 0x1F;
    printf_("MANU: 0x%x, KGD: 0x%x, Capacity: %dMb, EID: 0x%x%x%x%x%x%x\n", manu_id, kgd, density_MB, eid[5], eid[4], eid[3], eid[2], eid[1], eid[0]);
}

