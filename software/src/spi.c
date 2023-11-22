#include "spi.h"


// 32bit registers
#define SPI_REG_DATA 0
#define SPI_REG_CSN 1
#define SPI_REG_THROTTLE 2

// initialise an SPI struct with the base address so we can access the registers
void spi_init(struct spi *module, volatile void* base_address){
    module->registers = (volatile uint32_t *)base_address;
}

// Start SPI transaction by asserting CS
void spi_start(struct spi *module){
    module->registers[SPI_REG_CSN] = 0;
}

// Start SPI transaction by deasserting CS
void spi_stop(struct spi *module){
    module->registers[SPI_REG_CSN] = 1;
}

// write a byte over SPI
void spi_write_byte(struct spi *module, char b){
    module->registers[SPI_REG_DATA] = b;
}

// read a byte from SPI
char spi_read_byte(struct spi *module){
    return (char)module->registers[SPI_REG_DATA];
}

// set number of clocks between SPI clocks
void spi_set_throttle(struct spi *module, char throttle){
    module->registers[SPI_REG_THROTTLE] = throttle;
}