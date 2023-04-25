----------------------------------------------------------------------------------
-- Company:
-- Engineer: Joseph Hindmarsh
--
-- Create Date: 06.06.2020 13:45:07
-- Design Name:
-- Module Name: display_text_controller - rtl
-- Project Name:
-- Target Devices: xc7a35tcpg236-1 Artix 7 35T on Basys3
-- Tool Versions: 2019.2
-- Description:
-- Text mode display controller with VGA output
--
-- Font data is written in bytes
-- TODOs:
--  * make RAMs readwrite on port A for better processor integration
--  * increase colour palette output to 24-bit colour
--  * change from palette lookup to full 24-bit colour
--  * true dual port RAMs with independent clocks to allow for different pixelclks
--    and RAM clocks
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- Select which resolution we are targetting
--use work.pkg_vga_params_1920_1080_60hz.all;
--use work.pkg_vga_params_1280_1024_60hz.all;
use work.pkg_vga_params_640_480_60hz.all;

entity display_text_controller is
    port (
        pixelclk  : in std_logic;
        areset_n  : in std_logic;
        vga_hs    : out std_logic;
        vga_vs    : out std_logic;
        vga_blank : out std_logic;
        vga_r     : out std_logic_vector (3 downto 0);
        vga_g     : out std_logic_vector (3 downto 0);
        vga_b     : out std_logic_vector (3 downto 0);

        -- direct RAM access to font RAM (8x16 font, 1 row (byte) per write, 16 addresses per char)
        font_enable_in : in std_logic;
        font_we_in     : in std_logic;
        font_addr_in   : in std_logic_vector(32 - 1 downto 0);
        font_wdata_in  : in std_logic_vector(32 - 1 downto 0);
        -- direct RAM access (6b foreground, 4b background, 8b charcode) 1 Address per char
        text_enable_in : in std_logic;
        text_we_in     : in std_logic;
        text_addr_in   : in std_logic_vector(32 - 1 downto 0);
        text_wdata_in  : in std_logic_vector(32 - 1 downto 0)

    );
end display_text_controller;

architecture rtl of display_text_controller is
    -- font parameters
    constant CHAR_W : integer := 8;
    constant CHAR_H : integer := 16;

    -- display parameters
    constant CHARS_X : integer := END_ACTIVE_X / CHAR_W;
    constant CHARS_Y : integer := END_ACTIVE_Y / CHAR_H;

    -- font RAM parameters
    constant CHARS_IN_FONT : integer := 256; --
    constant FONT_ADDR_W   : integer := 12;  -- todo: parametersise this
    constant FONT_DATA_W   : integer := CHAR_W;
    constant FONT_DEPTH    : integer := CHAR_H * CHARS_IN_FONT;

    -- text RAM parameters
    constant TEXT_ADDR_W : integer := 16; -- todo: parametersise this
    constant TEXT_DATA_W : integer := 18; -- 8 bit charcode, 10 bit colours (6b foreground, 4b background)
    constant TEXT_DEPTH  : integer := CHARS_X * CHARS_Y;
    -- RAM control signals
    signal font_ena   : std_logic;
    signal font_enb   : std_logic;
    signal font_wea   : std_logic;
    signal font_addra : std_logic_vector(FONT_ADDR_W - 1 downto 0);
    signal font_addrb : std_logic_vector(FONT_ADDR_W - 1 downto 0);
    signal font_dia   : std_logic_vector(FONT_DATA_W - 1 downto 0);
    signal font_dob   : std_logic_vector(FONT_DATA_W - 1 downto 0);
    signal text_ena   : std_logic;
    signal text_enb   : std_logic;
    signal text_wea   : std_logic;
    signal text_addra : std_logic_vector(TEXT_ADDR_W - 1 downto 0);
    signal text_addrb : std_logic_vector(TEXT_ADDR_W - 1 downto 0);
    signal text_dia   : std_logic_vector(TEXT_DATA_W - 1 downto 0);
    signal text_dob   : std_logic_vector(TEXT_DATA_W - 1 downto 0);

    signal h_count     : integer;
    signal v_count     : integer;
    signal h_count_d1  : integer;
    signal v_count_d1  : integer;
    signal h_count_d2  : integer;
    signal v_count_d2  : integer;
    signal h_count_d3  : integer;
    signal v_count_d3  : integer;
    signal active_area : std_logic;

    signal char_x       : integer;
    signal char_y       : integer;
    signal char_address : integer;

    -- display signals
    signal font_line             : std_logic_vector(CHAR_W - 1 downto 0);
    signal font_row              : unsigned(FONT_ADDR_W - 1 downto 0); -- needs to be same size to add to charcode_base_address
    signal charcode_to_display   : unsigned(8 - 1 downto 0);           -- up to 255, but need to scale up width to avoid overflow
    signal charcode_base_address : unsigned(FONT_ADDR_W - 1 downto 0);
    signal colour_code           : std_logic_vector(9 downto 0);
    signal fg_colour             : std_logic_vector(11 downto 0);
    signal bg_colour             : std_logic_vector(11 downto 0);
    signal fg_colour_d1          : std_logic_vector(11 downto 0);
    signal bg_colour_d1          : std_logic_vector(11 downto 0);
    signal font_bit              : std_logic;
    signal colour_selected       : std_logic_vector(11 downto 0);
    signal font_bit_select       : unsigned(2 downto 0);

begin

    vga_blank <= not active_area;

    -- Write side for Text and Font Memories - direct RAM access
    font_ena   <= font_enable_in;
    font_wea   <= font_we_in;
    font_addra <= font_addr_in(FONT_ADDR_W - 1 downto 0);
    font_dia   <= font_wdata_in(FONT_DATA_W - 1 downto 0);
    text_ena   <= text_enable_in;
    text_wea   <= text_we_in;
    text_addra <= text_addr_in(TEXT_ADDR_W - 1 downto 0);
    text_dia   <= text_wdata_in(TEXT_DATA_W - 1 downto 0);

    -- We are using a 5 stage pipeline to improve performance and allow us to hit our 108MHz pixelclk
    -- target for 1280x1024

    -------------------------------------------------------------------
    -- Stage 1: Hcount and Vcount counters, CharAddress calculation
    -------------------------------------------------------------------
    sync_counters : process (pixelclk, areset_n)
    begin
        if areset_n = '0' then
            h_count <= 0;
            v_count <= 0;
        else
            -- TODO: we could add an "early reset" to the delayed h/v_count
            --       to bring them back to 0 near the end of the back porch
            --       so we have time to propagate the first char data through
            --       the pipeline
            if rising_edge(pixelclk) then
                -- counters
                if h_count >= END_BPORCH_X then
                    h_count <= 0;
                else
                    h_count <= h_count + 1;
                end if;
                if v_count >= END_BPORCH_Y then
                    v_count <= 0;
                else
                    if h_count >= END_BPORCH_X then
                        v_count <= v_count + 1;
                    end if;
                end if;

            end if;
        end if;
    end process;

    -- Char Address mapping - which char we are in from the mem
    -- this is the first stage in the pipeline so don't use counter delays
    char_x       <= to_integer(shift_right(to_unsigned(h_count, 32), 3)); -- 8 pixels width per char
    char_y       <= to_integer(shift_right(to_unsigned(v_count, 32), 4)); -- 16 pixels width per char
    char_address <= char_y * CHARS_X + char_x;

    -------------------------------------------------------------------
    -- Stage 2: Text RAM
    -------------------------------------------------------------------
    text_addrb <= std_logic_vector(to_unsigned(char_address, 16));
    text_enb   <= '1'; -- TODO: should this be enabled differently?
    -- ram for text mode graphics
    text_ram : entity work.simple_dual_two_clocks
        generic map(
            ADDR_W           => TEXT_ADDR_W,
            DATA_W           => TEXT_DATA_W,
            DEPTH            => TEXT_DEPTH,
            USE_INIT_FILE    => true,
            INIT_FILE_NAME   => "D:/Documents/vivado/microblaze_vga/tools/text_ram.txt",
            INIT_FILE_IS_HEX => false
        )
        port map(
            clka  => pixelclk,
            clkb  => pixelclk,
            ena   => text_ena,
            enb   => text_enb,
            wea   => text_wea,
            addra => text_addra,
            addrb => text_addrb,
            dia   => text_dia,
            dob   => text_dob
        );
    delay_counters_1 : process (pixelclk) is begin
        if rising_edge(pixelclk) then
            h_count_d1 <= h_count;
            v_count_d1 <= v_count;
        end if;
    end process;
    -------------------------------------------------------------------
    -- Stage 3: Font and Colour RAMs
    -------------------------------------------------------------------
    charcode_to_display                <= unsigned(text_dob(7 downto 0));
    charcode_base_address(3 downto 0)  <= x"0";
    charcode_base_address(11 downto 4) <= charcode_to_display; -- charcode*16
    font_enb                           <= '1';                 -- do we need an enable?
    font_row(FONT_ADDR_W - 1 downto 4) <= x"00";
    font_row(3 downto 0)               <= to_unsigned(v_count_d1, 32)(3 downto 0); -- bottom 4 bits of v_count
    font_addrb                         <= std_logic_vector(charcode_base_address + font_row);

    font_ram : entity work.simple_dual_two_clocks
        generic map(
            ADDR_W           => FONT_ADDR_W,
            DATA_W           => FONT_DATA_W,
            DEPTH            => FONT_DEPTH,
            USE_INIT_FILE    => true,
            INIT_FILE_NAME   => "D:/Documents/vivado/microblaze_vga/tools/font_rom.txt",
            INIT_FILE_IS_HEX => false
        )
        port map(
            clka  => pixelclk,
            clkb  => pixelclk,
            ena   => font_ena,
            enb   => font_enb,
            wea   => font_wea,
            addra => font_addra,
            addrb => font_addrb,
            dia   => font_dia,
            dob   => font_dob
        );
    colour_code <= text_dob(17 downto 8);
    colour_ram : entity work.display_colour_ram
        port map(
            clk         => pixelclk,
            colour_code => colour_code,
            fg_colour   => fg_colour,
            bg_colour   => bg_colour
        );
    delay_counters_2 : process (pixelclk) is begin
        if rising_edge(pixelclk) then
            h_count_d2 <= h_count_d1;
            v_count_d2 <= v_count_d1;
        end if;
    end process;
    -------------------------------------------------------------------
    -- Stage 4: Font line bit select
    -------------------------------------------------------------------
    delay_counters_3 : process (pixelclk) is begin
        if rising_edge(pixelclk) then
            fg_colour_d1 <= fg_colour;
            bg_colour_d1 <= bg_colour;
            h_count_d3   <= h_count_d2;
            v_count_d3   <= v_count_d2;
        end if;
    end process;

    font_line <= font_dob;
    -- reverse the font bit selected so hcount=0 means bit=7, 1=>6, 2 => 5 etc
    font_bit_select(2 downto 0) <= unsigned'(b"111") - to_unsigned(h_count_d3, 16)(2 downto 0); -- bottom 3 bits
    font_bit                    <= font_line(to_integer(font_bit_select));

    colour_selected <= fg_colour_d1 when font_bit = '1' else bg_colour_d1;

    -------------------------------------------------------------------
    -- Stage 5: Registered vga_hs, vga_vs and vga_r/g/b
    -------------------------------------------------------------------
    -- VGA Control Signals
    output_reg_proc : process (pixelclk) is begin
        if rising_edge(pixelclk) then
            if (h_count_d3 < END_ACTIVE_X) and (v_count_d3 < END_ACTIVE_Y) then
                active_area <= '1';
                vga_r       <= colour_selected(11 downto 8);
                vga_g       <= colour_selected(7 downto 4);
                vga_b       <= colour_selected(3 downto 0);
            else
                active_area <= '0';
                vga_r       <= x"0";
                vga_g       <= x"0";
                vga_b       <= x"0";
            end if;

            if (h_count_d3 >= END_FPORCH_X) and (h_count_d3 < END_SYNC_X) then
                vga_hs <= ACTIVE_HS;
            else
                vga_hs <= not ACTIVE_HS;
            end if;

            if (v_count_d3 >= END_FPORCH_Y) and (v_count_d3 < END_SYNC_Y) then
                vga_vs <= ACTIVE_VS;
            else
                vga_vs <= not ACTIVE_VS;
            end if;

        end if;
    end process;

end rtl;