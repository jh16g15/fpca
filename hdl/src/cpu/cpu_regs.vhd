----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.06.2021 23:09:25
-- Design Name: 
-- Module Name: cpu_regs - Behavioral
-- Project Name: 
-- Target Devices: 
-- Description: 
--      A triple port register file for a 32-bit RISC-V homebrew cpu core
--      32 registers total, with the "0" register hardwired to x0000_0000 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cpu_regs is
    Port( 
        CPU_CLK_IN              : in std_logic;
        CPU_RST_IN              : in std_logic;
        
        -- read port A
        READ_PORT_A_ADDR_IN     : in std_logic_vector(4 downto 0);
        READ_PORT_A_DATA_OUT    : out std_logic_vector(31 downto 0);
        -- READ_PORT_A_EN_IN       : in std_logic;  -- for pipelining?
        
        -- read port B
        READ_PORT_B_ADDR_IN     : in std_logic_vector(4 downto 0);
        READ_PORT_B_DATA_OUT    : out std_logic_vector(31 downto 0);
        -- READ_PORT_B_EN_IN       : in std_logic;  -- for pipelining?
                
        -- write port
        WRITE_PORT_ADDR_IN      : in std_logic_vector(4 downto 0);
        WRITE_PORT_DATA_IN      : in std_logic_vector(31 downto 0);
        WRITE_PORT_EN_IN        : in std_logic
        
    );
end cpu_regs;

architecture Behavioral of cpu_regs is

    -- set up our memory 
    type t_reg_bank is array (31 downto 0) of std_logic_vector(31 downto 0);

    -- duplicate to get dual port, instead of triple port
    signal registers_0 : t_reg_bank;

    signal addra : integer range 0 to 31;
    signal addrb : integer range 0 to 31;
    signal addrw : integer range 0 to 31;

begin

    addra <= to_integer(unsigned(READ_PORT_A_ADDR_IN));
    addrb <= to_integer(unsigned(READ_PORT_B_ADDR_IN));
    addrw <= to_integer(unsigned(WRITE_PORT_ADDR_IN));

    -- sequential register bank write process
    write_proc : process(CPU_CLK_IN) is
    begin
        if rising_edge(CPU_CLK_IN) then
            if CPU_RST_IN = '1' then
                registers_0 <= (others=> (others => '0'));    -- reset all registers
            else
                if WRITE_PORT_EN_IN = '1' then 
                    if WRITE_PORT_ADDR_IN /= b"00000" then
                        registers_0(addrw) <= WRITE_PORT_DATA_IN;
                    end if;
                end if;
            end if;
        
        end if;
    end process write_proc;

    -- combinational register bank read (synth to LUTRAM)
    read_proc : process(READ_PORT_A_ADDR_IN, READ_PORT_B_ADDR_IN, registers_0, addra, addrb) is
    begin
        if(READ_PORT_A_ADDR_IN = b"00000") then
            READ_PORT_A_DATA_OUT <= x"0000_0000";
        else
            READ_PORT_A_DATA_OUT <= registers_0(addra);
        end if;
        
        if(READ_PORT_B_ADDR_IN = b"00000") then
            READ_PORT_B_DATA_OUT <= x"0000_0000";
        else
            READ_PORT_B_DATA_OUT <= registers_0(addrb);
        end if;
    
    end process read_proc;



end Behavioral;
