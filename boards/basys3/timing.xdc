
# This is already in the pins.xdc
# create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# for some reason the MMCM generates two clocks here from the same clock input
#set_clock_groups -physically_exclusive -group clk_out25_clk_wiz_0 -group clk_out25_clk_wiz_0_1

create_clock -period 40.000 -name VIRTUAL_clk_out25_clk_wiz_0 -waveform {0.000 20.000}

# False Path all "slow" IO
set_false_path -from [get_ports {sw[*]}]
set_false_path -to [get_ports {led[*]}]

set_false_path -from [get_ports btnC]
set_false_path -from [get_ports btnD]
set_false_path -from [get_ports btnL]
set_false_path -from [get_ports btnR]
set_false_path -from [get_ports btnU]

set_false_path -to [get_ports {JC[*]}]

set_false_path -to [get_ports {vgaBlue[*]}]
set_false_path -to [get_ports {vgaRed[*]}]
set_false_path -to [get_ports {vgaGreen[*]}]
set_false_path -to [get_ports Hsync]
set_false_path -to [get_ports Vsync]

set_false_path -to [get_ports {seg[*]}]
set_false_path -to [get_ports {an[*]}]
set_false_path -to [get_ports dp]

set_false_path -to [get_ports RsTx]
set_false_path -from [get_ports RsRx]


set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks clk] -group [get_clocks -include_generated_clocks sys_clk_pin]
#set_clock_groups -physically_exclusive -group [get_clocks -include_generated_clocks clkfbout_clk_wiz_0] -group [get_clocks -include_generated_clocks clkfbout_clk_wiz_0_1]

##create_clock -period 100.000 -name VIRTUAL_PSRAM_SCK -waveform {0.000 50.000}
#set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay 2.500 [get_ports {PSRAM_QSPI_SIO[*]}]
#set_input_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 6.000 [get_ports {PSRAM_QSPI_SIO[*]}]

## Should these be referred to a proper clock?
#create_clock -period 50.000 -name VIRTUAL_clk_out_mem_clk_wiz_0 -waveform {0.000 25.000}
#set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay -1.500 [get_ports {PSRAM_QSPI_SIO[*]}]
#set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 2.500 [get_ports {PSRAM_QSPI_SIO[*]}]
#set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay -2.500 [get_ports PSRAM_QSPI_CSN]
#set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 3.000 [get_ports PSRAM_QSPI_CSN]
#set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -min -add_delay -1.500 [get_ports PSRAM_QSPI_SCK]
#set_output_delay -clock [get_clocks VIRTUAL_clk_out25_clk_wiz_0] -max -add_delay 2.500 [get_ports PSRAM_QSPI_SCK]

