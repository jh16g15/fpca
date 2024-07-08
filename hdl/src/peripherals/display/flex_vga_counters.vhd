library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- use work.pkg_vga_params_1280_720_60hz.all;

--! 
entity flex_vga_counters is
    generic (
        TARGET_LATENCY : natural range 1 to 20 := 1; -- number of clocks
        -- Defaults are for 720p
        END_ACTIVE_X   : natural := 1280;
        FRONT_PORCH_X  : natural := 110;
        SYNC_PULSE_X   : natural := 40;
        BACK_PORCH_X   : natural := 220;
               
        END_ACTIVE_Y   : natural := 720;
        FRONT_PORCH_Y  : natural := 5;
        SYNC_PULSE_Y   : natural := 5;
        BACK_PORCH_Y   : natural := 20;    
        
        -- '1' for active high, '0' for active low
        ACTIVE_HS  : std_logic := '1';
        ACTIVE_VS  : std_logic := '1'
    );
    port (
        pixelclk : in std_logic;
        
        -- control signals to display layers. req_pixel triggers load of next pixel data.
        -- TARGET_LATENCY pixelclks after receiving a req_pixel, that data should be displayed to screen
        -- load_line and load_frame can help to trigger DMA from other memory as needed
        req_pixel : out std_logic; -- display next pixel
        load_line : out std_logic;  -- load next line (internal HSYNC)
        load_frame : out std_logic; -- load next frame (internal VSYNC)

        -- delayed by TARGET_LATENCY from internal counters
        VGA_HSYNC : out std_logic;
        VGA_VSYNC : out std_logic;
        VGA_BLANK : out std_logic
        
    );
end entity flex_vga_counters;

architecture rtl of flex_vga_counters is
    constant END_FPORCH_X   : integer := END_ACTIVE_X + FRONT_PORCH_X;
    constant END_SYNC_X     : integer := END_FPORCH_X + SYNC_PULSE_X;
    constant END_BPORCH_X   : integer := END_SYNC_X + BACK_PORCH_X;     -- 1650
    constant END_FPORCH_Y   : integer := END_ACTIVE_Y + FRONT_PORCH_Y;           
    constant END_SYNC_Y     : integer := END_FPORCH_Y + SYNC_PULSE_Y;            
    constant END_BPORCH_Y   : integer := END_SYNC_Y + BACK_PORCH_Y;     -- 750  
    
    -- start just before end of frame to give first frame time to init
    signal h_count     : natural range 0 to END_BPORCH_X := END_ACTIVE_X;
    signal v_count     : natural range 0 to END_BPORCH_Y := END_ACTIVE_Y;

    signal hsync : std_logic_vector(0 to TARGET_LATENCY) := (others => not ACTIVE_HS) ;
    signal vsync : std_logic_vector(0 to TARGET_LATENCY) := (others => not ACTIVE_VS) ;
    signal blank : std_logic_vector(0 to TARGET_LATENCY) := (others => '1') ;

begin

    
    sync_counters : process (pixelclk)
    begin
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
    end process;

    sync_sigs : process (all) is begin
            if (h_count < END_ACTIVE_X) and (v_count < END_ACTIVE_Y) then
                blank(0) <= '0';
            else
                blank(0) <= '1';
            end if;

            if (h_count >= END_FPORCH_X) and (h_count < END_SYNC_X) then
                hsync(0) <= ACTIVE_HS;
            else
                hsync(0) <= not ACTIVE_HS;
            end if;

            if (v_count >= END_FPORCH_Y) and (v_count < END_SYNC_Y) then
                vsync(0) <= ACTIVE_VS;
            else
                vsync(0) <= not ACTIVE_VS;
            end if;

            -- trigger next line load on end of active line
            if h_count = END_ACTIVE_X and v_count < END_ACTIVE_Y then
                load_line <= '1';
            else
                load_line <= '0';
            end if;

            -- trigger next frame load on end of active area
            if h_count = END_ACTIVE_X and v_count = END_ACTIVE_Y then
                load_frame <= '1';
            else
                load_frame <= '0';
            end if;

            
    end process;
    
    --! Shift register to delay output signals to monitor
    add_latency : process (pixelclk)
    begin
        if rising_edge(pixelclk) then
            hsync(1 to hsync'right) <= hsync(0 to hsync'right-1);
            vsync(1 to vsync'right) <= vsync(0 to vsync'right-1);
            blank(1 to blank'right) <= blank(0 to blank'right-1);
        end if;
    end process;

    VGA_HSYNC <= hsync(hsync'right);
    VGA_VSYNC <= vsync(vsync'right);
    VGA_BLANK <= blank(blank'right);

    req_pixel <= not blank(0);

end architecture;