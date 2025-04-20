library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

entity sim_vga_log is
    generic(
        G_PROJECT_ROOT : string := "";
        G_LOG_NAME : string := "sim_vga_log.txt"
    );
    port(
        pixelclk : in std_logic;

        red   : in std_logic_vector(7 downto 0);
        green : in std_logic_vector(7 downto 0);
        blue  : in std_logic_vector(7 downto 0);

        blank : in std_logic;
        hsync : in std_logic;
        vsync : in std_logic
        
    );
end entity sim_vga_log;

architecture RTL of sim_vga_log is
    constant LOG_FILE_NAME : string := G_PROJECT_ROOT & G_LOG_NAME;
    signal hsync_d1 : std_logic:='0';
    signal vsync_d1 : std_logic:='0';
    
    signal hsync_edge : std_logic;
    signal vsync_edge : std_logic;
begin

    -- this works for all sync polarities, as there will always be a rising edge
    rising_edge_detect : process(pixelclk) is
    begin
        if rising_edge(pixelclk) then
            hsync_d1<=hsync;
            vsync_d1<=vsync;
        end if;
    end process;
    hsync_edge <= hsync and not hsync_d1;
    vsync_edge <= vsync and not vsync_d1;
    

    log_process : process(pixelclk) is
        file logfile : text open WRITE_MODE is LOG_FILE_NAME;
        variable log_ln : line;

        procedure write_pixel(ln : inout line) is
        begin
            write(ln, to_hstring(red));
            write(ln, string'(" "));
            write(ln, to_hstring(green));
            write(ln, string'(" "));
            write(ln, to_hstring(blue));
            write(ln, string'(", "));
        end procedure;
    begin
        if rising_edge(pixelclk) then
            if not blank then
                write_pixel(log_ln);
            end if;

            if hsync_edge then
                -- report "HSYNC";
                writeline(logfile, log_ln);
            end if;

            if vsync_edge then
                -- report "VSYNC";
                write(log_ln, string'("VSYNC"));
                writeline(logfile, log_ln);
            end if;
            

        end if;
    end process;
    


end architecture RTL;
