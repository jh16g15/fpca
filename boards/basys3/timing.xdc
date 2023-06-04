
# This is already in the pins.xdc
# create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# for some reason the MMCM generates two clocks here from the same clock input
#set_clock_groups -physically_exclusive -group clk_out25_clk_wiz_0 -group clk_out25_clk_wiz_0_1

# These should probably just be false_pathed as async, but eh
create_clock -period 40.000 -name VIRTUAL_clk_out25_clk_wiz_0 -waveform {0.000 20.000}
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 20.000 [get_ports {sw[*]}]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 20.000 [get_ports {sw[*]}]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 20.000 [get_ports RsRx]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 20.000 [get_ports RsRx]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 20.000 [get_ports btnC]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 20.000 [get_ports btnC]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 20.000 [get_ports btnD]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 20.000 [get_ports btnD]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 20.000 [get_ports btnL]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 20.000 [get_ports btnL]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 20.000 [get_ports btnR]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 20.000 [get_ports btnR]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 20.000 [get_ports btnU]
set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 20.000 [get_ports btnU]
set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 10.000 [get_ports {vgaBlue[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 10.000 [get_ports {vgaBlue[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 10.000 [get_ports {vgaGreen[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 10.000 [get_ports {vgaGreen[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 10.000 [get_ports {vgaRed[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 10.000 [get_ports {vgaRed[*]}]
set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 10.000 [get_ports Hsync]
set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 10.000 [get_ports Hsync]
set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks clk] -group [get_clocks -include_generated_clocks sys_clk_pin]
#set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks clkfbout_clk_wiz_0] -group [get_clocks -include_generated_clocks clkfbout_clk_wiz_0_1]
