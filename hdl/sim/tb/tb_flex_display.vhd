library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.graphics_pkg.all;

entity tb_flex_display is
generic(
    G_PROJECT_ROOT : string := "C:/Users/joehi/Documents/fpga/fpca/"
);
end entity tb_flex_display;

architecture RTL of tb_flex_display is
	constant TARGET_LATENCY : natural range 1 to 20 := 5;
	constant END_ACTIVE_X : natural := 1024;
	constant FRONT_PORCH_X : natural := 48;
	constant SYNC_PULSE_X : natural := 80;
	constant BACK_PORCH_X : natural := 32;
	constant END_ACTIVE_Y : natural := 600;
	constant FRONT_PORCH_Y : natural := 3;
	constant SYNC_PULSE_Y : natural := 10;
	constant BACK_PORCH_Y : natural := 5;
	constant ACTIVE_HS : std_logic := '1';
	constant ACTIVE_VS : std_logic := '1';
	signal pixelclk : std_logic := '0';
	signal req_pixel : std_logic;
	signal load_line : std_logic;
	signal load_frame : std_logic;
	signal VGA_HSYNC : std_logic;
	signal VGA_VSYNC : std_logic;
	signal VGA_BLANK : std_logic;
	signal red_out : std_logic_vector(4 downto 0);
	signal green_out : std_logic_vector(5 downto 0);
	signal blue_out : std_logic_vector(4 downto 0);

    signal pixel : t_pixel := (x"00", x"00", x"00");

    constant PIXELCLK_PERIOD : time := 22.73 ns;
    
begin

    pixelclk <= not pixelclk after PIXELCLK_PERIOD/2;

    dut_counters : entity work.flex_vga_counters
        generic map(
            TARGET_LATENCY => TARGET_LATENCY,
            END_ACTIVE_X   => END_ACTIVE_X,
            FRONT_PORCH_X  => FRONT_PORCH_X,
            SYNC_PULSE_X   => SYNC_PULSE_X,
            BACK_PORCH_X   => BACK_PORCH_X,
            END_ACTIVE_Y   => END_ACTIVE_Y,
            FRONT_PORCH_Y  => FRONT_PORCH_Y,
            SYNC_PULSE_Y   => SYNC_PULSE_Y,
            BACK_PORCH_Y   => BACK_PORCH_Y,
            ACTIVE_HS      => ACTIVE_HS,
            ACTIVE_VS      => ACTIVE_VS
        )
        port map(
            pixelclk   => pixelclk,
            req_pixel  => req_pixel,
            load_line  => load_line,
            load_frame => load_frame,
            VGA_HSYNC  => VGA_HSYNC,
            VGA_VSYNC  => VGA_VSYNC,
            VGA_BLANK  => VGA_BLANK
        );

    dut_text : entity work.flex_display_text
        generic map(
            G_PROJECT_ROOT => G_PROJECT_ROOT,
            TARGET_LATENCY => TARGET_LATENCY,
            G_TEXT_RAM_DEPTH => 128 * 40
        )
        port map(
            pixelclk   => pixelclk,
            line_chars => uint2slv(in_uint => 128, new_len => 16),
            -- reset      => reset,
            req_pixel  => req_pixel,
            load_line  => load_line,
            load_frame => load_frame,
            red_out    => red_out,
            green_out  => green_out,
            blue_out   => blue_out
        );

    pixel.red(7 downto 3) <= red_out;
    pixel.green(7 downto 2) <= green_out;
    pixel.blue(7 downto 3) <= blue_out;
    
    sim_vga_log_inst : entity work.sim_vga_log
        generic map(
            G_PROJECT_ROOT => G_PROJECT_ROOT,
            G_LOG_NAME     => "tools/sim_vga_log.txt"
        )
        port map(
            pixelclk => pixelclk,
            red      => pixel.red,
            green    => pixel.green,
            blue     => pixel.blue,
            blank    => VGA_BLANK,
            hsync    => VGA_HSYNC,
            vsync    => VGA_VSYNC
        );
    

end architecture RTL;
