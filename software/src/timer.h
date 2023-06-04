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

#ifndef _TIMER_H_
#define _TIMER_H_

#define TIMER1_COUNT (*((volatile unsigned long *)0x30000000))
#define TIMER1_CTRL (*((volatile unsigned long *)0x30000004))
#define TIMER1_TOP (*((volatile unsigned long *)0x30000008))
#define TIMER1_PWM (*((volatile unsigned long *)0x3000000C))

unsigned int timer_get_time(void);

void timer_start(void);
void timer_stop(void);

void timer_enable_interrupt(void);
void timer_disable_interrupt(void);
void timer_enable_pwm(void);
void timer_disable_pwm(void);
void timer_clear_oflow_flag(void);
int timer_get_oflow_flag(void);

void timer_set_threshold(unsigned int val);
unsigned int timer_get_threshold(void);
void timer_set_pwm_threshold(unsigned int val);
unsigned int timer_get_pwm_threshold(void);

#endif _TIMER_H_