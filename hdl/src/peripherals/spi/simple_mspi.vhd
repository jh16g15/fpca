-- Simple SPI Master. Designed to be software controlled, so only transfers a single byte at a time.
-- Uses Mode 0 SPI. Positive Pulse, latch then shift
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity simple_mspi is
    Port ( clk : in STD_LOGIC;
           byte_in : in STD_LOGIC_VECTOR (7 downto 0);  -- wdata
           strb_in : in STD_LOGIC;
--           we_in : in STD_LOGIC;
           stall_out : out STD_LOGIC := '0';
           byte_out : out STD_LOGIC_VECTOR (7 downto 0); -- rdata
           strb_out : out STD_LOGIC;
           sck_out : out STD_LOGIC := '0';
--           cs_n_out : out STD_LOGIC;
           mosi_out : out STD_LOGIC;
           miso_in : in STD_LOGIC);
end simple_mspi;

architecture Behavioral of simple_mspi is
    signal count : integer range 0 to 7 := 0;
    signal shift_reg : std_logic_vector(7 downto 0);
    
    type t_state is (IDLE, START, LATCH, SHIFT);
    signal state : t_state := IDLE;
begin

    spi_proc : process(clk) is
    begin
        strb_out <= '0';
        if rising_edge(clk) then
            case state is
            when IDLE => 
                if strb_in = '1' then
                    state <= START;
                    shift_reg <= byte_in; -- store the byte to send
                    sck_out <= '0';
                    stall_out <= '1';
                end if;         
            when START => 
                -- set up the MSB on the bus ready for transaction to start
                mosi_out <= shift_reg(7);
                state <= LATCH;
                count <= 0;
            -- note: this could be reorganised a little to make more sense!
            when LATCH =>
                -- latch in INPUT bit from the outside world on the rising edge of SCK (which signals the slave to read it's first bit
                sck_out <= '1';
                shift_reg(7 downto 0) <= shift_reg(6 downto 0) & miso_in;
                state <= SHIFT;
            when SHIFT =>
                -- 'shift' out to expose the next most significant bit to the bus, on the falling edge of SCK (which signals the slave to send it's next bit)
                sck_out <= '0';
                mosi_out <= shift_reg(7);
                state <= LATCH;
                count <= count + 1;
                if count = 7 then
                    state <= IDLE;
                    byte_out <= shift_reg(7 downto 0);
                    strb_out <= '1'; -- one cycle pulse
                    stall_out <= '0';
                end if;         
            end case;     
        end if;     
    end process;

end Behavioral;
