----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.04.2023 00:01:06
-- Design Name: 
-- Module Name: sim_sspi - 
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sim_sspi is
Port ( 
    byte_in : in STD_LOGIC_VECTOR (7 downto 0);
--    strb_in : in STD_LOGIC;
--    stall_out : out STD_LOGIC;
    byte_out : out STD_LOGIC_VECTOR (7 downto 0);
    strb_out : out STD_LOGIC;
    sck_in : in STD_LOGIC;
    cs_n_in : in STD_LOGIC;
    mosi_in : in STD_LOGIC;
    miso_out : out STD_LOGIC
);
end sim_sspi;

architecture behavioral of sim_sspi is
    signal shift_reg : std_logic_vector(7 downto 0);
begin
    
    process(sck_in, cs_n_in) is
        variable count : integer;
    begin
        strb_out <= '0';
        if cs_n_in = '0' then -- active low slave select
            if rising_edge(sck_in) then -- latch in INPUT bit from outside world
                 shift_reg(7 downto 0) <= shift_reg(6 downto 0) & mosi_in;
                 count := count + 1;
                 if count = 8 then
                    report "SSPI Received Byte "  & to_hstring(shift_reg(6 downto 0) & mosi_in);
                    byte_out <= shift_reg(6 downto 0) & mosi_in;
                    strb_out <= '1'; -- one cycle
                    count := 0;
                 end if;
            end if;
            
            if falling_edge(sck_in) then
                miso_out <= shift_reg(7);
            end if;
        end if;
        if falling_edge(cs_n_in) then
            -- start of transaction
            report "SSPI Start of Transaction";
            count := 0;
            shift_reg <= byte_in;
            miso_out <= byte_in(7);
            report "SSPI Sending " & to_hstring(byte_in); 
        end if;
        
        if rising_edge(cs_n_in) then
            -- end of transaction
            report "SSPI End of Transaction";
        end if;     
    end process;
end ;








