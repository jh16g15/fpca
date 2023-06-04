#include "spi.h"

void spi_start(void){
    SPI_CSN = 0;
}

void spi_stop(void){
    SPI_CSN = 1;
}

void spi_write_byte(char b){
    SPI_DATA = b;
}

char spi_read_byte(void){
    return (char)SPI_DATA;
}

void spi_set_throttle(char throttle){
    SPI_THROTTLE = throttle;
}