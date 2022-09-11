library ieee;
use ieee.std_logic_1164.all;

package pkg_vga_params_640_480_60hz is 
    -- from http://tinyvga.com/vga-timing/640x480@60Hz
    constant PIXELCLK_FREQ  : integer := 25000000; -- 25MHz (ideal 25.175MHz)
    constant END_ACTIVE_X   : integer := 640;
    constant FRONT_PORCH_X  : integer := 16;
    constant SYNC_PULSE_X   : integer := 96;
    constant BACK_PORCH_X   : integer := 48;
    
    constant END_FPORCH_X   : integer := END_ACTIVE_X + FRONT_PORCH_X;
    constant END_SYNC_X     : integer := END_FPORCH_X + SYNC_PULSE_X;
    constant END_BPORCH_X   : integer := END_SYNC_X + BACK_PORCH_X;     -- 800
    
    constant END_ACTIVE_Y   : integer := 480;
    constant FRONT_PORCH_Y  : integer := 10;
    constant SYNC_PULSE_Y   : integer := 2;
    constant BACK_PORCH_Y   : integer := 33;
    
    constant END_FPORCH_Y   : integer := END_ACTIVE_Y + FRONT_PORCH_Y;           
    constant END_SYNC_Y     : integer := END_FPORCH_Y + SYNC_PULSE_Y;            
    constant END_BPORCH_Y   : integer := END_SYNC_Y + BACK_PORCH_Y;     -- 525  
    
    -- '1' for active high, '0' for active low
    constant ACTIVE_HS  : std_logic := '0';
    constant ACTIVE_VS  : std_logic := '0';   
end pkg_vga_params_640_480_60hz;