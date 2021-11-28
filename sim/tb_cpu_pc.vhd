
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_cpu_pc is
end entity tb_cpu_pc;

architecture rtl of tb_cpu_pc is
    signal clk : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    signal reset : std_logic := '1';

    signal branch_addr_in : std_logic_vector(31 downto 0);
    signal branch_en_in : std_logic;
    signal pc_out : std_logic_vector(31 downto 0);
    signal next_pc_out : std_logic_vector(31 downto 0);
    
    

begin

    clk <= not clk after CLK_PERIOD/2;
    reset <= '0' after 15 ns;
    
    u_cpu_pc : entity work.cpu_pc
    Generic map (
        G_PC_RESET_ADDR => x"0000_0000"
    )
    Port map (
        clk => clk,
        reset => reset,
        branch_addr_in => branch_addr_in,
        branch_en_in => branch_en_in,
        pc_out => pc_out,
        next_pc_out => next_pc_out
    );

    stim : process is 
    begin
        
        branch_en_in <= '0';
        branch_addr_in <= x"1000_0000";
        wait for 152 ns;
        branch_en_in <= '1';
        wait for CLK_PERIOD;
        branch_en_in <= '0';
        wait for 152 ns;
        assert false report "end of test" severity failure;
        wait;
    end process;

end architecture rtl;