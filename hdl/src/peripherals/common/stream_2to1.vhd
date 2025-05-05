library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! A simple streamed data downsizer with backpressure
--! Requires G_IN_W = 2*G_OUT_W
entity stream_2to1 is
    generic (
        G_IN_W : integer := 32;
        G_OUT_W : integer := 16;
        G_HALF_SEND_FIRST : string := "top" -- top half first (MSB)
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;

        data_in : in std_logic_vector(G_IN_W-1 downto 0);
        data_in_valid : in std_logic;
        data_in_ready : out std_logic;

        data_out : out std_logic_vector(G_OUT_W-1 downto 0);
        data_out_valid : out std_logic;
        data_out_ready : in std_logic
    );
end entity stream_2to1;

architecture rtl of stream_2to1 is
    signal internal_store : std_logic_vector(G_IN_W-1 downto 0);
    signal store_valid : std_logic;

    constant UPPER_L : integer := G_OUT_W;
    constant LOWER_H : integer := G_OUT_W-1;


    signal half_stage : std_logic;

    type t_state is (LOAD, OUTPUT_HALF);
    signal state : t_state;
begin

    -- Implementation Plan:
    -- Input G_IN_W register
    -- Output G_OUT_W register (optional?)
    gen_output : if G_HALF_SEND_FIRST = "top" generate
        data_out <= internal_store(G_IN_W-1 downto UPPER_L) when state = LOAD else  -- upper half
            internal_store(LOWER_H downto 0);   --lower half
    else generate
        data_out <= internal_store(LOWER_H downto 0) when state = LOAD else  -- lower half
            internal_store(G_IN_W-1 downto UPPER_L);   --upper half
    end generate;

    -- TODO use control signals (ie set output valid, input ready)

    data_out_valid <= store_valid;

    process(all) is
    begin
        case(state) is
            when LOAD =>
                data_in_ready <= data_out_ready;

            when OUTPUT_HALF =>
                data_in_ready <= '0';
        end case;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- set control signals
                -- data_out_valid <= '0';
                -- data_in_ready <= '1';

                state <= LOAD;

            else
                if data_out_ready = '1' then    -- stall if not ready for output data
                    case(state) is
                        when LOAD =>
                        internal_store <= data_in;
                        store_valid <= data_in_valid;
                        state <= OUTPUT_HALF;

                        when OUTPUT_HALF =>
                        state <= LOAD;

                    end case;
                end if;


            end if;
        end if;
    end process;



end architecture;
