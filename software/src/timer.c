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

unsigned int timer_get_time(void){
    return TIMER1_COUNT;
}

void timer_start(void){
    unsigned int tmp = TIMER1_CTRL;
    tmp |= 0x1; // set bit 0
    TIMER1_CTRL = tmp;
}

void timer_stop(void){
    unsigned int tmp = TIMER1_CTRL;
    tmp &= ~0x1; // clear bit 0
    TIMER1_CTRL = tmp;
}


void timer_enable_interrupt(void){
    unsigned int tmp = TIMER1_CTRL;
    tmp |= 0x2; // set bit 1
    TIMER1_CTRL = tmp;
}


void timer_disable_interrupt(void){
    unsigned int tmp = TIMER1_CTRL;
    tmp &= ~0x2; // clear bit 1
    TIMER1_CTRL = tmp;
}

void timer_enable_pwm(void){
    unsigned int tmp = TIMER1_CTRL;
    tmp |= 0x4; // set bit 2
    TIMER1_CTRL = tmp;
}

void timer_disable_pwm(void){
    unsigned int tmp = TIMER1_CTRL;
    tmp &= ~0x4; // clear bit 2
    TIMER1_CTRL = tmp;
}

void timer_clear_oflow_flag(void){
    unsigned int tmp = TIMER1_CTRL;
    tmp &= ~(0x1 << 8); // clear bit 8
    TIMER1_CTRL = tmp;
}

int timer_get_oflow_flag(void){
    unsigned int tmp = TIMER1_CTRL;
    return tmp & (0x1 << 16);
}

void timer_set_threshold(unsigned int val){
    TIMER1_TOP = val;
}

unsigned int timer_get_threshold(void){
    return TIMER1_TOP;
}

void timer_set_pwm_threshold(unsigned int val){
    TIMER1_PWM = val;
}

unsigned int timer_get_pwm_threshold(void){
    return TIMER1_PWM;
}