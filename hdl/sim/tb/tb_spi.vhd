library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_spi is
    generic (runner_cfg : string);
end tb_spi;

architecture tb of tb_spi is
    signal clk : STD_LOGIC := '0';
    signal spi_sck_throttle : STD_LOGIC_VECTOR (7 downto 0) := x"00";
    signal byte_in : STD_LOGIC_VECTOR (7 downto 0);  -- wdata
    signal strb_in : STD_LOGIC;
--    signal we_in : STD_LOGIC;
    signal stall_out :STD_LOGIC;
    signal byte_out :STD_LOGIC_VECTOR (7 downto 0); -- rdata
    signal strb_out :STD_LOGIC;
    signal s_byte_out :STD_LOGIC_VECTOR (7 downto 0); -- rdata
    signal s_strb_out :STD_LOGIC;
    signal sck : STD_LOGIC;
    signal cs_n : STD_LOGIC;
    signal mosi : STD_LOGIC;
    signal miso : STD_LOGIC;
begin

    clk <= not clk after 10 ns;

    tb_proc : process is
    begin
        test_runner_setup(runner, runner_cfg);
        show(get_logger(default_checker), display_handler, pass);
        -- init
        spi_sck_throttle <= x"00"; -- no throttling
        cs_n <= '1';
        strb_in <= '0';
        wait for 40 ns;
        cs_n <= '0';
        wait for 20 ns;
        byte_in <= x"85";
        strb_in <= '1';
        wait for 0 ns;
        report "MSPI Sending " & to_hstring(byte_in);
        wait for 20 ns;
        strb_in <= '0';

        wait until rising_edge(strb_out);
        report "MSPI Received " & to_hstring(byte_out);
        assert byte_out = x"5A" report "Data Error";

--        wait until stall_out = '0';
        spi_sck_throttle <= x"01"; -- 1 cycle throttle (half speed)
        byte_in <= x"BE";
        strb_in <= '1';
        wait for 0 ns;
        report "MSPI Sending " & to_hstring(byte_in);
        wait for 20 ns;
        strb_in <= '0';

        wait until rising_edge(strb_out);
        report "MSPI Received " & to_hstring(byte_out);
        assert byte_out = x"85" report "Data Error";
        -- cleanup
        cs_n <= '1';
        test_runner_cleanup(runner);
        wait;
    end process;

    u_mspi : entity work.simple_mspi
    port map(
        clk => clk,
        sck_throttle_in => spi_sck_throttle,
        byte_in => byte_in,
        strb_in => strb_in,
        stall_out => stall_out,
        byte_out => byte_out,
        strb_out => strb_out,
        sck_out => sck,
        mosi_out => mosi,
        miso_in => miso
    );

    u_sspi : entity work.sim_sspi
    port map(
        byte_in => x"5A",
--        strb_in => strb_in,
--        stall_out => stall_out,
        byte_out => s_byte_out,
        strb_out => s_strb_out,
        cs_n_in => cs_n,
        sck_in => sck,
        mosi_in => mosi,
        miso_out => miso
    );

end tb;
