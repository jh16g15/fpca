library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pkg_lcd_params_480_272_60hz.all;

entity lcd_counters is
    generic (
        -- How many clocks the display logic takes to get the colour data from the pixel XY coordinates -
        -- tells us how many cycles to delay the LCD_HSYNC/LCD_VSYNC/LCD_DATA_EN signals by to sync up
        -- 0 for combinational
        G_PIXEL_DATA_LATENCY : integer := 0
    );
    port (
        pixelclk   : in std_logic;
        reset : in std_logic;

        -- LCD Control Signals
        LCD_HSYNC : out std_logic;
        LCD_VSYNC : out std_logic;
        LCD_DATA_EN : out std_logic;

        -- Display Code signals
        x_count_out : out integer;
        y_count_out : out integer;

        -- 16 bit RGB in (calc from x_count, y_count)
        red_in : in std_logic_vector(4 downto 0);
        green_in : in std_logic_vector(5 downto 0);
        blue_in : in std_logic_vector(4 downto 0);

        -- 16 bit RGB out
        LCD_R_out : out std_logic_vector(4 downto 0);
        LCD_G_out : out std_logic_vector(5 downto 0);
        LCD_B_out : out std_logic_vector(4 downto 0)

    );
end entity lcd_counters;

architecture rtl of lcd_counters is
    signal h_count  : integer;
    signal v_count  : integer;

    signal active_area : std_logic;

    signal hsync_i : std_logic;
    signal vsync_i : std_logic;
    signal data_en_i : std_logic;

    signal dly_hsync : std_logic_vector(G_PIXEL_DATA_LATENCY downto 0);
    signal dly_vsync : std_logic_vector(G_PIXEL_DATA_LATENCY downto 0);
    signal dly_data_en : std_logic_vector(G_PIXEL_DATA_LATENCY downto 0);
begin

    -- original
    no_pipe : if G_PIXEL_DATA_LATENCY = 0 generate
        LCD_HSYNC <= hsync_i;
        LCD_VSYNC <= vsync_i;
        LCD_DATA_EN <= data_en_i;
    end generate;

    -- delay pipeline shift register to sync the control signals to the fetched pixel data
    -- TODO: do we also need to change where we mask off the input data to 0s, to account for these delays?
    -- output from the end of the pipeline
    dly_gen : if G_PIXEL_DATA_LATENCY > 0 generate
        LCD_HSYNC <= dly_hsync(dly_hsync'left);
        LCD_VSYNC <= dly_vsync(dly_vsync'left);
        LCD_DATA_EN <= dly_data_en(dly_data_en'left);
        dly_proc : process(pixelclk, reset)
        begin
            if rising_edge(pixelclk) then
                dly_hsync <= dly_hsync(dly_hsync'left-1 downto 0) & hsync_i;
                dly_vsync <= dly_vsync(dly_vsync'left-1 downto 0) & vsync_i;
                dly_data_en <= dly_data_en(dly_data_en'left-1 downto 0) & data_en_i;
            end if;
        end process;

    end generate;

    x_count_out <= h_count;
    y_count_out <= v_count;

    data_en_i <= active_area;

    sync_counters : process(pixelclk, reset)
    begin
    if reset = '1' then
        h_count <= 0;
        v_count <= 0;
    else
        -- TODO: we could add an "early reset" to the delayed h/v_count
        --       to bring them back to 0 near the end of the back porch
        --       so we have time to propagate the first char data through
        --       the pipeline
        if rising_edge(pixelclk) then
            -- counters
            if h_count >=  END_BPORCH_X then
                h_count <= 0;
            else
                h_count <= h_count + 1;
            end if;
            if v_count >= END_BPORCH_Y then
                v_count <= 0;
            else
                if h_count >=  END_BPORCH_X then
                    v_count <= v_count + 1;
                end if;
            end if;

        end if;
    end if;
    end process;

    output_reg_proc : process(pixelclk) is begin
        if rising_edge(pixelclk) then
            if (h_count < END_ACTIVE_X) and (v_count < END_ACTIVE_Y) then
                active_area <= '1';
                LCD_R_out <= red_in;
                LCD_G_out <= green_in;
                LCD_B_out <= blue_in;
            else
                active_area <= '0';
                LCD_R_out <= (others => '0');
                LCD_G_out <= (others => '0');
                LCD_B_out <= (others => '0');
            end if;

            if (h_count >= END_FPORCH_X) and (h_count < END_SYNC_X) then
                hsync_i <= ACTIVE_HS;
            else
                hsync_i <= not ACTIVE_HS;
            end if;

            if (v_count >= END_FPORCH_Y) and (v_count < END_SYNC_Y) then
                vsync_i <= ACTIVE_VS;
            else
                vsync_i <= not ACTIVE_VS;
            end if;

        end if;
    end process;

end architecture;



