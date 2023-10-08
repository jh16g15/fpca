library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

entity cdc_pulse is
    generic (
        SYNC_FF : integer := 2
    );
    port (
        src_clk   : in std_logic;
        src_pulse : in std_logic;
        dest_clk   : in std_logic;
        dest_pulse : out std_logic
    );
end entity cdc_pulse;

architecture rtl of cdc_pulse is

begin
    -- Rising edge of this signal initiates a pulse transfer to the destination clock domain. The minimum gap between
    -- each pulse transfer must be at the minimum 2*(larger(src_clk period, dest_clk period)). This is measured between
    -- the falling edge of a src_pulse to the rising edge of the next src_pulse. This minimum gap will guarantee that
    -- each rising edge of src_pulse will generate a pulse the size of one dest_clk period in the destination clock domain.
    xpm_cdc_pulse_inst : xpm_cdc_pulse
    generic
    map (
    DEST_SYNC_FF   => SYNC_FF, -- DECIMAL; range: 2-10
    INIT_SYNC_FF   => 1, -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    REG_OUTPUT     => 0, -- DECIMAL; 0=disable registered output, 1=enable registered output
    RST_USED       => 0, -- DECIMAL; 0=no reset, 1=implement reset
    SIM_ASSERT_CHK => 0 -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    ) port map (
    dest_pulse => dest_pulse,
    dest_clk   => dest_clk,
    dest_rst   => '0',
    src_clk    => src_clk,
    src_pulse  => src_pulse,
    src_rst    => '0'
    );


end architecture;

