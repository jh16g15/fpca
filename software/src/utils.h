#ifndef _DELAY_H_
#define _DELAY_H_

#include <stdint.h>

#define _BV(n) (1 << (n))
// set bit:  value = value | _BV(n)
// clr bit:  value = value & ~_BV(n)
#define _SET_BIT(reg, n) (reg) = (reg) | _BV((n))
#define _CLR_BIT(reg, n) (reg) = (reg) & ~_BV((n))

// Define type shorthands based on stdint.h
typedef uint32_t u32;
typedef uint16_t u16;
typedef uint8_t u8;

typedef int32_t s32;
typedef int16_t s16;
typedef int8_t s8;




void delay_ms(int dly_ms);
int get_bit(int reg, int bitnum);
char get_bit_char(char reg, int bitnum);

// access data bus
// only builds if defined as "static"
// use "volatile" to force LOAD/STORE usage

static inline void write_u32(u32 addr, u32 data){
    // create pointer to addr
    volatile u32 *ptr = (u32*)addr;
    *ptr = data; // set the data stored at the location "ptr" to "data"
}
static inline void write_u16(u32 addr, u16 data){
    volatile u16 *ptr = (u16*)addr;
    *ptr = data;
}
static inline void write_u8(u32 addr, u8 data){
    volatile u8 *ptr = (u8*)addr;
    *ptr = data;
}
static inline u32 read_u32(u32 addr){
    return *(volatile u32*)addr;
}
static inline u16 read_u16(u32 addr){
    return *(volatile u16*)addr;
}
static inline u8 read_u8(u32 addr){
    return *(volatile u8*)addr;
}

#endif // _DELAY_H_