----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.11.2021 16:09:34
-- Design Name: 
-- Module Name: jh_uart_tx - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity jh_uart_tx is
    Generic (
        REFCLK_FREQ : integer := 125_000_000;
        BAUD_RATE : integer := 9600
    );
    Port ( 
        refclk_in : in std_logic;
        reset_in : std_logic;
        
        uart_tx : out std_logic; --! Output to physical pin
    
        -- AXI-S style interface
        byte_to_transmit_in : in std_logic_vector(7 downto 0);
        uart_tx_valid_in    : in std_logic;  
        uart_tx_ready_out   : out std_logic
    
    );
end jh_uart_tx;

architecture Behavioral of jh_uart_tx is

    -- UART packet structure 
    -- (line default HIGH)
    -- 1 start bit LOW
    -- 8 data bits (LSB first)
    -- 0 parity bits
    -- 1 stop bit HIGH
    -- may need a wait statement here


    -- clocks between new bits
    constant DIVISOR : integer := REFCLK_FREQ / BAUD_RATE;

    signal div_count : integer;
    
    type t_state is (RESET, WAIT_FOR_VALID, START_BIT, TRANSMIT_DATA, STOP_BIT );     
    signal state : t_state := RESET; 
    signal stored_byte : std_logic_vector(9 downto 0);
    signal bit_count : integer; -- range (0 to 7);
    
    signal bit_to_send : std_logic;
        
begin

    bit_to_send <= stored_byte(0); -- lsb first
    
    uart_tx_proc : process (refclk_in) is 
    
    begin
    
        if rising_edge (refclk_in) then
            if reset_in = '1' then
                uart_tx_ready_out   <= '0';
                uart_tx <= '1'; -- hold UART line high
            else
                case(state) is 
                    when RESET => 
                        uart_tx <= '1'; -- hold UART line high
                        div_count <= 0;
                        state <= WAIT_FOR_VALID;
                        uart_tx_ready_out <= '1';
                    when WAIT_FOR_VALID =>  
                        if uart_tx_valid_in = '1' then 
                            state <= TRANSMIT_DATA;
                            stored_byte(9) <= '1';  -- stop bit
                            stored_byte(8 downto 1)  <= byte_to_transmit_in;
                            stored_byte(0) <= '0';  -- start bit
                            uart_tx_ready_out <= '0';
                            -- uart_tx <= '0'; -- generate START BIT high->low
                            div_count <= 0;
                            bit_count <= 0;
                        end if;                     
                    when TRANSMIT_DATA => 
                        div_count <= div_count + 1;
                        -- send next bit
                        if(div_count = DIVISOR-1) then
                            uart_tx <= bit_to_send; -- send LSB first
                            div_count <= 0;
                            bit_count <= bit_count + 1;
                            stored_byte <= '1' & stored_byte(9 downto 1);  -- shift right one bit 
                            if bit_count = 9 then
                                state <= WAIT_FOR_VALID;
                                uart_tx_ready_out <= '1';
                                uart_tx <= '1'; -- send STOP bit
                            end if;
                        end if;
                    when others => 
                        state <= RESET;
                end case;            
             end if;  
        end if;     
    end process uart_tx_proc;

end Behavioral;
