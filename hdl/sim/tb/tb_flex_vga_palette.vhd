
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.graphics_pkg.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity flex_vga_palette_tb is
    generic (
        runner_cfg : string
    );
end;

architecture bench of flex_vga_palette_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant MEM_ACCESS : boolean := true;
    -- Ports
    signal byte_in : std_logic_vector(7 downto 0);
    signal pixel_out : t_pixel;
    signal palette_select : std_logic := '0';
    signal memclk : std_logic := '0';
    signal addr : std_logic_vector(8 downto 0);
    signal we : std_logic := '0';
    signal stb : std_logic := '0';
    signal wdat : std_logic_vector(23 downto 0);
    signal rdat : std_logic_vector(23 downto 0);
    signal ack : std_logic;
begin

    flex_vga_palette_inst : entity work.flex_vga_palette
    generic map (
        MEM_ACCESS => MEM_ACCESS
    )
    port map (
        byte_in => byte_in,
        pixel_out => pixel_out,
        palette_select => palette_select,
        memclk => memclk,
        addr => addr,
        stb => stb,
        we => we,
        wdat => wdat,
        rdat => rdat,
        ack => ack
    );
    main : process
        variable pixel_data : std_logic_vector(23 downto 0);
        procedure read_palette_ram (index : in integer; rdata : out std_logic_vector(23 downto 0); pal : in std_logic := '0') is
        begin
            addr <= pal & uint2slv(index, 8);
            stb <= '1';
            we <= '0';
            wait until rising_edge(memclk);
            stb <= '0';
            
            if ack = '0' then
                wait until ack = '1' and rising_edge(memclk);
            end if;
            
            rdata := rdat;
            info("Read from palette " & to_string(pal) & " index " & to_string(index) & " was " & to_hstring(rdat));
        end procedure;

        procedure write_palette_ram (index : in integer; wdata : in std_logic_vector(23 downto 0); pal : in std_logic := '0') is
        begin
            addr <= pal & uint2slv(index, 8);
            stb <= '1';
            we <= '1';
            wdat <= wdata;
            wait until rising_edge(memclk);
            stb <= '0';
            we <= '0';
            if ack = '0' then
                wait until ack = '1' and rising_edge(memclk);
            end if;
            info("Write to palette " & to_string(pal) & " index " & to_string(index) & " of " & to_hstring(wdata));
        end procedure;
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("basic test") then
                info("Hello world test_alive");
                wait for 100 * clk_period;
                test_runner_cleanup(runner);
        
            elsif run("access test") then
                write_palette_ram(0, x"11_22_33", '0');
                wait until rising_edge(memclk);
                write_palette_ram(30, x"44_55_66", '1');
                wait until rising_edge(memclk);
                read_palette_ram(0, pixel_data, '0');
                check_equal(pixel_data, std_logic_vector'(x"11_22_33"));
                wait until rising_edge(memclk);
                read_palette_ram(30, pixel_data, '1');
                check_equal(pixel_data, std_logic_vector'(x"44_55_66"));
                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

memclk <= not memclk after clk_period/2;

end;