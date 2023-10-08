library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library xpm;
use xpm.vcomponents.all;

entity cdc_single_array is
    generic (
        G_WIDTH : integer := 1
    );
    port (
        src_clk : in std_logic;
        src_in     : in std_logic_vector(G_WIDTH-1 downto 0);
        dest_clk : in std_logic;
        dest_out   : out  std_logic_vector(G_WIDTH-1 downto 0)
    );
end entity cdc_single_array;

architecture rtl of cdc_single_array is

begin
   -- xpm_cdc_array_single: Single-bit Array Synchronizer
   -- Xilinx Parameterized Macro, version 2021.1

   xpm_cdc_array_single_inst : xpm_cdc_array_single
   generic map (
      DEST_SYNC_FF => 2,   -- DECIMAL; range: 2-10
      INIT_SYNC_FF => 0,   -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      SIM_ASSERT_CHK => 0, -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG => 1,  -- DECIMAL; 0=do not register input, 1=register input
      WIDTH => G_WIDTH     -- DECIMAL; range: 1-1024
   )
   port map (
      dest_out => dest_out, -- WIDTH-bit output: src_in synchronized to the destination clock domain. This
                            -- output is registered.

      dest_clk => dest_clk, -- 1-bit input: Clock signal for the destination clock domain.
      src_clk => src_clk,   -- 1-bit input: optional; required when SRC_INPUT_REG = 1
      src_in => src_in      -- WIDTH-bit input: Input single-bit array to be synchronized to destination clock
                            -- domain. It is assumed that each bit of the array is unrelated to the others.
                            -- This is reflected in the constraints applied to this macro. To transfer a binary
                            -- value losslessly across the two clock domains, use the XPM_CDC_GRAY macro
                            -- instead.

   );
end architecture;