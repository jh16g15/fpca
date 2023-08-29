#include "spi.h"

// Start SPI transaction by asserting CS
void spi_start(void){
    SPI_CSN = 0;
}

// Start SPI transaction by deasserting CS
void spi_stop(void){
    SPI_CSN = 1;
}

// write a byte over SPI
void spi_write_byte(char b){
    SPI_DATA = b;
}

// read a byte from SPI
char spi_read_byte(void){
    return (char)SPI_DATA;
}

// set number of clocks between SPI clocks
void spi_set_throttle(char throttle){
    SPI_THROTTLE = throttle;
}