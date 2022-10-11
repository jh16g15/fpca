
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

use work.joe_common_pkg.all;
use work.axi_pkg.all;

-- <-----Cut code below this line and paste into the architecture body---->

-- xpm_fifo_axis: AXI Stream FIFO
-- Xilinx Parameterized Macro, version 2021.1

entity axi_stream_xpm_fifo_wrapper is
    generic (
        G_DUAL_CLOCK        : boolean := false; --! CDC FIFO?
        G_RELATED_CLOCKS    : boolean := false; --! if dual clocks, are they generated from the same source?
        G_FIFO_DEPTH        : integer := 64;
        G_DATA_WIDTH        : integer := 32;    --! must be a whole number of bytes
        G_FULL_PACKET       : boolean := false; --! Packet Mode FIFO
        G_PROG_FULL_THRESH  : integer := 7;     --! Min = 5+2 (CDC), Max = FIFO_DEPTH-5
        G_PROG_EMPTY_THRESH : integer := 5      --! Min = 5,         Max = FIFO_DEPTH-5

    );
    port (

        input_clk       : in std_logic;
        output_clk      : in std_logic; --! when using dual clock
        input_clk_reset : in std_logic;

        input_axi_stream_mosi_in  : in t_axi_stream32_mosi;
        input_axi_stream_miso_out : out t_axi_stream32_miso;

        output_axi_stream_mosi_out : out t_axi_stream32_mosi;
        output_axi_stream_miso_in  : in t_axi_stream32_miso;

        -- flags (optional)
        almost_empty : out std_logic;
        almost_full  : out std_logic;
        prog_empty   : out std_logic;
        prog_full    : out std_logic

    );
end entity axi_stream_xpm_fifo_wrapper;

architecture rtl of axi_stream_xpm_fifo_wrapper is

    signal input_clk_resetn : std_logic;

    function get_dual_clock_mode_string(param : boolean) return string is
    begin
        if param = true then
            return "independent_clock";
        else
            return "common_clock";
        end if;
    end function;

    function get_bool_string(param : boolean) return string is
    begin
        if param = true then
            return "true";
        else
            return "false";
        end if;
    end function;

    function get_bool_int(param : boolean) return integer is
    begin
        if param = true then
            return 1;
        else
            return 0;
        end if;
    end function;
begin
input_clk_resetn <= input_clk_reset;

    xpm_fifo_axis_inst : xpm_fifo_axis
    generic map(
        CASCADE_HEIGHT      => 0,                                        -- DECIMAL
        CDC_SYNC_STAGES     => 2,                                        -- DECIMAL
        CLOCKING_MODE       => get_dual_clock_mode_string(G_DUAL_CLOCK), -- String "independent_clock"
        ECC_MODE            => "no_ecc",                                 -- String
        FIFO_DEPTH          => G_FIFO_DEPTH,                             -- DECIMAL
        FIFO_MEMORY_TYPE    => "auto",                                   -- String
        PACKET_FIFO         => get_bool_string(G_FULL_PACKET),           -- String
        PROG_EMPTY_THRESH   => G_PROG_EMPTY_THRESH,                      -- DECIMAL
        PROG_FULL_THRESH    => G_PROG_FULL_THRESH,                       -- DECIMAL
        RD_DATA_COUNT_WIDTH => 1,                                        -- DECIMAL
        RELATED_CLOCKS      => get_bool_int(G_RELATED_CLOCKS),           -- DECIMAL
        SIM_ASSERT_CHK      => 0,                                        -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
        TDATA_WIDTH         => G_DATA_WIDTH,                             -- DECIMAL
        TDEST_WIDTH         => 1,                                        -- DECIMAL
        TID_WIDTH           => 1,                                        -- DECIMAL
        TUSER_WIDTH         => 1,                                        -- DECIMAL
        USE_ADV_FEATURES    => "1A0A",                                   -- String (AXI-S default ("1000"), with added prog_full/empty and almost_full/empty)
        WR_DATA_COUNT_WIDTH => 1                                         -- DECIMAL
    )
    port map(

        -- input AXI-Stream Slave port
        s_aclk        => input_clk,
        s_aresetn     => input_clk_resetn, -- 1-bit input: Active low asynchronous reset.
        s_axis_tdata  => input_axi_stream_mosi_in.tdata,
        s_axis_tvalid => input_axi_stream_mosi_in.tvalid,
        s_axis_tlast  => input_axi_stream_mosi_in.tlast,
        s_axis_tdest => (others => '0'),
        s_axis_tid => (others => '0'),
        s_axis_tkeep => (others => '1'),
        s_axis_tstrb => (others => '1'),
        s_axis_tuser => (others => '0'),
        s_axis_tready => input_axi_stream_miso_out.tready,

        -- output AXI-Stream Master port
        m_aclk        => output_clk,
        m_axis_tdata  => output_axi_stream_mosi_out.tdata,
        m_axis_tlast  => output_axi_stream_mosi_out.tlast,
        m_axis_tvalid => output_axi_stream_mosi_out.tvalid,
        m_axis_tdest  => open,
        m_axis_tid    => open,
        m_axis_tkeep  => open,
        m_axis_tstrb  => open,
        m_axis_tuser  => open,
        m_axis_tready => output_axi_stream_miso_in.tready,

        -- flags and counters
        almost_full_axis   => almost_full, -- 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
        prog_full_axis     => prog_full,   -- 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal to the programmable full threshold value. It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.
        wr_data_count_axis => open,
        almost_empty_axis  => almost_empty, -- 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
        prog_empty_axis    => prog_empty,   -- 1-bit output: Programmable Empty- This signal is asserted when the number of words in the FIFO is less than or equal to the programmable empty threshold value. It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.
        rd_data_count_axis => open,

        -- ECC
        dbiterr_axis       => open,
        sbiterr_axis       => open,
        injectdbiterr_axis => '1',
        injectsbiterr_axis => '1'
    );

    -- End of xpm_fifo_axis_inst instantiation
end architecture;