--------------------------------------------------------------------------------
-- Engineer:      Mike Field <hamster@snap.net.nz>
-- Description:   Converts VGA signals into DVID bitstreams.
--
--                'clk' and 'clk_n' should be 5x vga_pixelclk.
--
--                'vga_blank' should be asserted during the non-display
--                portions of the frame
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity dvid is
    port (
        dvi_clk      : in std_logic;
        dvi_clkn     : in std_logic;
        vga_pixelclk : in std_logic;
        vga_red      : in std_logic_vector (7 downto 0);
        vga_green    : in std_logic_vector (7 downto 0);
        vga_blue     : in std_logic_vector (7 downto 0);
        vga_blank    : in std_logic;
        vga_hsync    : in std_logic;
        vga_vsync    : in std_logic;

        tmds      : out std_logic_vector(2 downto 0);
        tmdsn     : out std_logic_vector(2 downto 0);
        tmds_clk  : out std_logic;
        tmds_clkn : out std_logic);

end dvid;

architecture behavioral of dvid is
    component TDMS_encoder
        port (
            clk       : in std_logic;
            data      : in std_logic_vector(7 downto 0);
            c         : in std_logic_vector(1 downto 0);
            blank : in std_logic;
            encoded   : out std_logic_vector(9 downto 0)
        );
    end component;

    signal encoded_red, encoded_green, encoded_blue : std_logic_vector(9 downto 0);
    signal latched_red, latched_green, latched_blue : std_logic_vector(9 downto 0) := (others => '0');
    signal shift_red, shift_green, shift_blue       : std_logic_vector(9 downto 0) := (others => '0');

    signal shift_clock : std_logic_vector(9 downto 0) := "0000011111";
    constant c_red     : std_logic_vector(1 downto 0) := (others => '0');
    constant c_green   : std_logic_vector(1 downto 0) := (others => '0');
    signal c_blue      : std_logic_vector(1 downto 0);

    signal red_s   : std_logic;
    signal green_s : std_logic;
    signal blue_s  : std_logic;
    signal clock_s : std_logic;

begin
    c_blue <= vga_vsync & vga_hsync;

    TDMS_encoder_red   : TDMS_encoder port map(clk => vga_pixelclk, data => vga_red, c => c_red, blank => vga_blank, encoded => encoded_red);
    TDMS_encoder_green : TDMS_encoder port map(clk => vga_pixelclk, data => vga_green, c => c_green, blank => vga_blank, encoded => encoded_green);
    TDMS_encoder_blue  : TDMS_encoder port map(clk => vga_pixelclk, data => vga_blue, c => c_blue, blank => vga_blank, encoded => encoded_blue);

    ODDR2_red : ODDR2 generic map(DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC")
    port map(Q => red_s, D0 => shift_red(0), D1 => shift_red(1), C0 => dvi_clk, C1 => dvi_clkn, CE => '1', R => '0', S => '0');

    ODDR2_green : ODDR2 generic map(DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC")
    port map(Q => green_s, D0 => shift_green(0), D1 => shift_green(1), C0 => dvi_clk, C1 => dvi_clkn, CE => '1', R => '0', S => '0');

    ODDR2_blue : ODDR2 generic map(DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC")
    port map(Q => blue_s, D0 => shift_blue(0), D1 => shift_blue(1), C0 => dvi_clk, C1 => dvi_clkn, CE => '1', R => '0', S => '0');

    ODDR2_clock : ODDR2 generic map(DDR_ALIGNMENT => "C0", INIT => '0', SRTYPE => "ASYNC")
    port map(Q => clock_s, D0 => shift_clock(0), D1 => shift_clock(1), C0 => dvi_clk, C1 => dvi_clkn, CE => '1', R => '0', S => '0');

    OBUFDS_blue  : OBUFDS port map(O => TMDS(0), OB => TMDSN(0), I => blue_s);
    OBUFDS_red   : OBUFDS port map(O => TMDS(1), OB => TMDSN(1), I => green_s);
    OBUFDS_green : OBUFDS port map(O => TMDS(2), OB => TMDSN(2), I => red_s);
    OBUFDS_clock : OBUFDS port map(O => tmds_clk, OB => tmds_clkn, I => clock_s);

    process (vga_pixelclk)
    begin
        if rising_edge(vga_pixelclk) then
            latched_red   <= encoded_red;
            latched_green <= encoded_green;
            latched_blue  <= encoded_blue;
        end if;
    end process;

    process (dvi_clk)
    begin
        if rising_edge(dvi_clk) then
            if shift_clock = "0000011111" then
                shift_red   <= latched_red;
                shift_green <= latched_green;
                shift_blue  <= latched_blue;
            else
                shift_red   <= "00" & shift_red (9 downto 2);
                shift_green <= "00" & shift_green(9 downto 2);
                shift_blue  <= "00" & shift_blue (9 downto 2);
            end if;
            shift_clock <= shift_clock(1 downto 0) & shift_clock(9 downto 2);
        end if;
    end process;

end Behavioral;