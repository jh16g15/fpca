----------------------------------------------------------------------------------
-- Joseph Hindmarsh September 2022
--
-- Wishbone wrapper for text display controller (640x480 VGA/HDMI)
-- Address Map:
--  The internal address space is split into 2 16-bit address spaces
--  (internally, all is word addressed)
--  x"XXX0_YYYY" goes to the text RAM
--  x"XXX1_YYYY" goes to the font RAM
--
-- TODOs:
--  * check that wishbone addressing matches the BRAM word addressing
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wb_pkg.all;

entity wb_display_text_controller is
    generic(
        G_PROJECT_ROOT : string := ""
    );
    port (
        pixelclk  : in std_logic;
        areset_n  : in std_logic;
        vga_hs    : out std_logic;
        vga_vs    : out std_logic;
        vga_blank : out std_logic;
        vga_r     : out std_logic_vector (3 downto 0);
        vga_g     : out std_logic_vector (3 downto 0);
        vga_b     : out std_logic_vector (3 downto 0);

        -- Wishbone to framebuffer (must be synced to pixelclk)
        text_display_wb_mosi_in  : in t_wb_mosi;
        text_display_wb_miso_out : out t_wb_miso
    );
end entity wb_display_text_controller;

architecture rtl of wb_display_text_controller is
    signal reset : std_logic;

    signal mem_enable : std_logic;
    signal mem_we     : std_logic;
    signal mem_addr   : std_logic_vector(31 downto 0);
    signal mem_wdata  : std_logic_vector(31 downto 0);
    signal mem_rdata  : std_logic_vector(31 downto 0);

    signal font_enable      : std_logic;
    signal text_enable      : std_logic;
    signal addr_decode_font : std_logic;
    signal addr_decode_text : std_logic;

begin
    reset <= not areset_n;

    wb_mem_shim_inst : entity work.wb_mem_shim
        port map(
            wb_clk         => pixelclk,
            wb_reset       => reset,
            wb_mosi_in     => text_display_wb_mosi_in,
            wb_miso_out    => text_display_wb_miso_out,
            mem_enable_out => mem_enable,
            mem_we_out     => mem_we,
            mem_addr_out   => mem_addr,
            mem_wdata_out  => mem_wdata,
            mem_rdata_in   => mem_rdata
        );

    -- The internal address space is split into 2 16-bit address spaces
    -- (internally, all is word addressed)
    -- x"XXX0_YYYY" goes to the text RAM
    -- x"XXX1_YYYY" goes to the font RAM

    addr_decode_font <= '1' when mem_addr(16) = '1' else '0';
    addr_decode_text <= '1' when mem_addr(16) = '0' else '0';

    font_enable <= mem_enable and addr_decode_font;
    text_enable <= mem_enable and addr_decode_text;

    display_text_controller_inst : entity work.display_text_controller
        generic map(
            G_PROJECT_ROOT => G_PROJECT_ROOT
        )
        port map(
            pixelclk       => pixelclk,
            areset_n       => areset_n,
            vga_hs         => vga_hs,
            vga_vs         => vga_vs,
            vga_blank      => vga_blank,
            vga_r          => vga_r,
            vga_g          => vga_g,
            vga_b          => vga_b,
            font_enable_in => font_enable,
            font_we_in     => mem_we,
            font_addr_in   => b"00" & mem_addr(31 downto 2),    -- convert byte to word address
            font_wdata_in  => mem_wdata,
            text_enable_in => text_enable,
            text_we_in     => mem_we,
            text_addr_in   => b"00" & mem_addr(31 downto 2),    -- convert byte to word address
            text_wdata_in  => mem_wdata
        );
end architecture;