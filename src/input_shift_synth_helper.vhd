library ieee;
use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

--! Shift register to allow us to compact a many-bit wide input port into 
--! a single wire (plus LOAD) 
entity input_shift_synth_helper is
    generic (
        WIDTH : integer := 32
    );
    port (
        clk      : in std_logic;
        shift_in : in std_logic;
        load     : in std_logic;
        dout     : out std_logic_vector(WIDTH - 1 downto 0)
    );
end entity input_shift_synth_helper;

architecture rtl of input_shift_synth_helper is
    signal shift_reg : std_logic_vector(WIDTH - 1 downto 0);

begin
    process (clk) is
    begin
        if rising_edge(clk) then
            shift_reg <= shift_reg(shift_reg'left - 1 downto 0) & shift_in;
            if load = '1' then
                dout <= shift_reg;
            end if;
        end if;
    end process;

end architecture;