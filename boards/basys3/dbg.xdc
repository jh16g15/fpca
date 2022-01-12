

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
connect_debug_port u_ila_0/clk [get_nets [list pll_inst/inst/clk_out50]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {simple_soc_inst/cpu_top_inst/cpu_control_inst/state[0]} {simple_soc_inst/cpu_top_inst/cpu_control_inst/state[1]} {simple_soc_inst/cpu_top_inst/cpu_control_inst/state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 3 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {simple_soc_inst/cpu_top_inst/cpu_control_inst/error_status[0]} {simple_soc_inst/cpu_top_inst/cpu_control_inst/error_status[1]} {simple_soc_inst/cpu_top_inst/cpu_control_inst/error_status[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {simple_soc_inst/cpu_top_inst/current_instr[0]} {simple_soc_inst/cpu_top_inst/current_instr[1]} {simple_soc_inst/cpu_top_inst/current_instr[2]} {simple_soc_inst/cpu_top_inst/current_instr[3]} {simple_soc_inst/cpu_top_inst/current_instr[4]} {simple_soc_inst/cpu_top_inst/current_instr[5]} {simple_soc_inst/cpu_top_inst/current_instr[6]} {simple_soc_inst/cpu_top_inst/current_instr[7]} {simple_soc_inst/cpu_top_inst/current_instr[8]} {simple_soc_inst/cpu_top_inst/current_instr[9]} {simple_soc_inst/cpu_top_inst/current_instr[10]} {simple_soc_inst/cpu_top_inst/current_instr[11]} {simple_soc_inst/cpu_top_inst/current_instr[12]} {simple_soc_inst/cpu_top_inst/current_instr[13]} {simple_soc_inst/cpu_top_inst/current_instr[14]} {simple_soc_inst/cpu_top_inst/current_instr[15]} {simple_soc_inst/cpu_top_inst/current_instr[16]} {simple_soc_inst/cpu_top_inst/current_instr[17]} {simple_soc_inst/cpu_top_inst/current_instr[18]} {simple_soc_inst/cpu_top_inst/current_instr[19]} {simple_soc_inst/cpu_top_inst/current_instr[20]} {simple_soc_inst/cpu_top_inst/current_instr[21]} {simple_soc_inst/cpu_top_inst/current_instr[22]} {simple_soc_inst/cpu_top_inst/current_instr[23]} {simple_soc_inst/cpu_top_inst/current_instr[24]} {simple_soc_inst/cpu_top_inst/current_instr[25]} {simple_soc_inst/cpu_top_inst/current_instr[26]} {simple_soc_inst/cpu_top_inst/current_instr[27]} {simple_soc_inst/cpu_top_inst/current_instr[28]} {simple_soc_inst/cpu_top_inst/current_instr[29]} {simple_soc_inst/cpu_top_inst/current_instr[30]} {simple_soc_inst/cpu_top_inst/current_instr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {simple_soc_inst/cpu_top_inst/current_pc[0]} {simple_soc_inst/cpu_top_inst/current_pc[1]} {simple_soc_inst/cpu_top_inst/current_pc[2]} {simple_soc_inst/cpu_top_inst/current_pc[3]} {simple_soc_inst/cpu_top_inst/current_pc[4]} {simple_soc_inst/cpu_top_inst/current_pc[5]} {simple_soc_inst/cpu_top_inst/current_pc[6]} {simple_soc_inst/cpu_top_inst/current_pc[7]} {simple_soc_inst/cpu_top_inst/current_pc[8]} {simple_soc_inst/cpu_top_inst/current_pc[9]} {simple_soc_inst/cpu_top_inst/current_pc[10]} {simple_soc_inst/cpu_top_inst/current_pc[11]} {simple_soc_inst/cpu_top_inst/current_pc[12]} {simple_soc_inst/cpu_top_inst/current_pc[13]} {simple_soc_inst/cpu_top_inst/current_pc[14]} {simple_soc_inst/cpu_top_inst/current_pc[15]} {simple_soc_inst/cpu_top_inst/current_pc[16]} {simple_soc_inst/cpu_top_inst/current_pc[17]} {simple_soc_inst/cpu_top_inst/current_pc[18]} {simple_soc_inst/cpu_top_inst/current_pc[19]} {simple_soc_inst/cpu_top_inst/current_pc[20]} {simple_soc_inst/cpu_top_inst/current_pc[21]} {simple_soc_inst/cpu_top_inst/current_pc[22]} {simple_soc_inst/cpu_top_inst/current_pc[23]} {simple_soc_inst/cpu_top_inst/current_pc[24]} {simple_soc_inst/cpu_top_inst/current_pc[25]} {simple_soc_inst/cpu_top_inst/current_pc[26]} {simple_soc_inst/cpu_top_inst/current_pc[27]} {simple_soc_inst/cpu_top_inst/current_pc[28]} {simple_soc_inst/cpu_top_inst/current_pc[29]} {simple_soc_inst/cpu_top_inst/current_pc[30]} {simple_soc_inst/cpu_top_inst/current_pc[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 8 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[0]} {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[1]} {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[2]} {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[3]} {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[4]} {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[5]} {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[6]} {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/byte_received_out[7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 32 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {simple_soc_inst/rw_regs_out[2][0]} {simple_soc_inst/rw_regs_out[2][1]} {simple_soc_inst/rw_regs_out[2][2]} {simple_soc_inst/rw_regs_out[2][3]} {simple_soc_inst/rw_regs_out[2][4]} {simple_soc_inst/rw_regs_out[2][5]} {simple_soc_inst/rw_regs_out[2][6]} {simple_soc_inst/rw_regs_out[2][7]} {simple_soc_inst/rw_regs_out[2][8]} {simple_soc_inst/rw_regs_out[2][9]} {simple_soc_inst/rw_regs_out[2][10]} {simple_soc_inst/rw_regs_out[2][11]} {simple_soc_inst/rw_regs_out[2][12]} {simple_soc_inst/rw_regs_out[2][13]} {simple_soc_inst/rw_regs_out[2][14]} {simple_soc_inst/rw_regs_out[2][15]} {simple_soc_inst/rw_regs_out[2][16]} {simple_soc_inst/rw_regs_out[2][17]} {simple_soc_inst/rw_regs_out[2][18]} {simple_soc_inst/rw_regs_out[2][19]} {simple_soc_inst/rw_regs_out[2][20]} {simple_soc_inst/rw_regs_out[2][21]} {simple_soc_inst/rw_regs_out[2][22]} {simple_soc_inst/rw_regs_out[2][23]} {simple_soc_inst/rw_regs_out[2][24]} {simple_soc_inst/rw_regs_out[2][25]} {simple_soc_inst/rw_regs_out[2][26]} {simple_soc_inst/rw_regs_out[2][27]} {simple_soc_inst/rw_regs_out[2][28]} {simple_soc_inst/rw_regs_out[2][29]} {simple_soc_inst/rw_regs_out[2][30]} {simple_soc_inst/rw_regs_out[2][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 32 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {simple_soc_inst/rw_regs_out[1][0]} {simple_soc_inst/rw_regs_out[1][1]} {simple_soc_inst/rw_regs_out[1][2]} {simple_soc_inst/rw_regs_out[1][3]} {simple_soc_inst/rw_regs_out[1][4]} {simple_soc_inst/rw_regs_out[1][5]} {simple_soc_inst/rw_regs_out[1][6]} {simple_soc_inst/rw_regs_out[1][7]} {simple_soc_inst/rw_regs_out[1][8]} {simple_soc_inst/rw_regs_out[1][9]} {simple_soc_inst/rw_regs_out[1][10]} {simple_soc_inst/rw_regs_out[1][11]} {simple_soc_inst/rw_regs_out[1][12]} {simple_soc_inst/rw_regs_out[1][13]} {simple_soc_inst/rw_regs_out[1][14]} {simple_soc_inst/rw_regs_out[1][15]} {simple_soc_inst/rw_regs_out[1][16]} {simple_soc_inst/rw_regs_out[1][17]} {simple_soc_inst/rw_regs_out[1][18]} {simple_soc_inst/rw_regs_out[1][19]} {simple_soc_inst/rw_regs_out[1][20]} {simple_soc_inst/rw_regs_out[1][21]} {simple_soc_inst/rw_regs_out[1][22]} {simple_soc_inst/rw_regs_out[1][23]} {simple_soc_inst/rw_regs_out[1][24]} {simple_soc_inst/rw_regs_out[1][25]} {simple_soc_inst/rw_regs_out[1][26]} {simple_soc_inst/rw_regs_out[1][27]} {simple_soc_inst/rw_regs_out[1][28]} {simple_soc_inst/rw_regs_out[1][29]} {simple_soc_inst/rw_regs_out[1][30]} {simple_soc_inst/rw_regs_out[1][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 32 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {simple_soc_inst/rw_regs_out[0][0]} {simple_soc_inst/rw_regs_out[0][1]} {simple_soc_inst/rw_regs_out[0][2]} {simple_soc_inst/rw_regs_out[0][3]} {simple_soc_inst/rw_regs_out[0][4]} {simple_soc_inst/rw_regs_out[0][5]} {simple_soc_inst/rw_regs_out[0][6]} {simple_soc_inst/rw_regs_out[0][7]} {simple_soc_inst/rw_regs_out[0][8]} {simple_soc_inst/rw_regs_out[0][9]} {simple_soc_inst/rw_regs_out[0][10]} {simple_soc_inst/rw_regs_out[0][11]} {simple_soc_inst/rw_regs_out[0][12]} {simple_soc_inst/rw_regs_out[0][13]} {simple_soc_inst/rw_regs_out[0][14]} {simple_soc_inst/rw_regs_out[0][15]} {simple_soc_inst/rw_regs_out[0][16]} {simple_soc_inst/rw_regs_out[0][17]} {simple_soc_inst/rw_regs_out[0][18]} {simple_soc_inst/rw_regs_out[0][19]} {simple_soc_inst/rw_regs_out[0][20]} {simple_soc_inst/rw_regs_out[0][21]} {simple_soc_inst/rw_regs_out[0][22]} {simple_soc_inst/rw_regs_out[0][23]} {simple_soc_inst/rw_regs_out[0][24]} {simple_soc_inst/rw_regs_out[0][25]} {simple_soc_inst/rw_regs_out[0][26]} {simple_soc_inst/rw_regs_out[0][27]} {simple_soc_inst/rw_regs_out[0][28]} {simple_soc_inst/rw_regs_out[0][29]} {simple_soc_inst/rw_regs_out[0][30]} {simple_soc_inst/rw_regs_out[0][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 32 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {simple_soc_inst/ro_regs_in[0][0]} {simple_soc_inst/ro_regs_in[0][1]} {simple_soc_inst/ro_regs_in[0][2]} {simple_soc_inst/ro_regs_in[0][3]} {simple_soc_inst/ro_regs_in[0][4]} {simple_soc_inst/ro_regs_in[0][5]} {simple_soc_inst/ro_regs_in[0][6]} {simple_soc_inst/ro_regs_in[0][7]} {simple_soc_inst/ro_regs_in[0][8]} {simple_soc_inst/ro_regs_in[0][9]} {simple_soc_inst/ro_regs_in[0][10]} {simple_soc_inst/ro_regs_in[0][11]} {simple_soc_inst/ro_regs_in[0][12]} {simple_soc_inst/ro_regs_in[0][13]} {simple_soc_inst/ro_regs_in[0][14]} {simple_soc_inst/ro_regs_in[0][15]} {simple_soc_inst/ro_regs_in[0][16]} {simple_soc_inst/ro_regs_in[0][17]} {simple_soc_inst/ro_regs_in[0][18]} {simple_soc_inst/ro_regs_in[0][19]} {simple_soc_inst/ro_regs_in[0][20]} {simple_soc_inst/ro_regs_in[0][21]} {simple_soc_inst/ro_regs_in[0][22]} {simple_soc_inst/ro_regs_in[0][23]} {simple_soc_inst/ro_regs_in[0][24]} {simple_soc_inst/ro_regs_in[0][25]} {simple_soc_inst/ro_regs_in[0][26]} {simple_soc_inst/ro_regs_in[0][27]} {simple_soc_inst/ro_regs_in[0][28]} {simple_soc_inst/ro_regs_in[0][29]} {simple_soc_inst/ro_regs_in[0][30]} {simple_soc_inst/ro_regs_in[0][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 32 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {simple_soc_inst/ro_regs_in[1][0]} {simple_soc_inst/ro_regs_in[1][1]} {simple_soc_inst/ro_regs_in[1][2]} {simple_soc_inst/ro_regs_in[1][3]} {simple_soc_inst/ro_regs_in[1][4]} {simple_soc_inst/ro_regs_in[1][5]} {simple_soc_inst/ro_regs_in[1][6]} {simple_soc_inst/ro_regs_in[1][7]} {simple_soc_inst/ro_regs_in[1][8]} {simple_soc_inst/ro_regs_in[1][9]} {simple_soc_inst/ro_regs_in[1][10]} {simple_soc_inst/ro_regs_in[1][11]} {simple_soc_inst/ro_regs_in[1][12]} {simple_soc_inst/ro_regs_in[1][13]} {simple_soc_inst/ro_regs_in[1][14]} {simple_soc_inst/ro_regs_in[1][15]} {simple_soc_inst/ro_regs_in[1][16]} {simple_soc_inst/ro_regs_in[1][17]} {simple_soc_inst/ro_regs_in[1][18]} {simple_soc_inst/ro_regs_in[1][19]} {simple_soc_inst/ro_regs_in[1][20]} {simple_soc_inst/ro_regs_in[1][21]} {simple_soc_inst/ro_regs_in[1][22]} {simple_soc_inst/ro_regs_in[1][23]} {simple_soc_inst/ro_regs_in[1][24]} {simple_soc_inst/ro_regs_in[1][25]} {simple_soc_inst/ro_regs_in[1][26]} {simple_soc_inst/ro_regs_in[1][27]} {simple_soc_inst/ro_regs_in[1][28]} {simple_soc_inst/ro_regs_in[1][29]} {simple_soc_inst/ro_regs_in[1][30]} {simple_soc_inst/ro_regs_in[1][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 3 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/state[0]} {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/state[1]} {simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 32 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {simple_soc_inst/rw_regs_out[3][0]} {simple_soc_inst/rw_regs_out[3][1]} {simple_soc_inst/rw_regs_out[3][2]} {simple_soc_inst/rw_regs_out[3][3]} {simple_soc_inst/rw_regs_out[3][4]} {simple_soc_inst/rw_regs_out[3][5]} {simple_soc_inst/rw_regs_out[3][6]} {simple_soc_inst/rw_regs_out[3][7]} {simple_soc_inst/rw_regs_out[3][8]} {simple_soc_inst/rw_regs_out[3][9]} {simple_soc_inst/rw_regs_out[3][10]} {simple_soc_inst/rw_regs_out[3][11]} {simple_soc_inst/rw_regs_out[3][12]} {simple_soc_inst/rw_regs_out[3][13]} {simple_soc_inst/rw_regs_out[3][14]} {simple_soc_inst/rw_regs_out[3][15]} {simple_soc_inst/rw_regs_out[3][16]} {simple_soc_inst/rw_regs_out[3][17]} {simple_soc_inst/rw_regs_out[3][18]} {simple_soc_inst/rw_regs_out[3][19]} {simple_soc_inst/rw_regs_out[3][20]} {simple_soc_inst/rw_regs_out[3][21]} {simple_soc_inst/rw_regs_out[3][22]} {simple_soc_inst/rw_regs_out[3][23]} {simple_soc_inst/rw_regs_out[3][24]} {simple_soc_inst/rw_regs_out[3][25]} {simple_soc_inst/rw_regs_out[3][26]} {simple_soc_inst/rw_regs_out[3][27]} {simple_soc_inst/rw_regs_out[3][28]} {simple_soc_inst/rw_regs_out[3][29]} {simple_soc_inst/rw_regs_out[3][30]} {simple_soc_inst/rw_regs_out[3][31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list simple_soc_inst/cpu_top_inst/addr_align_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
set_property port_width 1 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list simple_soc_inst/cpu_top_inst/alu_func3_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
set_property port_width 1 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list simple_soc_inst/cpu_top_inst/mem_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
set_property port_width 1 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list simple_soc_inst/cpu_top_inst/opcode_err]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
set_property port_width 1 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/uart_rx_error]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list simple_soc_inst/wb_uart_simple_inst/jh_uart_rx_inst/uart_rx_valid_out]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk50]
