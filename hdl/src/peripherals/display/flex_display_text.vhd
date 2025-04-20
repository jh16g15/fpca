
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.graphics_pkg.all;

--! Fairly Generic text display module
--! contains font and text rams (?) or read-side interfaces to both
--! We need continuous throughput of pixels TARGET_LATENCY after req_pixel is asserted
--! As this is intended to be used in front of a pixel layer, do we need background colours?
entity flex_display_text is
    generic (
        G_PROJECT_ROOT : string := "";
        TARGET_LATENCY : natural range 1 to 20 := 1; -- number of clocks between req_pixel and our output
        G_TEXT_RAM_DEPTH : natural -- can size our text ram here according to our resolution and memory limitations
    );
    port (
        pixelclk   : in std_logic;
        
        -- control registers
        frame_start_char : in std_logic_vector(15 downto 0) := x"0000"; --! text ram location that is the start of a displayed frame, to allow for scrolling/flips if we have sufficient  memory
        line_chars : in  std_logic_vector(15 downto 0); --! How many chars are on a line

        busclk     : in std_logic := '0'; -- Write Port clock for text/font RAMs
        -- direct RAM access to font RAM (8x16 font, 1 row (byte) per write, 16 addresses per char)
        font_enable_in : in std_logic := '0';
        font_we_in     : in std_logic := '0';
        font_addr_in   : in std_logic_vector(32 - 1 downto 0) := (others => '0');
        font_wdata_in  : in std_logic_vector(32 - 1 downto 0) := (others => '0');
        -- direct RAM access to text RAM (6b foreground, 4b background, 8b charcode) 1 Address per char
        text_enable_in : in std_logic := '0';
        text_we_in     : in std_logic := '0';
        text_addr_in   : in std_logic_vector(32 - 1 downto 0) := (others => '0');
        text_wdata_in  : in std_logic_vector(32 - 1 downto 0) := (others => '0');

        -- trigger data fetch
        req_pixel : in std_logic;   --! triggers pixel load, must be output TARGET_LATENCY cycles after we receiver this
        load_line : in std_logic;   --! triggers end of prev line
        load_frame : in std_logic;  --! triggers start of new frame

        -- pixel data out
        pixel_valid : out std_logic;  --! for latency tracking
        red_out : out std_logic_vector(4 downto 0);
        green_out : out std_logic_vector(5 downto 0);
        blue_out : out std_logic_vector(4 downto 0)

    );
end entity flex_display_text;

architecture rtl of flex_display_text is

    -- latency from 
    constant ACTUAL_LATENCY : integer := 3;
    

    constant INIT_TEXT_RAM_FILE : string := G_PROJECT_ROOT & "tools/text_ram.txt";
    constant INIT_FONT_RAM_FILE : string := G_PROJECT_ROOT & "tools/font_rom8x16.txt";
    -- font parameters
    constant CHAR_W : integer := 8;
    constant CHAR_H : integer := 16;
    -- font RAM parameters
    constant CHARS_IN_FONT : integer := 256; --
    constant FONT_ADDR_W   : integer := 12;  -- todo: parametersise this
    constant FONT_DATA_W   : integer := CHAR_W;
    constant FONT_DEPTH    : integer := CHAR_H * CHARS_IN_FONT;

    -- text RAM parameters
    constant TEXT_ADDR_W : integer := 16; -- todo: parametersise this
    constant TEXT_DATA_W : integer := 18; -- 8 bit charcode, 10 bit colours (6b foreground, 4b background)
    

    signal line_start_char_address : unsigned(15 downto 0); -- as we always progress linearly through the text ram, just increment this
    signal char_address : unsigned(15 downto 0); -- as we always progress linearly through the text ram, just increment this
    signal dbg_char_x : unsigned(15 downto 0); 
    signal dbg_char_y : unsigned(15 downto 0); 
    
    signal dbg_pixel_x : unsigned(15 downto 0); 
    signal dbg_pixel_y : unsigned(15 downto 0); 

    signal font_coord_x : unsigned(clog2(CHAR_W)-1 downto 0);
    signal font_coord_y : unsigned(clog2(CHAR_H)-1 downto 0);
    constant MAX_FONT_X : unsigned(clog2(CHAR_W)-1 downto 0) := (others => '1');
    constant MAX_FONT_Y : unsigned(clog2(CHAR_H)-1 downto 0) := (others => '1');
    signal font_coord_x_d1 : unsigned(clog2(CHAR_W)-1 downto 0);
    signal font_coord_y_d1 : unsigned(clog2(CHAR_H)-1 downto 0);
    signal font_coord_x_d2 : unsigned(clog2(CHAR_W)-1 downto 0);

    -- RAM control signals
    signal font_ena   : std_logic;
    signal font_enb   : std_logic;
    signal font_wea   : std_logic;
    signal font_addra : std_logic_vector(FONT_ADDR_W - 1 downto 0) := (others => '0');
    signal font_addrb : std_logic_vector(FONT_ADDR_W - 1 downto 0) := (others => '0');
    signal font_dia   : std_logic_vector(FONT_DATA_W - 1 downto 0);
    signal font_dob   : std_logic_vector(FONT_DATA_W - 1 downto 0);
    signal text_ena   : std_logic;
    signal text_enb   : std_logic;
    signal text_wea   : std_logic;
    signal text_addra : std_logic_vector(TEXT_ADDR_W - 1 downto 0) := (others => '0');
    signal text_addrb : std_logic_vector(TEXT_ADDR_W - 1 downto 0) := (others => '0');
    signal text_dia   : std_logic_vector(TEXT_DATA_W - 1 downto 0);
    signal text_dob   : std_logic_vector(TEXT_DATA_W - 1 downto 0);

    -- pipeline signalling (dbg)
    signal dbg_text_addr_valid : std_logic;
    signal dbg_charcode_valid : std_logic;
    signal dbg_colourcode_valid : std_logic;
    signal dbg_colours_valid : std_logic;
    signal dbg_font_row_valid : std_logic;

    -- font lookup
    signal font_line             : std_logic_vector(CHAR_W - 1 downto 0) := (others => '0'); -- line buffer
    
    signal charcode_to_display   : unsigned(8 - 1 downto 0) := (others => '0');           -- up to 255, but need to scale up width to avoid overflow
    signal charcode_base_address : unsigned(FONT_ADDR_W - 1 downto 0) := (others => '0');
    signal colour_code           : std_logic_vector(9 downto 0) := (others => '0');
    signal fg_colour             : std_logic_vector(11 downto 0) := (others => '0');
    signal bg_colour             : std_logic_vector(11 downto 0) := (others => '0');
    signal font_bit              : std_logic;
    signal colour_selected       : std_logic_vector(11 downto 0) := (others => '0');
    signal font_bit_select       : unsigned(2 downto 0) := (others => '0');

    type t_colour_arr is array(natural range <>) of std_logic_vector(11 downto 0);
    constant LATENCY_TO_ADD : natural := TARGET_LATENCY-ACTUAL_LATENCY;
    signal colour_pipe : t_colour_arr(0 to LATENCY_TO_ADD);
    signal colour_pipe_valid : std_logic_vector(0 to LATENCY_TO_ADD);

    signal aligned_colour : std_logic_vector(11 downto 0) := (others => '0');
    signal aligned_colour_valid : std_logic;

begin
    -- Write side for Text and Font Memories - direct RAM access
    font_ena   <= font_enable_in;
    font_wea   <= font_we_in;
    font_addra <= font_addr_in(FONT_ADDR_W - 1 downto 0);
    font_dia   <= font_wdata_in(FONT_DATA_W - 1 downto 0);
    text_ena   <= text_enable_in;
    text_wea   <= text_we_in;
    text_addra <= text_addr_in(TEXT_ADDR_W - 1 downto 0);
    text_dia   <= text_wdata_in(TEXT_DATA_W - 1 downto 0);

    -- address counters
    counter_proc : process (pixelclk) is
    begin
        if rising_edge(pixelclk) then
            if load_frame then -- Start prep for next frame
                char_address <= unsigned(frame_start_char);
                line_start_char_address <= (others => '0');
                font_coord_x <= (others => '0');
                font_coord_y <= (others => '0');
            end if;

            if req_pixel then -- increment X
                font_coord_x <= font_coord_x + 1; -- will wrap round
                if font_coord_x = MAX_FONT_X then
                    char_address <= char_address + 1;
                end if;
            end if;

            if load_line then -- increment Y
                font_coord_y <= font_coord_y + 1; -- will wrap round
                char_address <= line_start_char_address;
                if font_coord_y = MAX_FONT_Y then
                    line_start_char_address <= line_start_char_address + unsigned(line_chars);
                end if;
            end if;
        end if;
    end process counter_proc;
    
    -- as we already have the first char_addr etc loaded before the start of the line request, we are effectively 0-latency here 
    dbg_text_addr_valid <= req_pixel;

    ------ FIRST CYCLE OF LATENCY - fetch Text RAM contents to find what char we are on -----------
    process (pixelclk) is
    begin
        if rising_edge(pixelclk) then
            dbg_charcode_valid <= dbg_text_addr_valid;
            dbg_colourcode_valid <= dbg_text_addr_valid;
            font_coord_x_d1 <= font_coord_x;
            font_coord_y_d1 <= font_coord_y;
        end if;
    end process;
    

    text_addrb <= std_logic_vector(char_address);
    text_enb   <= dbg_text_addr_valid;
    -- ram for text mode graphics
    text_ram : entity work.simple_dual_two_clocks
        generic map(
            ADDR_W           => TEXT_ADDR_W,
            DATA_W           => TEXT_DATA_W,
            DEPTH            => G_TEXT_RAM_DEPTH,
            USE_INIT_FILE    => true,
            INIT_FILE_NAME   => INIT_TEXT_RAM_FILE,
            INIT_FILE_IS_HEX => false
        )
        port map(
            clka  => busclk,
            clkb  => pixelclk,
            ena   => text_ena,
            enb   => text_enb,
            wea   => text_wea,
            addra => text_addra,
            addrb => text_addrb,
            dia   => text_dia,
            dob   => text_dob
        );

    charcode_to_display                <= unsigned(text_dob(7 downto 0));
    charcode_base_address(3 downto 0)  <= x"0";
    charcode_base_address(11 downto 4) <= charcode_to_display; -- charcode*16

    colour_code <= text_dob(17 downto 8);
    ------ SECOND CYCLE OF LATENCY - fetch corresponding row of Font RAM, and corresponding FG/BG colours -----------
    process (pixelclk) is
    begin
        if rising_edge(pixelclk) then
            dbg_font_row_valid <= dbg_charcode_valid;
            dbg_colours_valid <= dbg_colourcode_valid;
            font_coord_x_d2 <= font_coord_x_d1; -- we need this to select which pixel in our font row
        end if;
    end process;
    
    font_enb                           <= dbg_charcode_valid;  -- do we need an enable?
    font_addrb                         <= std_logic_vector(charcode_base_address + font_coord_y_d1);

    font_ram : entity work.simple_dual_two_clocks
        generic map(
            ADDR_W           => FONT_ADDR_W,
            DATA_W           => FONT_DATA_W,
            DEPTH            => FONT_DEPTH,
            USE_INIT_FILE    => true,
            INIT_FILE_NAME   => INIT_FONT_RAM_FILE,
            INIT_FILE_IS_HEX => false
        )
        port map(
            clka  => busclk,
            clkb  => pixelclk,
            ena   => font_ena,
            enb   => font_enb,
            wea   => font_wea,
            addra => font_addra,
            addrb => font_addrb,
            dia   => font_dia,
            dob   => font_dob
        );
    
    colour_ram : entity work.display_colour_ram
        port map(
            clk         => pixelclk,
            colour_code => colour_code,
            fg_colour   => fg_colour,
            bg_colour   => bg_colour
        );

        font_line <= font_dob;
        -- reverse the font bit selected so x=0 means bit=7, 1=>6, 2 => 5 etc
        font_bit_select(2 downto 0) <= unsigned'(b"111") - font_coord_x_d2; -- bottom 3 bits
        font_bit                    <= font_line(to_integer(font_bit_select));
        colour_selected <= fg_colour when font_bit = '1' else bg_colour;
        

        -- before we expand the colours, add extra delay from ACTUAL LATENCY TO TARGET LATENCY so we can sync up with other display layers
        colour_pipe(0) <= colour_selected;
        colour_pipe_valid(0) <= dbg_colours_valid;
        gen_extra_latency : if LATENCY_TO_ADD > 0 generate
            add_extra_latency : process(pixelclk) is
            begin
                if rising_edge(pixelclk) then
                    colour_pipe(1 to colour_pipe'high) <= colour_pipe(0 to colour_pipe'high-1);
                    colour_pipe_valid(1 to colour_pipe_valid'high) <= colour_pipe_valid(0 to colour_pipe_valid'high-1);
                end if;
            end process;
        end generate gen_extra_latency;
        aligned_colour <= colour_pipe(colour_pipe'high);
        aligned_colour_valid <= colour_pipe_valid(colour_pipe_valid'high);

        ------- THIRD cycle of latency that is counted as part of ACTUAL_LATENCY
        pad_output_color : process (pixelclk) is
        begin
            if rising_edge(pixelclk) then
                pixel_valid <= aligned_colour_valid;
                -- extend from 12-bit to 16-bit colour by repeating MSB
                red_out <= aligned_colour(11 downto 8) & aligned_colour(11);
                green_out <= aligned_colour( 7 downto 4) & aligned_colour(7) & aligned_colour(7);
                blue_out <= aligned_colour( 3 downto 0) & aligned_colour(3);
            end if;
        end process;

        


end architecture;