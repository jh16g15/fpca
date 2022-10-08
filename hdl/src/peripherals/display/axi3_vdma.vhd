library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.axi_pkg.all;
use work.graphics_pkg.all;

-- For a pixel based display.
-- Reads  out a framebuffer from an AXI3 connected memory (ideally Zynq DDR3)
--
-- Generics:
-- VGA resolution parameters
--
-- Inputs:
-- framebuffer start address (to support multiple buffering)
-- enable?
--
-- Outputs:
-- VGA RGB and sync signals
--
-- 32 bits per pixel
-- Note: uses Xilinx XPMs for CDC

entity axi3_vdma is
    generic (
        -- display parameters (default 640*480)
        G_END_ACTIVE_X  : integer := 640;
        G_FRONT_PORCH_X : integer := 16;
        G_SYNC_PULSE_X  : integer := 96;
        G_BACK_PORCH_X  : integer := 48;

        G_END_ACTIVE_Y  : integer   := 480;
        G_FRONT_PORCH_Y : integer   := 10;
        G_SYNC_PULSE_Y  : integer   := 2;
        G_BACK_PORCH_Y  : integer   := 33;
        G_ACTIVE_HS     : std_logic := '0';
        G_ACTIVE_VS     : std_logic := '0';

        -- framebuffer parameters (default 640x480)
        -- needs to be power of 2 larger than G_END_ACTIVE_X so we can avoid multiplication for address calculation.
        -- This uses about 2MB per frame for 640x480 @32bpp, which gives us loads of room in the Zynq DDR3
        G_FRAMEBUFFER_LINE_LEN : integer := 1024; --!

        G_PIXEL_FIFO_DEPTH : integer := 512 --! Experiment to see how big this needs to be
    );
    port (
        dma_clk_in  : in std_logic; -- AXI_S_HP clock: 150MHz (up to 250MHz?)
        pixelclk_in : in std_logic; -- depends on video resolution, 25MHz for 640x480

        pixelclk_reset_in : in std_logic;
        dma_reset_in      : in std_logic;

        -- connect to Zynq HP AXI3 ports for DDR3 access
        dma_axi_hp_mosi_out : out t_axi_mosi;
        dma_axi_hp_miso_in  : in t_axi_miso;

        -- to VGA/DVI out
        vga_pixel_out : out t_pixel;
        vga_hsync_out : out std_logic;
        vga_vsync_out : out std_logic;
        vga_blank_out : out std_logic;

        -- double buffering
        buffer0_start : in std_logic_vector(31 downto 0);
        buffer1_start : in std_logic_vector(31 downto 0);

        -- status and control
        next_frame_in             : in std_logic;                      --! From CPU/GPU logic - choose which buffer to use next
        start_of_frame            : out std_logic;                     --! to clear next_frame_ready/CPU interrupt
        pixel_underflow_count_out : out std_logic_vector(31 downto 0); --! count of when our DMA is too slow/not enough buffering
        frame_skip_count_out      : out std_logic_vector(31 downto 0)  --! count of when we have to display an old frame as the new one isn't ready yet

    );
end entity axi3_vdma;

architecture rtl of axi3_vdma is
    constant G_END_FPORCH_X : integer := G_END_ACTIVE_X + G_FRONT_PORCH_X;
    constant G_END_SYNC_X   : integer := G_END_FPORCH_X + G_SYNC_PULSE_X;
    constant G_END_BPORCH_X : integer := G_END_SYNC_X + G_BACK_PORCH_X; -- 800

    constant G_END_FPORCH_Y : integer := G_END_ACTIVE_Y + G_FRONT_PORCH_Y;
    constant G_END_SYNC_Y   : integer := G_END_FPORCH_Y + G_SYNC_PULSE_Y;
    constant G_END_BPORCH_Y : integer := G_END_SYNC_Y + G_BACK_PORCH_Y; -- 525

    signal h_count : integer range 0 to G_END_BPORCH_X;
    signal v_count : integer range 0 to G_END_BPORCH_Y;

    signal data_enable           : std_logic;
    signal dma_start_in          : std_logic;
    signal dma_done_out          : std_logic;
    signal dma_start_addr_in     : std_logic_vector(31 downto 0);
    signal dma_axi_burst_mode_in : std_logic_vector(1 downto 0);
    signal dma_num_words_in      : std_logic_vector(31 downto 0);
    signal dma_queue_limit_in    : std_logic_vector(31 downto 0);
    signal dma_stall_in          : std_logic;

    signal dma_axi_stream_mosi   : t_axi_stream32_mosi;
    signal dma_axi_stream_miso   : t_axi_stream32_miso;
    signal pixel_axi_stream_mosi : t_axi_stream32_mosi;
    signal pixel_axi_stream_miso : t_axi_stream32_miso;
    type t_state is (IDLE, NEW_FRAME, NEW_LINE, STALL, WAIT_FOR_FLUSH);

    signal state : t_state := WAIT_FOR_FLUSH;

    signal pixel_fifo_prog_full         : std_logic;
    signal pixel_fifo_has_space         : std_logic;
    signal pixel_fifo_has_space_dma_clk : std_logic;
    signal pixel_fifo_empty             : std_logic;
    signal pixel_fifo_empty_dma_clk     : std_logic; -- cdc so we know when the flush is completed
    -- status reporting
    signal pixel_underflow_count : integer;
    signal frame_skip_count      : integer;

begin

    -----------------------------------------------------------------
    -- 1. Pixel Counters
    -----------------------------------------------------------------
    -- the point of these counters is to schedule the DMA operations to keep the FIFOs topped off.
    -- and also to generate the HSYNC, VSYNC and BLANK signals

    vga_blank_out <= not data_enable;

    -- NOTE: these control signals are registered, so are asserted one cycle after the counter reaches that value
    sync_counters : process (pixelclk_in)
    begin
        if rising_edge(pixelclk_in) then
            if pixelclk_reset_in = '1' then
                -- reset to the end of the active area to give DMA time to fill the FIFO
                h_count     <= G_END_ACTIVE_X;
                v_count     <= G_END_ACTIVE_Y;
                data_enable <= '0';
            else
                -- counters
                h_count <= 0 when h_count >= G_END_BPORCH_X else h_count + 1;
                v_count <= 0 when v_count >= G_END_BPORCH_Y else v_count + 1;

                --blanking signal
                data_enable <= '1' when ((h_count < G_END_ACTIVE_X) and (h_count < G_END_ACTIVE_X)) else '0';

                --sync signals
                vga_hsync_out <= G_ACTIVE_HS when ((h_count >= G_END_FPORCH_X) and (h_count < G_END_SYNC_X)) else not G_ACTIVE_HS;
                vga_vsync_out <= G_ACTIVE_VS when ((v_count >= G_END_FPORCH_Y) and (v_count < G_END_SYNC_Y)) else not G_ACTIVE_VS;

            end if;
        end if;
    end process;

    -----------------------------------------------------------------
    -- 2. AXI3 DMA master and control
    -----------------------------------------------------------------
    -- 32b pixel data
    dma_axi3_read_inst : entity work.dma_axi3_read
        port map(
            axi_clk               => dma_clk_in,
            axi_reset             => dma_reset_in,
            dma_start_in          => dma_start_in,
            dma_start_addr_in     => dma_start_addr_in,
            dma_axi_burst_mode_in => AXI_BURST_INCR,
            dma_num_words_in      => dma_num_words_in,
            dma_queue_limit_in    => uint2slv(4),
            dma_stall_in          => dma_stall_in,
            dma_done_out          => dma_done_out,
            dma_axi_hp_mosi_out   => dma_axi_hp_mosi_out,
            dma_axi_hp_miso_in    => dma_axi_hp_miso_in,
            axi_stream_mosi_out   => dma_axi_stream_mosi,
            axi_stream_miso_in    => dma_axi_stream_miso
        );

    dma_ctrl_proc : process (dma_clk_in)
    begin
        if rising_edge(dma_clk_in) then
            if dma_reset_in = '1' then
                state <= WAIT_FOR_FLUSH;
            else
                -- type t_state is (IDLE, NEW_FRAME, NEW_LINE, STALL, WAIT_FOR_FLUSH);

                -- state machine description:
                When we reset (or have an error), start flushing the pixel FIFO and don't start any more DMA
                After the pixel FIFO is empty, wait for the end of the current frame, then start a new frame as normal



                case state is
                    when IDLE           =>
                    when NEW_FRAME      =>
                    when NEW_LINE       =>
                    when STALL          =>
                    when WAIT_FOR_FLUSH =>
                    when others         =>
                        null;
                end case;
            end if;
        end if;
    end process;
    -----------------------------------------------------------------
    -- 3. Read Data CDC FIFO and pixel readout
    -----------------------------------------------------------------
    -- we will use the prog_full flag to stall the DMA transfer until we have room for another burst
    pixel_fifo_has_space <= not pixel_fifo_prog_full;
    pixel_fifo_empty     <= not pixel_axi_stream_mosi.tvalid;

    -- CDC back to the dma_clk domain
    xpm_cdc_to_dma_clk_inst : xpm_cdc_array_single
    generic map(DEST_SYNC_FF => 2, WIDTH => 2)
    port map(
        dest_out => (pixel_fifo_empty_dma_clk, pixel_fifo_has_space_dma_clk),
        dest_clk => dma_clk_in,
        src_clk  => pixelclk_in,
        src_in   => (pixel_fifo_empty, pixel_fifo_has_space)
    );

    -- CDC into the pixelclk domain
    axi_stream_xpm_fifo_wrapper_inst : entity work.axi_stream_xpm_fifo_wrapper
        generic map(
            G_DUAL_CLOCK       => true,
            G_RELATED_CLOCKS   => true,
            G_FIFO_DEPTH       => 512, -- experiment to find how small a FIFO we can get away with
            G_DATA_WIDTH       => 32,
            G_FULL_PACKET      => false,
            G_PROG_FULL_THRESH => G_PIXEL_FIFO_DEPTH - 16
        )
        port map(
            input_clk                  => dma_clk_in,
            output_clk                 => pixelclk_in,
            input_clk_reset            => dma_reset_in,
            input_axi_stream_mosi_in   => dma_axi_stream_mosi,
            input_axi_stream_miso_out  => dma_axi_stream_miso,
            output_axi_stream_mosi_out => pixel_axi_stream_mosi,
            output_axi_stream_miso_in  => pixel_axi_stream_miso,
            prog_full                  => pixel_fifo_prog_full
        );

    --! Note: everything here is registered
    pixel_out_proc : process (pixelclk_in)
    begin
        if rising_edge(pixelclk_in) then
            if pixelclk_reset_in = '1' then
                pixel_underflow_count <= 0;
            else
                -- if no new pixel is available, increase underflow count

                -- while in the active display area
                if ((h_count < G_END_ACTIVE_X) and (h_count < G_END_ACTIVE_X)) then
                    -- ACK current pixel from FIFO
                    pixel_axi_stream_miso.tready <= '1';

                    if pixel_axi_stream_mosi.tvalid = '1' then
                        vga_pixel_out.red   <= pixel_axi_stream_mosi.tdata(23 downto 16);
                        vga_pixel_out.green <= pixel_axi_stream_mosi.tdata(15 downto 8);
                        vga_pixel_out.blue  <= pixel_axi_stream_mosi.tdata(7 downto 0);
                    else -- if no pixel preset
                        pixel_underflow_count <= pixel_underflow_count + 1;
                        -- underflow colour is "deep pink" for debug
                        vga_pixel_out.red   <= x"E6";
                        vga_pixel_out.green <= x"00";
                        vga_pixel_out.blue  <= x"7E";

                    end if;

                else -- hold FIFO output and output black until we have finished the blanking period
                    pixel_axi_stream_miso.tready <= '0';
                    vga_pixel_out.red            <= x"00";
                    vga_pixel_out.green          <= x"00";
                    vga_pixel_out.blue           <= x"00";
                end if;
            end if;
        end if;
    end process;

end architecture;