library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aps6404_init_pkg.all;

-- for ODDR
Library UNISIM;
use UNISIM.vcomponents.all;

entity qspi_oversample is
    generic (
        OVERSAMPLE_KHZ : integer := 200_000;
        SPI_KHZ : integer := 20_000
    );
    port (
        oversample_clk : in std_logic;    -- 200MHz?
        oversample_rst : in std_logic;

        init_done_out : out std_logic;

        -- qspi_clk_in : in std_logic; -- from same MMCM as oversample clock, only used for clock forwarding

        qspi_clk_out : out std_logic;
        qspi_csn : out std_logic;
        qspi_sio : inout std_logic_vector(3 downto 0)
        
    );
end entity qspi_oversample;

architecture rtl of qspi_oversample is

    -- NOTE: this is how we force placement into IOB registers
    -- attribute IOB : string;
    -- attribute IOB of <port_name>: signal is "TRUE";

    constant OSAMPLE_CLKS_PER_SPI : integer := OVERSAMPLE_KHZ / SPI_KHZ;

    -- signal qspi_clk_en : std_logic := '0';
    -- signal qspi_clk : std_logic; -- internal

    constant SIO_OUTPUT_EN_INIT : std_logic_vector(3 downto 0) := b"1111";  -- set all to output
    constant SIO_OUTPUT_EN_WRITE : std_logic_vector(3 downto 0) := b"1111"; -- set all to output
    constant SIO_OUTPUT_EN_READ : std_logic_vector(3 downto 0) := b"0000";  -- set all to input

    -- constant CMD_ENTER_QUAD : std_logic_vector(7 downto 0) := x"35";
    constant CMD_FAST_QUAD_READ : std_logic_vector(7 downto 0) := x"EB";
    constant CMD_QUAD_WRITE : std_logic_vector(7 downto 0) := x"38";

    signal sio_output_en : std_logic_vector(3 downto 0) := SIO_OUTPUT_EN_READ;
    signal sio_input : std_logic_vector(3 downto 0);
    signal sio_output : std_logic_vector(3 downto 0);
    
    -- signal sio_output_dly : std_logic_vector(3 downto 0);   -- one oversample clk later than CSn
    -- signal qspi_clk_en_dly : std_logic := '0';  -- one oversample clk later than CSn (in line with data)

    type t_state is (RESET, INIT, INIT_DONE, SEND_BYTE);
    signal state : t_state := INIT;
 
    signal spi_tick : std_logic := '0'; -- tick when there is a rising or falling edge of spi_clk

    signal spi_tick_counter : integer range 0 to C_APS6404_INIT_TICKS := 0;
    signal os_tick_counter : integer range 0 to 1024 := 0;

    signal await_rdata : std_logic := '0';

    attribute mark_debug : boolean;
    attribute mark_debug of sio_output_en : signal is true;
    attribute mark_debug of sio_input : signal is true;
    attribute mark_debug of sio_output : signal is true;
    attribute mark_debug of spi_tick : signal is true;
    attribute mark_debug of state : signal is true;
    attribute mark_debug of spi_tick_counter : signal is true;
    attribute mark_debug of qspi_clk_out : signal is true;
    attribute mark_debug of qspi_csn : signal is true;
    

begin

    -- OUTPUT PROCESS
    process (oversample_clk)
    begin
        if rising_edge(oversample_clk) then
            -- delay by one osample clk to ensure that CSn is asserted first
            -- sio_output_dly <= sio_output;
            -- qspi_clk_en_dly <= qspi_clk_en;

            if oversample_rst = '1' then
                state <= RESET;
                qspi_csn <= '1';
                init_done_out <= '0';

            else
                if spi_tick = '1' then 
                    spi_tick_counter <= spi_tick_counter + 1;
                end if;

                case state is
                    when RESET =>
                        spi_tick_counter <= 0;

                        state <= INIT;
                        sio_output_en <= SIO_OUTPUT_EN_INIT;
                    when INIT => -- Clock through APS6404 init sequence (from package)
                        if spi_tick = '1' then
                            -- info(to_string(spi_tick_counter) & ": " & to_string(C_APS6404_INIT_ARR(spi_tick_counter)));
                            qspi_csn <= C_APS6404_INIT_ARR(spi_tick_counter)(6);
                            qspi_clk_out <= C_APS6404_INIT_ARR(spi_tick_counter)(5);
                            sio_output_en <= (others => C_APS6404_INIT_ARR(spi_tick_counter)(4));
                            sio_output <= C_APS6404_INIT_ARR(spi_tick_counter)(3 downto 0);
                            if spi_tick_counter = C_APS6404_INIT_TICKS-1 then
                                state <= INIT_DONE;
                                
                            end if;
                        end if;
                    when INIT_DONE =>
                            init_done_out <= '1';
                    when others => null;
                        
                end case;
            end if;
        end if;
    end process;

    -- SPI "tick" clock enable
    process (oversample_clk)
    begin
        if rising_edge(oversample_clk) then
            -- defaults
            spi_tick <= '0';
            os_tick_counter <= os_tick_counter + 1;
            if os_tick_counter = OSAMPLE_CLKS_PER_SPI-1 then 
                os_tick_counter <= 0;
                spi_tick <= '1';
            end if;
        end if;
    end process;

    -- infer combinational IOBUFs here
    sio_input <= qspi_sio;
    process (all)
    begin
        for i in 0 to 3 loop
            qspi_sio(i) <= sio_output(i) when sio_output_en(i) = '1' else 'Z';
        end loop;
    end process;
    
--     -- for proper clock forwarding from an actual clock
--     ODDR_inst : ODDR
--    generic map(
--       DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE" 
--       INIT => '0',   -- Initial value for Q port ('1' or '0')
--       SRTYPE => "SYNC") -- Reset Type ("ASYNC" or "SYNC")
--    port map (
--       Q => qspi_clk_out,   -- 1-bit DDR output
--       C => qspi_clk_in,    -- 1-bit clock input
--       CE => qspi_clk_en,  -- 1-bit clock enable input
--       D1 => '1',  -- 1-bit data input (positive edge)       Consider having this be our clock enable so we idle low properly
--       D2 => '0',  -- 1-bit data input (negative edge)
--       R => '0',    -- 1-bit reset input
--       S => '0'     -- 1-bit set input
--    );
     


end architecture;
