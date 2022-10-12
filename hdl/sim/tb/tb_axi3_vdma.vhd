library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.joe_common_pkg.all;
use work.axi_pkg.all;
use work.graphics_pkg.all;
--
library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

entity axi3_vdma_tb is
    generic (runner_cfg : string);
end;

architecture bench of axi3_vdma_tb is
    signal mem : memory_t; -- get from vunit_axi_slave

    constant MEM_WORDS : integer := 2048;

    -- Clock period
    constant pixelclk_period : time := 40 ns;    -- 25MHz
    constant dma_clk_period  : time := 6.666 ns; -- 150MHz
    -- Generics
    constant G_END_ACTIVE_X     : integer   := 640;
    constant G_FRONT_PORCH_X    : integer   := 16;
    constant G_SYNC_PULSE_X     : integer   := 96;
    constant G_BACK_PORCH_X     : integer   := 48;
    constant G_END_ACTIVE_Y     : integer   := 480;
    constant G_FRONT_PORCH_Y    : integer   := 10;
    constant G_SYNC_PULSE_Y     : integer   := 2;
    constant G_BACK_PORCH_Y     : integer   := 33;
    constant G_ACTIVE_HS        : std_logic := '0';
    constant G_ACTIVE_VS        : std_logic := '0';
    constant G_PIXEL_FIFO_DEPTH : integer   := 512;

    -- Ports
    signal dma_clk_in                        : std_logic;
    signal pixelclk_in                       : std_logic;
    signal pixelclk_reset_in                 : std_logic;
    signal dma_reset_in                      : std_logic;
    signal dma_axi_hp_mosi_out               : t_axi_mosi;
    signal dma_axi_hp_miso_in                : t_axi_miso;
    signal vga_pixel_out                     : t_pixel;
    signal vga_hsync_out                     : std_logic;
    signal vga_vsync_out                     : std_logic;
    signal vga_blank_out                     : std_logic;
    signal buffer0_start                     : std_logic_vector(31 downto 0);
    signal buffer1_start                     : std_logic_vector(31 downto 0);
    signal pixel_underflow_count_dma_clk_out : std_logic_vector(31 downto 0);
    signal start_of_frame_dma_clk_out        : std_logic;
    signal buffer_sel_dma_clk_in             : std_logic;

begin
    test_runner_watchdog(runner, 35 ms);

    -- DUT
    axi3_vdma_inst : entity work.axi3_vdma
        generic map(
            G_END_ACTIVE_X     => G_END_ACTIVE_X,
            G_FRONT_PORCH_X    => G_FRONT_PORCH_X,
            G_SYNC_PULSE_X     => G_SYNC_PULSE_X,
            G_BACK_PORCH_X     => G_BACK_PORCH_X,
            G_END_ACTIVE_Y     => G_END_ACTIVE_Y,
            G_FRONT_PORCH_Y    => G_FRONT_PORCH_Y,
            G_SYNC_PULSE_Y     => G_SYNC_PULSE_Y,
            G_BACK_PORCH_Y     => G_BACK_PORCH_Y,
            G_ACTIVE_HS        => G_ACTIVE_HS,
            G_ACTIVE_VS        => G_ACTIVE_VS,
            G_PIXEL_FIFO_DEPTH => G_PIXEL_FIFO_DEPTH
        )
        port map(
            dma_clk_in                        => dma_clk_in,
            pixelclk_in                       => pixelclk_in,
            pixelclk_reset_in                 => pixelclk_reset_in,
            dma_reset_in                      => dma_reset_in,
            dma_axi_hp_mosi_out               => dma_axi_hp_mosi_out,
            dma_axi_hp_miso_in                => dma_axi_hp_miso_in,
            vga_pixel_out                     => vga_pixel_out,
            vga_hsync_out                     => vga_hsync_out,
            vga_vsync_out                     => vga_vsync_out,
            vga_blank_out                     => vga_blank_out,
            buffer0_start_in                  => buffer0_start,
            buffer1_start_in                  => buffer1_start,
            pixel_underflow_count_dma_clk_out => pixel_underflow_count_dma_clk_out,
            start_of_frame_dma_clk_out        => start_of_frame_dma_clk_out,
            buffer_sel_dma_clk_in             => buffer_sel_dma_clk_in
        );

    vunit_axi_slave_inst : entity work.vunit_axi_slave
        generic map(G_NAME => "DDR3", G_BASE_ADDR => x"0000_0000", G_BYTES => MEM_WORDS * 4, G_DEBUG_PRINT => false)
        port map(
            axi_clk        => dma_clk_in,
            axi_mosi       => dma_axi_hp_mosi_out,
            axi_miso       => dma_axi_hp_miso_in,
            memory_ref_out => mem
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("frame_gen test") then
                info("frame_gen test alive");
                buffer0_start <= x"0000_0000"; -- 2MB buffers
                buffer1_start <= x"0020_0000";

                -- set up intial contents for buffer 0
                for i in 0 to 2 ** 10 - 1 loop
                    write_integer(mem, address => i * 4, word => i);
                end loop;

                buffer_sel_dma_clk_in <= '0'; -- select buffer 0

                -- reset sequencing
                dma_reset_in      <= '1';
                pixelclk_reset_in <= '1';
                wait for 10 * pixelclk_period;
                wait until rising_edge(dma_clk_in);
                dma_reset_in <= '0';
                wait until rising_edge(pixelclk_in);
                pixelclk_reset_in <= '0';
                wait for 100 * dma_clk_period;
                wait until start_of_frame_dma_clk_out = '1';
                wait until start_of_frame_dma_clk_out = '1';
                test_runner_cleanup(runner);
            end if;
        end loop;
    end process main;

    pixelclk_process : process
    begin
        pixelclk_in <= '1';
        wait for pixelclk_period/2;
        pixelclk_in <= '0';
        wait for pixelclk_period/2;
    end process;
    dma_clk_process : process
    begin
        dma_clk_in <= '1';
        wait for dma_clk_period/2;
        dma_clk_in <= '0';
        wait for dma_clk_period/2;
    end process;

end;