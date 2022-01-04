-- A simple UART receiver
-- This just takes one sample halfway through the bit period, relying on a refclk at least 16 times faster than the baud rate.
-- Seeing as FPGA clocks are several orders of magnitude faster than UART baud rates, this will not be an issue.

-- Reliability could be improved by sampling at multiple points throughout the bit period, and then voting on the result.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity jh_uart_rx is
    Generic (
        REFCLK_FREQ : integer  := 125_000_000;
        BAUD_RATE : integer := 9600
    );
    Port ( refclk_in : in STD_LOGIC;
           reset_in : in STD_LOGIC;
           uart_rx : in STD_LOGIC;
           byte_received_out : out STD_LOGIC_VECTOR (7 downto 0);
           uart_rx_valid_out : out STD_LOGIC := '0';
           uart_rx_ready_in : in STD_LOGIC;  -- not sure we can use this (need FIFO)
           uart_rx_error : out STD_LOGIC := '0'
       );
end jh_uart_rx;

architecture rtl of jh_uart_rx is

-- UART packet structure 
    -- (line default HIGH)
    -- 1 start bit LOW
    -- 8 data bits (LSB first)
    -- 0 parity bits
    -- 1 stop bit HIGH
    -- may need a wait statement here
    -- clocks between new bits
    constant DIVISOR : integer := REFCLK_FREQ / BAUD_RATE;
    -- halfway through the bit period, take a sample
    constant SAMPLE_POINT : integer := (DIVISOR / 2) - 1; 
    
    signal div_count : integer;
    
    type t_state is (RESET, WAIT_FOR_READY, WAIT_FOR_START_BIT, START_BIT, RECEIVE_DATA, STOP_BIT );
    signal state : t_state := RESET; 
    
    signal uart_rx_prev : std_logic;
    
    signal sample_strobe : std_logic;
    
    signal bit_count : integer;
    signal rec_byte_shift : std_logic_vector(7 downto 0);
begin
    
    uart_rx_proc : process(refclk_in) is 
    begin
        if rising_edge (refclk_in) then
            uart_rx_prev <= uart_rx;
            if reset_in = '1' then
                uart_rx_valid_out   <= '0';
                state <= RESET;
            else
                div_count <= div_count + 1;
                sample_strobe <= '0'; -- default
                case(state) is 
                    when RESET => 
                        div_count <= 0;
                        state <= WAIT_FOR_START_BIT;
                        uart_rx_error <= '0'; -- clear error status
                    
                    -- wait for a falling edge on the RX line that signifies the start of the start bit      
                    when WAIT_FOR_START_BIT => 
                        if uart_rx_prev = '1' and uart_rx = '0' then -- if falling edge
                            div_count <= 0; 
                            state <= START_BIT;
                        end if;    
                    
                    -- 
                    when START_BIT => 
                        if div_count = SAMPLE_POINT then -- sample at middle of bit_period 
                            sample_strobe <= '1'; 
                            if uart_rx = '1' then -- not a true start bit
                                uart_rx_error <= '1';
                                state <= WAIT_FOR_START_BIT;
                            end if;
                        end if;
                        if div_count = DIVISOR then -- at end of bit_period 
                            state <= RECEIVE_DATA;
                            div_count <= 0;
                            bit_count <= 0;
                            rec_byte_shift <= x"00";
                        end if;
                    
                    -- shift the data in at the middle of the bit period      
                    when RECEIVE_DATA => 
                        
                        if div_count = SAMPLE_POINT then -- sample at middle of bit_period 
                            sample_strobe <= '1'; 
                            rec_byte_shift( 7 downto 0) <= uart_rx & rec_byte_shift(7 downto 1);    -- LSB first, so shift rx into the top
                        end if;
                        if div_count = DIVISOR then -- at end of bit_period 
                            bit_count <= bit_count + 1;
                            div_count <= 0;
                            if bit_count = 8-1 then -- if this is the end of the final data bit
                                byte_received_out <= rec_byte_shift;
                                uart_rx_valid_out <= '1';
                                state <= STOP_BIT;
                            end if;
                        end if;
                    
                    -- use the stop bit time to clock the received byte out
                    when STOP_BIT => 
                        if uart_rx_ready_in = '1' then 
                            uart_rx_valid_out <= '0';
                        end if;
                        
                        state <= WAIT_FOR_START_BIT;                     
                        
                        -- TODO: Add "uart rx overflow error" check here by checking for next "start bit" trigger before old byte is accepted                          
                    
                    when others => 
                        state <= RESET;
                end case;            
             end if;  
        end if;     
    end process uart_rx_proc;
    
    

end rtl;
