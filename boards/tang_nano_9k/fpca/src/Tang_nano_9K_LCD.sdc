//Copyright (C)2014-2021 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.6.02 Beta
//Created Time: 2021-11-04 19:03:59
create_clock -name XTAL -period 37.037 -waveform {0 18.518} [get_ports {XTAL_IN}] -add
// 33 MHz for 800x480x60Hz
//create_clock -name LCD_CLK -period 30.03 -waveform {0 15.015} [get_ports {LCD_CLK}] -add
// 9 MHz for 480x272x60Hz
create_clock -name LCD_CLK -period 111.111 -waveform {0 55.555} [get_ports {LCD_CLK}] -add