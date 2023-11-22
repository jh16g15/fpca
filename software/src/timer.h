#ifndef _TIMER_H_
#define _TIMER_H_

#include "utils.h"

struct timer
{
    volatile u32 *registers;
};

void timer_init(struct timer *module, volatile void *base_address);

u32 timer_get_time(struct timer *module);

void timer_start(struct timer *module);
void timer_stop(struct timer *module);

void timer_enable_interrupt(struct timer *module);
void timer_disable_interrupt(struct timer *module);
void timer_enable_pwm(struct timer *module);
void timer_disable_pwm(struct timer *module);
void timer_clear_oflow_flag(struct timer *module);
int timer_get_oflow_flag(struct timer *module);

void timer_set_threshold(struct timer *module, u32 val);
u32 timer_get_threshold(struct timer *module);
void timer_set_pwm_threshold(struct timer *module, u32 val);
u32 timer_get_pwm_threshold(struct timer *module);

#endif // _TIMER_H_