--Copyright (C)2014-2020 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--GOWIN Version: V1.9.6Beta
--Part Number: GW1NR-LV9QN88PC6/I5
--Created Time: Sat Feb 05 13:13:07 2022

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_rPLL
    port (
        clkout: out std_logic;
        lock: out std_logic;
        clkin: in std_logic
    );
end component;

your_instance_name: Gowin_rPLL
    port map (
        clkout => clkout_o,
        lock => lock_o,
        clkin => clkin_i
    );

----------Copy end-------------------
