
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity flex_vga_counters_tb is
    generic (
        runner_cfg : string
    );
end;

architecture bench of flex_vga_counters_tb is
    -- Clock period
    constant clk_period : time := 13.5 ns;
    -- Generics
    constant TARGET_LATENCY : natural range 1 to 20 := 1;
    -- Ports
    signal pixelclk : std_logic := '0';
    signal next_pixel : std_logic;
    signal next_line : std_logic;
    signal next_frame : std_logic;
    signal VGA_HSYNC : std_logic;
    signal VGA_VSYNC : std_logic;
    signal VGA_BLANK : std_logic;
begin

    flex_vga_counters_inst : entity work.flex_vga_counters
    generic map (
        TARGET_LATENCY => TARGET_LATENCY
    )
    port map (
        pixelclk => pixelclk,
        req_pixel => next_pixel,
        load_line => next_line,
        load_frame => next_frame,
        VGA_HSYNC => VGA_HSYNC,
        VGA_VSYNC => VGA_VSYNC,
        VGA_BLANK => VGA_BLANK
    );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("test_alive") then
                info("Hello world test_alive");
                wait for 17 ms; -- 60 fps
                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

    pixelclk <= not pixelclk after clk_period/2;

end;