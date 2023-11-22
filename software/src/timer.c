#include "timer.h"
/*
 *  Hardware Timer functions

    Register Map per timer
        x0: Current Value of time_reg (32b)
        R/W
        x4: Timer Control and Status register
        [0]      Timer Start/Stop
        [1]      Enable Overflow Interrupt
        [2]      Enable PWM mode
        [8]     Clear timer overflow
        [16]     Timer Overflow
        x8: Timer Threshold Register (32b)
        xC: PWM Threshold Register (32b)
 */
#define TIMER_REG_COUNT 0
#define TIMER_REG_CTRL 1
#define TIMER_REG_TOP 2
#define TIMER_REG_PWM 3

// initialise a timer struct with the base address so we can access the registers offset from a base address
void timer_init(struct timer *module, volatile void* base_address){
    module->registers = (volatile u32 *)base_address;
}

u32 timer_get_time(struct timer *module){
    return module->registers[TIMER_REG_COUNT];
}

void timer_start(struct timer *module){
    u32 tmp = module->registers[TIMER_REG_CTRL];
    tmp |= 0x1; // set bit 0
    module->registers[TIMER_REG_CTRL] = tmp;
}

void timer_stop(struct timer *module){
    unsigned int tmp = module->registers[TIMER_REG_CTRL];
    tmp &= ~0x1; // clear bit 0
    module->registers[TIMER_REG_CTRL] = tmp;
}


void timer_enable_interrupt(struct timer *module){
    unsigned int tmp = module->registers[TIMER_REG_CTRL];
    tmp |= 0x2; // set bit 1
    module->registers[TIMER_REG_CTRL] = tmp;
}


void timer_disable_interrupt(struct timer *module){
    unsigned int tmp = module->registers[TIMER_REG_CTRL];
    tmp &= ~0x2; // clear bit 1
    module->registers[TIMER_REG_CTRL] = tmp;
}

void timer_enable_pwm(struct timer *module){
    unsigned int tmp = module->registers[TIMER_REG_CTRL];
    tmp |= 0x4; // set bit 2
    module->registers[TIMER_REG_CTRL] = tmp;
}

void timer_disable_pwm(struct timer *module){
    unsigned int tmp = module->registers[TIMER_REG_CTRL];
    tmp &= ~0x4; // clear bit 2
    module->registers[TIMER_REG_CTRL] = tmp;
}

void timer_clear_oflow_flag(struct timer *module){
    unsigned int tmp = module->registers[TIMER_REG_CTRL];
    tmp &= ~(0x1 << 8); // clear bit 8
    module->registers[TIMER_REG_CTRL] = tmp;
}

int timer_get_oflow_flag(struct timer *module){
    unsigned int tmp = module->registers[TIMER_REG_CTRL];
    return tmp & (0x1 << 16);
}

void timer_set_threshold(struct timer *module, u32 val){
    module->registers[TIMER_REG_TOP] = val;
}

u32 timer_get_threshold(struct timer *module){
    return module->registers[TIMER_REG_TOP];
}

void timer_set_pwm_threshold(struct timer *module, u32 val){
    module->registers[TIMER_REG_PWM] = val;
}

u32 timer_get_pwm_threshold(struct timer *module){
    return module->registers[TIMER_REG_PWM];
}