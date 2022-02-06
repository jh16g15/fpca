library ieee;
use ieee.std_logic_1164.all;

package pkg_lcd_params_480_272_60hz is

    constant PIXELCLK_FREQ  : integer := 9_000_000; -- 9MHz (ideal 9.175MHz)
    constant END_ACTIVE_X   : integer := 480;
    constant FRONT_PORCH_X  : integer := 8;
    constant SYNC_PULSE_X   : integer := 1;
    constant BACK_PORCH_X   : integer := 42;

    constant END_FPORCH_X   : integer := END_ACTIVE_X + FRONT_PORCH_X;
    constant END_SYNC_X     : integer := END_FPORCH_X + SYNC_PULSE_X;
    constant END_BPORCH_X   : integer := END_SYNC_X + BACK_PORCH_X;     -- 531

    constant END_ACTIVE_Y   : integer := 272;
    constant FRONT_PORCH_Y  : integer := 4;
    constant SYNC_PULSE_Y   : integer := 10;
    constant BACK_PORCH_Y   : integer := 2;

    constant END_FPORCH_Y   : integer := END_ACTIVE_Y + FRONT_PORCH_Y;
    constant END_SYNC_Y     : integer := END_FPORCH_Y + SYNC_PULSE_Y;
    constant END_BPORCH_Y   : integer := END_SYNC_Y + BACK_PORCH_Y;     -- 288

    -- '1' for active high, '0' for active low
    constant ACTIVE_HS  : std_logic := '1';
    constant ACTIVE_VS  : std_logic := '1';
end pkg_lcd_params_480_272_60hz;