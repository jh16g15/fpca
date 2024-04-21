library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr32 is
    port (
        clk   : in std_logic;
        reset : in std_logic := '0';
        en    : in std_logic := '1';
        dout  : out std_logic_vector(31 downto 0)
    );
end entity lfsr32;

architecture rtl of lfsr32 is

    signal lfsr_shreg : std_logic_vector(31 downto 0);
begin

    dout <= lfsr_shreg;
   
    -- Xilinx Language Template for 32-bit LFSR
process(clk)
begin
   if rising_edge(clk) then
      if (reset = '1') then
        lfsr_shreg <= (others => '0');
      elsif en='1' then
         lfsr_shreg(31 downto 1) <= lfsr_shreg(30 downto 0);
         lfsr_shreg(0) <= not(lfsr_shreg(31) XOR lfsr_shreg(22) XOR lfsr_shreg(2) XOR lfsr_shreg(1));
      end if;
   end if;
end process;


end architecture;