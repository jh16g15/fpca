library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Will branching give us one "dead" cycle as we can't IF combinationally?

entity cpu_pc is
  generic (
    G_PC_RESET_ADDR : unsigned(31 downto 0) := x"0000_0000"
  );
  port (
    clk : in std_logic;
    reset : in std_logic;
    branch_addr_in : in std_logic_vector(31 downto 0);
    branch_en_in : in std_logic;
    pc_out : out std_logic_vector(31 downto 0);
    next_pc_out : out std_logic_vector(31 downto 0) -- PC+4
      
  );
end entity;

architecture rtl of cpu_pc is
    signal pc : unsigned(31 downto 0);
    signal next_pc : unsigned(31 downto 0);
begin
 
    -- combinational
    next_pc <= pc + to_unsigned(4, 32);
    pc_out <= std_logic_vector(pc);
    next_pc_out <= std_logic_vector(next_pc);

    main_proc : process(clk, reset) is
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pc <= G_PC_RESET_ADDR;
            else
                
                if branch_en_in = '1' then
                  pc<= unsigned(branch_addr_in);
                else
                  pc <= next_pc;
                end if;

            end if;
        end if;
    end process;
    

end architecture;
