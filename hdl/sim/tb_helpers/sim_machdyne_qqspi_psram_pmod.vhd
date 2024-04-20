library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Simulation model of the Machdyne LD-QQSPI-PSRAM32 32MB PSRAM Module
--! 4 APS6404 PSRAM chips are simulated
entity sim_machdyne_qqspi_psram_pmod is
    port
    (
        sclk : in std_logic; --! Serial Clock
        ss_n : in std_logic; --! Active Low Slave Select
        sio  : inout std_logic_vector(3 downto 0); --! Serial IO
        cs   : in std_logic_vector(1 downto 0) --! Chip Select
    );
end entity sim_machdyne_qqspi_psram_pmod;

architecture rtl of sim_machdyne_qqspi_psram_pmod is
    constant C_DECODER_DELAY : time := 33 ns; -- max Tpd for 2V supply for worst-case operation (we are powering from 3V3, but 4V5 (12 ns) is the next value given)
    signal csn_decoder_next : std_logic_vector(3 downto 0);
    signal csn_decoder_out : std_logic_vector(3 downto 0);
    
begin

    process (all)
    begin
        if ss_n = '1' then  -- Slave Select deasserted
            csn_decoder_next <= "1111"; -- No PSRAMs selected
        else
            case cs is
                when "00" => csn_decoder_next <= "1110"; -- PSRAM0 selected
                when "01" => csn_decoder_next <= "1101"; -- PSRAM1 selected
                when "10" => csn_decoder_next <= "1011"; -- PSRAM2 selected
                when "11" => csn_decoder_next <= "0111"; -- PSRAM3 selected
                when others => csn_decoder_next <= "1111"; -- invalid
            end case;
        end if;
    end process;
    csn_decoder_out <= transport csn_decoder_next after C_DECODER_DELAY;    -- model some level of propagation delay, important at higher clock speeds


    gen_psram : for i in 0 to 3 generate
        constant name : string := "psram" & to_string(i);
    begin
        sim_psram_aps6404_inst : entity work.sim_psram_aps6404
        generic map (
            G_NAME => name
        )
        port map (
            psram_clk => sclk,
            psram_cs_n => csn_decoder_out(i),
            psram_sio => sio
        );

    end generate;

end architecture;