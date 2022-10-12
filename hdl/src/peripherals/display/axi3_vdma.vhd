library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.axi_pkg.all;
use work.graphics_pkg.all;

library xpm;
use xpm.vcomponents.all;

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
        buffer0_start_in : in std_logic_vector(31 downto 0);
        buffer1_start_in : in std_logic_vector(31 downto 0);

        -- status and control
        -- frame_skip_count_out      : out std_logic_vector(31 downto 0);  --! count of when we have to display an old frame as the new one isn't ready yet
        pixel_underflow_count_dma_clk_out : out std_logic_vector(31 downto 0); --! (dma_clk) count of when our DMA is too slow/not enough buffering
        start_of_frame_dma_clk_out        : out std_logic;                     --! (dma_clk) to clear next_frame_ready/CPU interrupt
        buffer_sel_dma_clk_in             : in std_logic                       --! (dma_clk) From CPU/GPU logic - choose which buffer to use next

    );
end entity axi3_vdma;

architecture rtl of axi3_vdma is
    constant G_END_FPORCH_X : integer := G_END_ACTIVE_X + G_FRONT_PORCH_X;
    constant G_END_SYNC_X   : integer := G_END_FPORCH_X + G_SYNC_PULSE_X;
    constant G_END_BPORCH_X : integer := G_END_SYNC_X + G_BACK_PORCH_X; -- 800

    constant G_END_FPORCH_Y : integer := G_END_ACTIVE_Y + G_FRONT_PORCH_Y;
    constant G_END_SYNC_Y   : integer := G_END_FPORCH_Y + G_SYNC_PULSE_Y;
    constant G_END_BPORCH_Y : integer := G_END_SYNC_Y + G_BACK_PORCH_Y; -- 525

    signal h_count : integer range 0 to G_END_BPORCH_X := G_END_ACTIVE_X;
    signal v_count : integer range 0 to G_END_BPORCH_Y := G_END_ACTIVE_Y;

    signal data_enable        : std_logic;
    signal dma_start          : std_logic;
    signal dma_done           : std_logic;
    signal dma_start_addr     : std_logic_vector(31 downto 0);
    signal dma_axi_burst_mode : std_logic_vector(1 downto 0);
    signal dma_num_words      : std_logic_vector(31 downto 0);
    signal dma_queue_limit    : std_logic_vector(31 downto 0);
    signal dma_stall          : std_logic;

    signal dma_axi_stream_mosi   : t_axi_stream32_mosi;
    signal dma_axi_stream_miso   : t_axi_stream32_miso;
    signal pixel_axi_stream_mosi : t_axi_stream32_mosi;
    signal pixel_axi_stream_miso : t_axi_stream32_miso;
    type t_state is (WAIT_FOR_FLUSH, WAIT_FOR_VSYNC, LINE_DMA_START, LINE_DMA_WAIT);
    signal state : t_state := WAIT_FOR_FLUSH;
    -- framebuffer parameters (default 640x480)
    -- needs to be power of 2 larger than G_END_ACTIVE_X so we can avoid multiplication for address calculation.
    -- This uses about 2MB per frame for 640x480 @32bpp, which gives us loads of room in the Zynq DDR3
    constant LINE_ADDR_SHIFT_AMOUNT : integer := clog2(G_END_ACTIVE_X) + 2;

    -- for example, consider a line 640 pixels wide. We need clog2(640) = 10 bits to store this
    -- so the line offset becomes Y << (10 + 2)
    -- So line 0 has an offset of 0
    -- line 1 has an word offset of 1024 (byte 4096)

    signal dma_line_count               : unsigned(31 downto 0);
    signal dma_frame_addr_offset        : unsigned(31 downto 0);
    signal vga_vsync                    : std_logic;
    signal vga_vsync_dma_clk            : std_logic;
    signal pixel_fifo_prog_full         : std_logic;
    signal pixel_fifo_prog_full_dma_clk : std_logic;
    signal pixel_fifo_empty             : std_logic;
    signal pixel_fifo_empty_dma_clk     : std_logic; -- cdc so we know when the flush is completed
    -- status reporting
    signal pixel_underflow_count : unsigned(31 downto 0) := (others => '0');
    signal frame_skip_count      : unsigned(31 downto 0) := (others => '0');

    -- splitting up after CDC in an array (XPM)
    signal cdc_to_dma_clk_arr : std_logic_vector(31 downto 0) := (others => '0');

begin

    -----------------------------------------------------------------
    -- 1. Pixel Counters
    -----------------------------------------------------------------
    -- the point of these counters is to schedule the DMA operations to keep the FIFOs topped off.
    -- and also to generate the HSYNC, VSYNC and BLANK signals

    vga_blank_out <= not data_enable;
    vga_vsync_out <= vga_vsync;

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
                -- h_count <= 0 when h_count >= G_END_BPORCH_X else h_count + 1;

                if h_count >= G_END_BPORCH_X then
                    h_count <= 0;
                    v_count <= 0 when v_count >= G_END_BPORCH_Y else v_count + 1;
                else
                    h_count <= h_count + 1;
                end if;

                --blanking signal
                data_enable <= '1' when ((h_count < G_END_ACTIVE_X) and (h_count < G_END_ACTIVE_X)) else '0';

                --sync signals
                vga_hsync_out <= G_ACTIVE_HS when ((h_count >= G_END_FPORCH_X) and (h_count < G_END_SYNC_X)) else not G_ACTIVE_HS;
                vga_vsync     <= G_ACTIVE_VS when ((v_count >= G_END_FPORCH_Y) and (v_count < G_END_SYNC_Y)) else not G_ACTIVE_VS;

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
            dma_start_in          => dma_start,
            dma_start_addr_in     => dma_start_addr,
            dma_axi_burst_mode_in => AXI_BURST_INCR,
            dma_num_words_in      => dma_num_words,
            dma_queue_limit_in    => uint2slv(4),
            dma_stall_in          => dma_stall,
            dma_done_out          => dma_done,
            dma_axi_hp_mosi_out   => dma_axi_hp_mosi_out,
            dma_axi_hp_miso_in    => dma_axi_hp_miso_in,
            axi_stream_mosi_out   => dma_axi_stream_mosi,
            axi_stream_miso_in    => dma_axi_stream_miso
        );

    dma_ctrl_proc : process (dma_clk_in)
        variable v_dma_line_addr_offset : unsigned(31 downto 0);
    begin
        if rising_edge(dma_clk_in) then
            if dma_reset_in = '1' then
                state <= WAIT_FOR_FLUSH;
            else
                -- state machine description:
                -- When we reset (or have an error), start flushing the pixel FIFO and don't start any more DMA
                -- After the pixel FIFO is empty, wait for the end of the current frame, then start a new frame as normal

                -- start the DMA for the next frame when our VSYNC is asserted (this should give us enough time, as that will be
                -- multiple lines before the active area)

                -- as individual lines are not contiguously in memory, do one DMA transfer per line. We don't need to wait for a HSYNC each time though

                --defaults:
                start_of_frame_dma_clk_out <= '0';
                case state is
                    when WAIT_FOR_FLUSH =>
                        ------------------------------------------------------
                        -- don't start any more DMA transfers until the pixel
                        -- FIFO is empty to resync the data
                        ------------------------------------------------------
                        dma_start <= '0';
                        if dma_done = '1' and pixel_fifo_empty_dma_clk = '1' then
                            state <= WAIT_FOR_VSYNC;
                        end if;

                    when WAIT_FOR_VSYNC =>
                        ----------------------------------------------------------------
                        -- when we get a VSYNC, we can then get ready for the next frame
                        ----------------------------------------------------------------
                        if vga_vsync_dma_clk = '1' then
                            start_of_frame_dma_clk_out <= '1';
                            dma_line_count             <= (others => '0');
                            dma_frame_addr_offset      <= unsigned(buffer1_start_in) when buffer_sel_dma_clk_in = '1' else unsigned(buffer0_start_in);
                            state                      <= LINE_DMA_START;
                        end if;

                    when LINE_DMA_START =>
                        --------------------------------------------------------
                        -- Start a DMA
                        --------------------------------------------------------
                        dma_start <= '1';
                        v_dma_line_addr_offset := shift_left(dma_line_count, LINE_ADDR_SHIFT_AMOUNT);
                        dma_start_addr <= std_logic_vector(dma_frame_addr_offset + v_dma_line_addr_offset);
                        dma_num_words  <= uint2slv(G_END_ACTIVE_X); -- number of horizontal pixels
                        state          <= LINE_DMA_START;

                    when LINE_DMA_WAIT =>
                        --------------------------------------------------------
                        -- Wait for the line buffer transfer to complete
                        -- (can be stalled by pixel_fifo_prog_full)
                        --------------------------------------------------------
                        dma_start <= '0';
                        if dma_done = '1' then
                            -- if we have finished reading out the current frame, wait until the next one is ready
                            if dma_line_count = G_END_ACTIVE_Y - 1 then
                                state <= WAIT_FOR_VSYNC;
                            else -- read out the next line
                                dma_line_count <= dma_line_count + to_unsigned(1, dma_line_count'length);
                                state          <= LINE_DMA_START;
                            end if;
                        end if;

                    when others =>
                        state <= WAIT_FOR_FLUSH;
                end case;
            end if;
        end if;
    end process;

    -- we will use the prog_full flag to stall the DMA transfer until we have room for another burst
    dma_stall <= pixel_fifo_prog_full_dma_clk;

    -----------------------------------------------------------------
    -- 3. Read Data CDC FIFO and pixel readout
    -----------------------------------------------------------------

    -- CDC back to the dma_clk domain (all bits must be independent)

    pixel_fifo_empty_dma_clk     <= cdc_to_dma_clk_arr(2);
    pixel_fifo_prog_full_dma_clk <= cdc_to_dma_clk_arr(1);
    vga_vsync_dma_clk            <= cdc_to_dma_clk_arr(0);

    xpm_cdc_to_dma_clk_inst : xpm_cdc_array_single
    generic map(DEST_SYNC_FF => 2, WIDTH => 3)
    port map(
        dest_out => cdc_to_dma_clk_arr(2 downto 0),
        dest_clk => dma_clk_in,
        src_clk  => pixelclk_in,
        src_in   => (pixel_fifo_empty, pixel_fifo_prog_full, vga_vsync)
    );

    pixel_fifo_empty <= not pixel_axi_stream_mosi.tvalid;

    -- CDC into the pixelclk domain
    axi_stream_xpm_fifo_wrapper_inst : entity work.axi_stream_xpm_fifo_wrapper
        generic map(
            G_DUAL_CLOCK       => true,
            G_RELATED_CLOCKS   => false,              -- technically "true", but only "false" works with XPM_GHDL
            G_FIFO_DEPTH       => G_PIXEL_FIFO_DEPTH, -- experiment to find how small a FIFO we can get away with
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

    xpm_cdc_gray_to_dma_clk_inst : xpm_cdc_gray
    generic map(
        DEST_SYNC_FF          => 2, -- DECIMAL; range: 2-10
        REG_OUTPUT            => 0, -- DECIMAL; 0=disable registered output, 1=enable registered output
        SIM_LOSSLESS_GRAY_CHK => 0, -- DECIMAL; 0=disable lossless check, 1=enable lossless check
        WIDTH                 => 32 -- DECIMAL; range: 2-32
    )
    port map(
        dest_out_bin => pixel_underflow_count_dma_clk_out,      -- WIDTH-bit output: Binary input bus (src_in_bin) syncd to dest_clk
        dest_clk     => dma_clk_in,                             -- 1-bit input: Destination clock.
        src_clk      => pixelclk_in,                            -- 1-bit input: Source clock.
        src_in_bin   => std_logic_vector(pixel_underflow_count) -- WIDTH-bit input: Binary input bus that will be synchronized to the
        -- destination clock domain.

    );

    --! Note: everything here is registered
    pixel_readout_proc : process (pixelclk_in)
    begin
        if rising_edge(pixelclk_in) then
            if pixelclk_reset_in = '1' then
                pixel_underflow_count <= (others => '0');
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
                        pixel_underflow_count <= pixel_underflow_count + to_unsigned(1, pixel_underflow_count'length);
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