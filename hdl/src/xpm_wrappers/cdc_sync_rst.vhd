library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

entity cdc_sync_rst is
    generic (
        SYNC_FF : integer := 2
    );
    port
    (
        dest_clk   : in std_logic;
        src_rst : in std_logic;
        dest_rst   : out std_logic
    );
end entity cdc_sync_rst;

architecture rtl of cdc_sync_rst is
begin
    xpm_cdc_sync_rst_inst : xpm_cdc_sync_rst
    generic
    map (
    DEST_SYNC_FF   => SYNC_FF, -- DECIMAL; range: 2-10
    INIT           => 1, -- DECIMAL; 0=initialize synchronization registers value
    INIT_SYNC_FF   => 0, -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
    SIM_ASSERT_CHK => 0 -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
    )
    port map
    (
        dest_rst => dest_rst,
        dest_clk => dest_clk,
        src_rst  => src_rst
    );
end architecture;