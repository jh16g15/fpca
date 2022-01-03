

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity basys3_simple_soc_wrapper is
    port (
        clk   : in std_logic;   --! 100MHz
        
        btnC : in std_logic;
        btnU : in std_logic;
        btnL : in std_logic;
        btnR : in std_logic;
        btnD : in std_logic;

        sw : in std_logic_vector(15 downto 0);
        led : out std_logic_vector(15 downto 0);
        
        seg : out std_logic_vector(6 downto 0);
        dp : out std_logic;
        an : out std_logic_vector(3 downto 0)
        
        

    );
end entity basys3_simple_soc_wrapper;

architecture rtl of basys3_simple_soc_wrapper is

    -- run location: fpca/boards/basys3/fpca
    constant G_MEM_INIT_FILE : string := "../../../software/build/blinky.hex"; -- from toolchain
    signal gpio_led          : std_logic_vector(31 downto 0);
    signal gpio_sw           : std_logic_vector(31 downto 0);
    signal gpio_btn          : std_logic_vector(31 downto 0);
    
    signal reset : std_logic;
    
    constant DIV_RATE : integer := 22;
    
    -- div by 2**24, or about 8 million ish    
    -- 21 for simple blinky
    -- 19 for blinky + counting 7 seg
    
    -- div by 2 for 50MHz (should meet timing)
    signal clk_div_counter : unsigned(DIV_RATE-3 downto 0) := (others => '0');
    signal slow_clk : std_logic;
    
    signal sseg_ca : std_logic_vector(7 downto 0);
    signal sseg_an : std_logic_vector(3 downto 0);
        
begin

    -- TODO: replace with MMCM (or just time the code properly)
    simple_clk_div : process(clk) is
    begin
        if rising_edge(clk) then
            clk_div_counter <= clk_div_counter + 1;
        end if;
    end process;
    
    slow_clk <= clk_div_counter(clk_div_counter'left);    

    reset <= btnC;
    led                   <= gpio_led(15 downto 0);

    gpio_btn(31 downto 4) <= (others => '0');
    gpio_btn(3 downto 0)  <= (btnU, btnL, btnR, btnD);
    
    gpio_sw(31 downto 16) <= (others => '0');  
    gpio_sw(15 downto 0) <= sw;
    
    seg <= sseg_ca(6 downto 0);
    dp <= sseg_ca(7);
    
    an <= sseg_an;

    simple_soc_inst : entity work.simple_soc
        generic map(
            G_MEM_INIT_FILE => G_MEM_INIT_FILE,
            G_SOC_FREQ => 100_000_000 / (2**DIV_RATE)       -- for seven seg
        )
        port map(
            clk          => slow_clk,
--            clk          => clk,
            reset        => reset,
            gpio_led_out => gpio_led,
            gpio_btn_in  => gpio_btn,
            gpio_sw_in   => gpio_sw,
            sseg_ca_out => sseg_ca,
            sseg_an_out => sseg_an            
        );

end architecture;