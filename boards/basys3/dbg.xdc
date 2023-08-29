



create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list pll_inst/inst/clk_out25]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {soc_inst/cpu_top_inst/cpu_control_inst/state[0]} {soc_inst/cpu_top_inst/cpu_control_inst/state[1]} {soc_inst/cpu_top_inst/cpu_control_inst/state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 3 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {soc_inst/cpu_top_inst/cpu_control_inst/error_status[0]} {soc_inst/cpu_top_inst/cpu_control_inst/error_status[1]} {soc_inst/cpu_top_inst/cpu_control_inst/error_status[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {soc_inst/cpu_top_inst/current_pc[0]} {soc_inst/cpu_top_inst/current_pc[1]} {soc_inst/cpu_top_inst/current_pc[2]} {soc_inst/cpu_top_inst/current_pc[3]} {soc_inst/cpu_top_inst/current_pc[4]} {soc_inst/cpu_top_inst/current_pc[5]} {soc_inst/cpu_top_inst/current_pc[6]} {soc_inst/cpu_top_inst/current_pc[7]} {soc_inst/cpu_top_inst/current_pc[8]} {soc_inst/cpu_top_inst/current_pc[9]} {soc_inst/cpu_top_inst/current_pc[10]} {soc_inst/cpu_top_inst/current_pc[11]} {soc_inst/cpu_top_inst/current_pc[12]} {soc_inst/cpu_top_inst/current_pc[13]} {soc_inst/cpu_top_inst/current_pc[14]} {soc_inst/cpu_top_inst/current_pc[15]} {soc_inst/cpu_top_inst/current_pc[16]} {soc_inst/cpu_top_inst/current_pc[17]} {soc_inst/cpu_top_inst/current_pc[18]} {soc_inst/cpu_top_inst/current_pc[19]} {soc_inst/cpu_top_inst/current_pc[20]} {soc_inst/cpu_top_inst/current_pc[21]} {soc_inst/cpu_top_inst/current_pc[22]} {soc_inst/cpu_top_inst/current_pc[23]} {soc_inst/cpu_top_inst/current_pc[24]} {soc_inst/cpu_top_inst/current_pc[25]} {soc_inst/cpu_top_inst/current_pc[26]} {soc_inst/cpu_top_inst/current_pc[27]} {soc_inst/cpu_top_inst/current_pc[28]} {soc_inst/cpu_top_inst/current_pc[29]} {soc_inst/cpu_top_inst/current_pc[30]} {soc_inst/cpu_top_inst/current_pc[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {soc_inst/cpu_top_inst/current_instr[0]} {soc_inst/cpu_top_inst/current_instr[1]} {soc_inst/cpu_top_inst/current_instr[2]} {soc_inst/cpu_top_inst/current_instr[3]} {soc_inst/cpu_top_inst/current_instr[4]} {soc_inst/cpu_top_inst/current_instr[5]} {soc_inst/cpu_top_inst/current_instr[6]} {soc_inst/cpu_top_inst/current_instr[7]} {soc_inst/cpu_top_inst/current_instr[8]} {soc_inst/cpu_top_inst/current_instr[9]} {soc_inst/cpu_top_inst/current_instr[10]} {soc_inst/cpu_top_inst/current_instr[11]} {soc_inst/cpu_top_inst/current_instr[12]} {soc_inst/cpu_top_inst/current_instr[13]} {soc_inst/cpu_top_inst/current_instr[14]} {soc_inst/cpu_top_inst/current_instr[15]} {soc_inst/cpu_top_inst/current_instr[16]} {soc_inst/cpu_top_inst/current_instr[17]} {soc_inst/cpu_top_inst/current_instr[18]} {soc_inst/cpu_top_inst/current_instr[19]} {soc_inst/cpu_top_inst/current_instr[20]} {soc_inst/cpu_top_inst/current_instr[21]} {soc_inst/cpu_top_inst/current_instr[22]} {soc_inst/cpu_top_inst/current_instr[23]} {soc_inst/cpu_top_inst/current_instr[24]} {soc_inst/cpu_top_inst/current_instr[25]} {soc_inst/cpu_top_inst/current_instr[26]} {soc_inst/cpu_top_inst/current_instr[27]} {soc_inst/cpu_top_inst/current_instr[28]} {soc_inst/cpu_top_inst/current_instr[29]} {soc_inst/cpu_top_inst/current_instr[30]} {soc_inst/cpu_top_inst/current_instr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 8 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[0]} {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[1]} {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[2]} {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[3]} {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[4]} {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[5]} {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[6]} {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 3 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/state[0]} {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/state[1]} {soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 32 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {soc_inst/wb_cpu_sel_mosi[wdat][0]} {soc_inst/wb_cpu_sel_mosi[wdat][1]} {soc_inst/wb_cpu_sel_mosi[wdat][2]} {soc_inst/wb_cpu_sel_mosi[wdat][3]} {soc_inst/wb_cpu_sel_mosi[wdat][4]} {soc_inst/wb_cpu_sel_mosi[wdat][5]} {soc_inst/wb_cpu_sel_mosi[wdat][6]} {soc_inst/wb_cpu_sel_mosi[wdat][7]} {soc_inst/wb_cpu_sel_mosi[wdat][8]} {soc_inst/wb_cpu_sel_mosi[wdat][9]} {soc_inst/wb_cpu_sel_mosi[wdat][10]} {soc_inst/wb_cpu_sel_mosi[wdat][11]} {soc_inst/wb_cpu_sel_mosi[wdat][12]} {soc_inst/wb_cpu_sel_mosi[wdat][13]} {soc_inst/wb_cpu_sel_mosi[wdat][14]} {soc_inst/wb_cpu_sel_mosi[wdat][15]} {soc_inst/wb_cpu_sel_mosi[wdat][16]} {soc_inst/wb_cpu_sel_mosi[wdat][17]} {soc_inst/wb_cpu_sel_mosi[wdat][18]} {soc_inst/wb_cpu_sel_mosi[wdat][19]} {soc_inst/wb_cpu_sel_mosi[wdat][20]} {soc_inst/wb_cpu_sel_mosi[wdat][21]} {soc_inst/wb_cpu_sel_mosi[wdat][22]} {soc_inst/wb_cpu_sel_mosi[wdat][23]} {soc_inst/wb_cpu_sel_mosi[wdat][24]} {soc_inst/wb_cpu_sel_mosi[wdat][25]} {soc_inst/wb_cpu_sel_mosi[wdat][26]} {soc_inst/wb_cpu_sel_mosi[wdat][27]} {soc_inst/wb_cpu_sel_mosi[wdat][28]} {soc_inst/wb_cpu_sel_mosi[wdat][29]} {soc_inst/wb_cpu_sel_mosi[wdat][30]} {soc_inst/wb_cpu_sel_mosi[wdat][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 4 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {soc_inst/wb_cpu_sel_mosi[sel][0]} {soc_inst/wb_cpu_sel_mosi[sel][1]} {soc_inst/wb_cpu_sel_mosi[sel][2]} {soc_inst/wb_cpu_sel_mosi[sel][3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 32 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {soc_inst/wb_cpu_sel_mosi[adr][0]} {soc_inst/wb_cpu_sel_mosi[adr][1]} {soc_inst/wb_cpu_sel_mosi[adr][2]} {soc_inst/wb_cpu_sel_mosi[adr][3]} {soc_inst/wb_cpu_sel_mosi[adr][4]} {soc_inst/wb_cpu_sel_mosi[adr][5]} {soc_inst/wb_cpu_sel_mosi[adr][6]} {soc_inst/wb_cpu_sel_mosi[adr][7]} {soc_inst/wb_cpu_sel_mosi[adr][8]} {soc_inst/wb_cpu_sel_mosi[adr][9]} {soc_inst/wb_cpu_sel_mosi[adr][10]} {soc_inst/wb_cpu_sel_mosi[adr][11]} {soc_inst/wb_cpu_sel_mosi[adr][12]} {soc_inst/wb_cpu_sel_mosi[adr][13]} {soc_inst/wb_cpu_sel_mosi[adr][14]} {soc_inst/wb_cpu_sel_mosi[adr][15]} {soc_inst/wb_cpu_sel_mosi[adr][16]} {soc_inst/wb_cpu_sel_mosi[adr][17]} {soc_inst/wb_cpu_sel_mosi[adr][18]} {soc_inst/wb_cpu_sel_mosi[adr][19]} {soc_inst/wb_cpu_sel_mosi[adr][20]} {soc_inst/wb_cpu_sel_mosi[adr][21]} {soc_inst/wb_cpu_sel_mosi[adr][22]} {soc_inst/wb_cpu_sel_mosi[adr][23]} {soc_inst/wb_cpu_sel_mosi[adr][24]} {soc_inst/wb_cpu_sel_mosi[adr][25]} {soc_inst/wb_cpu_sel_mosi[adr][26]} {soc_inst/wb_cpu_sel_mosi[adr][27]} {soc_inst/wb_cpu_sel_mosi[adr][28]} {soc_inst/wb_cpu_sel_mosi[adr][29]} {soc_inst/wb_cpu_sel_mosi[adr][30]} {soc_inst/wb_cpu_sel_mosi[adr][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {soc_inst/wb_cpu_sel_miso[rdat][0]} {soc_inst/wb_cpu_sel_miso[rdat][1]} {soc_inst/wb_cpu_sel_miso[rdat][2]} {soc_inst/wb_cpu_sel_miso[rdat][3]} {soc_inst/wb_cpu_sel_miso[rdat][4]} {soc_inst/wb_cpu_sel_miso[rdat][5]} {soc_inst/wb_cpu_sel_miso[rdat][6]} {soc_inst/wb_cpu_sel_miso[rdat][7]} {soc_inst/wb_cpu_sel_miso[rdat][8]} {soc_inst/wb_cpu_sel_miso[rdat][9]} {soc_inst/wb_cpu_sel_miso[rdat][10]} {soc_inst/wb_cpu_sel_miso[rdat][11]} {soc_inst/wb_cpu_sel_miso[rdat][12]} {soc_inst/wb_cpu_sel_miso[rdat][13]} {soc_inst/wb_cpu_sel_miso[rdat][14]} {soc_inst/wb_cpu_sel_miso[rdat][15]} {soc_inst/wb_cpu_sel_miso[rdat][16]} {soc_inst/wb_cpu_sel_miso[rdat][17]} {soc_inst/wb_cpu_sel_miso[rdat][18]} {soc_inst/wb_cpu_sel_miso[rdat][19]} {soc_inst/wb_cpu_sel_miso[rdat][20]} {soc_inst/wb_cpu_sel_miso[rdat][21]} {soc_inst/wb_cpu_sel_miso[rdat][22]} {soc_inst/wb_cpu_sel_miso[rdat][23]} {soc_inst/wb_cpu_sel_miso[rdat][24]} {soc_inst/wb_cpu_sel_miso[rdat][25]} {soc_inst/wb_cpu_sel_miso[rdat][26]} {soc_inst/wb_cpu_sel_miso[rdat][27]} {soc_inst/wb_cpu_sel_miso[rdat][28]} {soc_inst/wb_cpu_sel_miso[rdat][29]} {soc_inst/wb_cpu_sel_miso[rdat][30]} {soc_inst/wb_cpu_sel_miso[rdat][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list soc_inst/cpu_top_inst/addr_align_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list soc_inst/cpu_top_inst/alu_func3_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list soc_inst/wb_spi_inst/cs_n_out]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list soc_inst/cpu_top_inst/mem_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list soc_inst/wb_spi_inst/miso_in]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list soc_inst/monitor_read_cmd_stb]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list soc_inst/monitor_write_cmd_stb]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list soc_inst/wb_spi_inst/mosi_out]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list soc_inst/cpu_top_inst/opcode_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list soc_inst/wb_spi_inst/sck_out]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe20]
set_property port_width 1 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/uart_rx_error]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/uart_rx_valid_out]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe22]
set_property port_width 1 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list {soc_inst/wb_cpu_sel_miso[ack]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe23]
set_property port_width 1 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list {soc_inst/wb_cpu_sel_miso[err]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe24]
set_property port_width 1 [get_debug_ports u_ila_0/probe24]
connect_debug_port u_ila_0/probe24 [get_nets [list {soc_inst/wb_cpu_sel_miso[stall]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe25]
set_property port_width 1 [get_debug_ports u_ila_0/probe25]
connect_debug_port u_ila_0/probe25 [get_nets [list {soc_inst/wb_cpu_sel_mosi[cyc]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe26]
set_property port_width 1 [get_debug_ports u_ila_0/probe26]
connect_debug_port u_ila_0/probe26 [get_nets [list {soc_inst/wb_cpu_sel_mosi[lock]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe27]
set_property port_width 1 [get_debug_ports u_ila_0/probe27]
connect_debug_port u_ila_0/probe27 [get_nets [list {soc_inst/wb_cpu_sel_mosi[stb]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe28]
set_property port_width 1 [get_debug_ports u_ila_0/probe28]
connect_debug_port u_ila_0/probe28 [get_nets [list {soc_inst/wb_cpu_sel_mosi[we]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk25]
