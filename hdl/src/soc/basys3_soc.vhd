library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

-- fpca/hdl/sim
-- fpca/software/build/*.hex

entity basys3_soc is
    generic (
        G_PROJECT_ROOT       : string  := "";
        G_MEM_KBYTES         : integer := 64;
        G_MEM_INIT_FILE      : string  := "software/hex/main.hex";
        G_BOOT_INIT_FILE     : string  := "software/hex/boot.hex";
        G_SOC_FREQ           : integer := 50_000_000;
        G_MEM_CTRL_CLK_FREQ_KHZ : integer := 100_000;
        G_DEFAULT_BAUD       : integer := 9600;
        G_INCLUDE_JTAG_DEBUG : boolean := false
    );
    port (
        clk   : in std_logic;
        mem_ctrl_clk : in std_logic;
        reset : in std_logic;

        -- GPIO
        gpio_led_out : out std_logic_vector(31 downto 0);
        gpio_btn_in  : in std_logic_vector(31 downto 0);
        gpio_sw_in   : in std_logic_vector(31 downto 0);

        -- Quad Seven Seg
        sseg_ca_out : out std_logic_vector(7 downto 0);
        sseg_an_out : out std_logic_vector(3 downto 0);

        -- UART
        uart_tx_out : out std_logic;
        uart_rx_in  : in std_logic;

        -- I2C (write only)
        i2c_scl_out : out std_logic;
        i2c_sda_out : out std_logic;

        -- SPI (for SD card etc)
        spi_sck_out  : out std_logic;
        spi_miso_in  : in std_logic;
        spi_mosi_out : out std_logic;
        spi_csn_out   : out std_logic;

        -- QSPI PSRAM
        psram_clk  : out std_logic;
        psram_cs_n : out std_logic;
        psram_sio  : inout std_logic_vector(3 downto 0);

        vga_hs_out : out std_logic;
        vga_vs_out : out std_logic;
        vga_r      : out std_logic_vector(3 downto 0);
        vga_g      : out std_logic_vector(3 downto 0);
        vga_b      : out std_logic_vector(3 downto 0)
    );
end entity basys3_soc;

architecture rtl of basys3_soc is

    constant MEM_BYTES : integer := G_MEM_KBYTES * 1024;
    constant MEM_WORDS : integer := MEM_BYTES / 4;
    constant MEM_INIT_FILE  : string := G_PROJECT_ROOT & G_MEM_INIT_FILE;
    constant BOOT_INIT_FILE : string := G_PROJECT_ROOT & G_BOOT_INIT_FILE;

    constant G_PC_RESET_ADDR : unsigned(31 downto 0) := x"F000_0000"; -- always reset into bootloader

    constant G_NUM_SLAVES : integer := 16; -- max 16

    -- for GPIO register bank
    constant G_NUM_RW_REGS : integer := 4;
    constant G_NUM_RO_REGS : integer := 4;

    signal if_wb_mosi         : t_wb_mosi;
    signal if_wb_miso         : t_wb_miso;
    signal mem_wb_mosi        : t_wb_mosi;
    signal mem_wb_miso        : t_wb_miso;
    signal wb_master_sel_mosi : t_wb_mosi;
    signal wb_master_sel_miso : t_wb_miso;
    signal jtag_wb_mosi       : t_wb_mosi;
    signal jtag_wb_miso       : t_wb_miso;
    signal wb_cpu_sel_mosi    : t_wb_mosi;
    signal wb_cpu_sel_miso    : t_wb_miso;

    signal wb_slave_mosi_arr : t_wb_mosi_arr(G_NUM_SLAVES - 1 downto 0);
    signal wb_slave_miso_arr : t_wb_miso_arr(G_NUM_SLAVES - 1 downto 0);

    -- Wishbone to framebuffer
    signal text_display_wb_mosi_out : t_wb_mosi;
    signal text_display_wb_miso_in  : t_wb_miso;

    signal rw_regs_out : t_slv32_arr(G_NUM_RW_REGS - 1 downto 0);
    signal ro_regs_in  : t_slv32_arr(G_NUM_RO_REGS - 1 downto 0);

    signal monitor_write_cmd_stb  : std_logic;
    signal monitor_read_cmd_stb  : std_logic;

    attribute mark_debug                    : boolean;
--    attribute mark_debug of rw_regs_out     : signal is true;
--    attribute mark_debug of ro_regs_in      : signal is true;
    attribute mark_debug of wb_cpu_sel_mosi : signal is true;
    attribute mark_debug of wb_cpu_sel_miso : signal is true;
    attribute mark_debug of monitor_write_cmd_stb : signal is true;
    attribute mark_debug of monitor_read_cmd_stb : signal is true;
    attribute mark_debug of psram_cs_n : signal is true;

    -- Seven Segment Display controller
    signal sseg_display_data : std_logic_vector(15 downto 0);

    component jtag_wb_master
        generic (
            G_ILA : boolean
        );
        port (
            clk         : in std_logic;
            reset       : in std_logic;
            wb_mosi_out : out t_wb_mosi;
            wb_miso_in  : in t_wb_miso
        );
    end component;
begin

    cpu_top_inst : entity work.cpu_top
        generic map(
            G_PC_RESET_ADDR => G_PC_RESET_ADDR
        )
        port map(
            clk             => clk,
            reset           => reset,
            extern_halt_in  => '0',
            if_wb_mosi_out  => if_wb_mosi,
            if_wb_miso_in   => if_wb_miso,
            mem_wb_mosi_out => mem_wb_mosi,
            mem_wb_miso_in  => mem_wb_miso
        );

    -- 2:1 arbiter
    wb_arbiter_inst : entity work.wb_arbiter
        generic map(
            G_ARBITER => "priority"
        )
        port map(
            wb_clk                 => clk,
            wb_reset               => reset,
            wb_master_0_mosi_in    => if_wb_mosi,
            wb_master_0_miso_out   => if_wb_miso,
            wb_master_1_mosi_in    => mem_wb_mosi,
            wb_master_1_miso_out   => mem_wb_miso,
            wb_master_sel_mosi_out => wb_cpu_sel_mosi,
            wb_master_sel_miso_in  => wb_cpu_sel_miso
        );
    gen_jtag_false : if G_INCLUDE_JTAG_DEBUG = false generate
        wb_master_sel_mosi <= wb_cpu_sel_mosi;
        wb_cpu_sel_miso    <= wb_master_sel_miso;
    end generate;

    gen_jtag_true : if G_INCLUDE_JTAG_DEBUG = true generate
        --        -- wraps a Xilinx JTAG-AXI master
        --        jtag_wb_master_inst : jtag_wb_master
        --        generic map(G_ILA => true)
        --        port map(
        --            clk         => clk,
        --            reset       => reset,
        --            wb_mosi_out => jtag_wb_mosi,
        --            wb_miso_in  => jtag_wb_miso
        --        );
        --        -- 2:1 arbiter to choose between CPU and JTAG access
        --        wb_debug_arbiter_inst : entity work.wb_arbiter
        --            generic map(
        --                G_ARBITER => "simple" -- most recently used
        --            )
        --            port map(
        --                wb_clk                 => clk,
        --                wb_reset               => reset,
        --                wb_master_0_mosi_in    => wb_cpu_sel_mosi,
        --                wb_master_0_miso_out   => wb_cpu_sel_miso,
        --                wb_master_1_mosi_in    => jtag_wb_mosi,
        --                wb_master_1_miso_out   => jtag_wb_miso,
        --                wb_master_sel_mosi_out => wb_master_sel_mosi,
        --                wb_master_sel_miso_in  => wb_master_sel_miso
        --            );

    end generate;

    wb_address_monitor_inst : entity work.wb_address_monitor
      generic map (
        G_ADDR => x"0000_0000"
      )
      port map (
        wb_clk => clk,
        wb_mosi => wb_master_sel_mosi,
        wb_miso => wb_master_sel_miso,
        write_cmd_stb => monitor_write_cmd_stb,
        read_cmd_stb => monitor_read_cmd_stb
      );

    -- 1:N interconnect
    wb_interconnect_inst : entity work.wb_interconnect
        generic map(
            G_NUM_SLAVES => G_NUM_SLAVES
        )
        port map(
            wb_clk                => clk,
            wb_reset              => reset,
            wb_master_mosi_in     => wb_master_sel_mosi,
            wb_master_miso_out    => wb_master_sel_miso,
            wb_slave_mosi_arr_out => wb_slave_mosi_arr,
            wb_slave_miso_arr_in  => wb_slave_miso_arr
        );

    --! Main memory
    --! x0000_0000 to x0FFF_FFFF
    wb_sp_bram_inst : entity work.wb_sp_bram
        generic map(
            G_MEM_DEPTH_WORDS => MEM_WORDS,
            G_INIT_FILE       => MEM_INIT_FILE
        )
        port map(
            wb_clk      => clk,
            wb_reset    => reset,
            wb_mosi_in  => wb_slave_mosi_arr(0),
            wb_miso_out => wb_slave_miso_arr(0)
        );

    --! GPIO Register Bank
    --! x1000_0000 to x1FFF_FFFF
    --! RW registers are 0x000, 0x004 up to 0x0FC
    --! RO registers are 0x100, 0x104 up to 0x1FC
    wb_gpio_regs_inst : entity work.wb_regs
        generic map(
            G_NUM_RW_REGS => G_NUM_RW_REGS,
            G_NUM_RO_REGS => G_NUM_RO_REGS
        )
        port map(
            wb_clk      => clk,
            wb_reset    => reset,
            wb_mosi_in  => wb_slave_mosi_arr(1),
            wb_miso_out => wb_slave_miso_arr(1),
            rw_regs_out => rw_regs_out,
            ro_regs_in  => ro_regs_in
        );
    -- Map GPIO registers to peripherals
    ro_regs_in(0)     <= gpio_btn_in;
    ro_regs_in(1)     <= gpio_sw_in;
    ro_regs_in(2)     <= int2slv(G_SOC_FREQ);
    ro_regs_in(3)     <= int2slv(MEM_BYTES);

    gpio_led_out      <= rw_regs_out(0);
    sseg_display_data <= rw_regs_out(1)(15 downto 0);
    i2c_scl_out <= rw_regs_out(2)(0);
    i2c_sda_out <= rw_regs_out(3)(0);

    -- 0x2000_00000
    wb_uart_simple_inst : entity work.wb_uart_simple
        generic map(
            DEFAULT_BAUD => G_DEFAULT_BAUD,
            REFCLK_FREQ  => G_SOC_FREQ
        )
        port map(
            wb_clk      => clk,
            wb_reset    => reset,
            wb_mosi_in  => wb_slave_mosi_arr(2),
            wb_miso_out => wb_slave_miso_arr(2),
            uart_tx_out => uart_tx_out,
            uart_rx_in  => uart_rx_in
        );

    -- 0x3000_0000
    wb_timer_inst : entity work.wb_timer
        generic map(
            G_NUM_TIMERS => 1
        )
        port map(
            wb_clk              => clk,
            wb_reset            => reset,
            wb_mosi_in          => wb_slave_mosi_arr(3),
            wb_miso_out         => wb_slave_miso_arr(3),
            pwm_out             => open,
            timer_interrupt_out => open
        );

    -- 0x4000_0000 (external framebuffer, up to 256MB of address space)
    text_display_inst : entity work.wb_display_text_controller
        generic map(
            G_PROJECT_ROOT => G_PROJECT_ROOT
        )
        port map(
            pixelclk  => clk,
            reset     => reset,
            vga_hs    => vga_hs_out,
            vga_vs    => vga_vs_out,
            vga_blank => open,
            vga_r     => vga_r,
            vga_g     => vga_g,
            vga_b     => vga_b,

            text_display_wb_mosi_in  => wb_slave_mosi_arr(4),
            text_display_wb_miso_out => wb_slave_miso_arr(4)
        );

    quad_seven_seg_driver_inst : entity work.quad_seven_seg_driver
        generic map(
            G_REFCLK_FREQ => G_SOC_FREQ
        )
        port map(
            clk             => clk,
            display_data_in => sseg_display_data,
            sseg_ca         => sseg_ca_out,
            sseg_an         => sseg_an_out
        );

    -- -- 0x5000_0000 SPI controller for SD Card
    wb_spi_inst : entity work.wb_spi
        port map(
            wb_clk      => clk,
            wb_reset    => reset,
            wb_mosi_in  => wb_slave_mosi_arr(5),
            wb_miso_out => wb_slave_miso_arr(5),
            sck_out     => spi_sck_out,
            cs_n_out    => spi_csn_out,
            mosi_out    => spi_mosi_out,
            miso_in     => spi_miso_in
        );

    -- 0x6000_0000 QSPI 8MB PSRAM controller
    -- 0x6000_0000 to 0x607f_ffff   Mapped RAM
--    wb_machdyne_qqspi_inst : entity work.wb_machdyne_qqspi
--    port map (
--        wb_clk => clk,
--        wb_reset => reset,
--        wb_mosi_in => wb_slave_mosi_arr(6),
--        wb_miso_out => wb_slave_miso_arr(6),
--        psram_clk => psram_clk,
--        psram_cs_n => psram_cs_n,
--        psram_sio => psram_sio
--    );
     wb_psram_aps6404_streaming_inst : entity work.wb_psram_aps6404_streaming
         generic map (
           MEM_CTRL_CLK_FREQ_KHZ => G_MEM_CTRL_CLK_FREQ_KHZ
         )
         port map (
           wb_clk => clk,
           mem_ctrl_clk => mem_ctrl_clk, -- max 168MHz
           wb_reset => reset,
           wb_mosi_in => wb_slave_mosi_arr(6),
           wb_miso_out => wb_slave_miso_arr(6),
           psram_clk => psram_clk,
           psram_cs_n => psram_cs_n,
           psram_sio => psram_sio
         );

    -- generic SPI controller for non-memory mapped access (SPI only)
    -- wb_spi_psram_inst : entity work.wb_spi
    --      port map(
    --          wb_clk      => clk,
    --          wb_reset    => reset,
    --          wb_mosi_in  => wb_slave_mosi_arr(6),
    --          wb_miso_out => wb_slave_miso_arr(6),
    --          sck_out     => psram_clk,
    --          cs_n_out    => psram_cs_n,
    --          mosi_out    => psram_sio(0),
    --          miso_in     => psram_sio(1)
    --      );

    gen_unmapped : for i in 7 to 14 generate
        wb_unmapped_slv_inst : entity work.wb_unmapped_slv
            port map(
                wb_mosi_in  => wb_slave_mosi_arr(i),
                wb_miso_out => wb_slave_miso_arr(i)
            );
    end generate;

    --! Bootloader memory
    --! xF000_0000 to xFFFF_FFFF
    bootloader_inst : entity work.wb_sp_bram
        generic map(
            G_MEM_DEPTH_WORDS => 256,
            G_INIT_FILE       => BOOT_INIT_FILE
        )
        port map(
            wb_clk      => clk,
            wb_reset    => reset,
            wb_mosi_in  => wb_slave_mosi_arr(15),
            wb_miso_out => wb_slave_miso_arr(15)
        );
end architecture;