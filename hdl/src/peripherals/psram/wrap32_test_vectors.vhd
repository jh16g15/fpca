library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! Synthesisable PSRAM Controller test
entity wrap32_test_vectors is
    generic
    (
        G_BURST_LEN   : integer range 4 to 32 := 4;
        G_FREQ_KHZ    : integer               := 100_000;
        G_SIM         : boolean               := false;
        G_TEST_LENGTH : integer               := 100 -- number of bursts to check
    );
    port
    (
        clk   : in std_logic;
        reset : in std_logic;

        test_pass : out std_logic;
        test_fail : out std_logic;

        -- PSRAM IO
        psram_sel  : out std_logic_vector(1 downto 0); -- which PSRAM chip to select
        psram_clk  : out std_logic;
        psram_cs_n : out std_logic;
        psram_sio  : inout std_logic_vector(3 downto 0)
    );
end entity wrap32_test_vectors;

architecture rtl of wrap32_test_vectors is

    constant C_ADDR_INCREMENT : unsigned(24 downto 0) := to_unsigned(G_BURST_LEN, 25);

    -- Controller Control Signals
    signal cmd_valid : std_logic;
    signal cmd_ready : std_logic;
    signal cmd_address_in : std_logic_vector(24 downto 0);
    signal cmd_we_in : std_logic;
    signal cmd_wdata_in : std_logic_vector(G_BURST_LEN*8-1 downto 0) := (others => '0');
    signal rsp_valid : std_logic;
    signal rsp_rdata_out : std_logic_vector(G_BURST_LEN*8-1 downto 0);

    signal write_address_under_test : unsigned(24 downto 0) := to_unsigned(0, 25);
    signal read_address_under_test  : unsigned(24 downto 0) := to_unsigned(0, 25);

    signal write_test_count : integer := 0;
    signal read_test_count  : integer := 0;

    type t_state is (S_RESET, S_WRITE, S_WRITE_WAIT, S_READ, S_READ_WAIT, S_PASS, S_FAIL);
    signal state : t_state := S_RESET;

    signal w_lfsr_next : std_logic;
    signal w_lfsr_data : std_logic_vector(31 downto 0);
    signal r_lfsr_next : std_logic;
    signal r_lfsr_data : std_logic_vector(31 downto 0);


begin

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= S_RESET;
            else
                -- defaults
                w_lfsr_next <= '0';
                r_lfsr_next <= '0';
                case state is
                    when S_RESET                        =>
                        write_address_under_test <= (others => '0');
                        read_address_under_test  <= (others => '0');
                        write_test_count         <= 0;
                        read_test_count          <= 0;
                        state                    <= S_WRITE;
                        test_pass <= '0';
                        test_fail <= '0';
                    when S_WRITE =>
                        cmd_valid <= '1';
                        cmd_we_in <= '1';
                        cmd_address_in <= std_logic_vector(write_address_under_test);
                        cmd_wdata_in <= w_lfsr_data;
                        if cmd_valid and cmd_ready then -- cmd accepted
                            cmd_valid <= '0';                            
                            state <= S_WRITE_WAIT;
                        end if;

                    when S_WRITE_WAIT => 
                        if rsp_valid then
                            -- setup next transaction
                            w_lfsr_next <= '1'; -- one cycle pulse
                            write_test_count <= write_test_count + 1;
                            write_address_under_test <= write_address_under_test + C_ADDR_INCREMENT;
                            if write_test_count = G_TEST_LENGTH-1 then
                                state <= S_READ;
                            else
                                state <= S_WRITE;
                            end if;
                        end if;
                    when S_READ =>
                        cmd_valid <= '1';
                        cmd_we_in <= '0';
                        cmd_address_in <= std_logic_vector(read_address_under_test);
                        if cmd_valid and cmd_ready then -- cmd accepted
                            cmd_valid <= '0';                            
                            state <= S_READ_WAIT;
                        end if;

                    when S_READ_WAIT => 
                        if rsp_valid then
                            if read_test_count = G_TEST_LENGTH-1 then
                                state <= S_PASS;
                                test_pass <= '1';
                            else
                                state <= S_READ;
                            end if;
                            report "Got " & to_hstring(rsp_rdata_out);
                            assert rsp_rdata_out = r_lfsr_data 
                                report "Got " & to_hstring(rsp_rdata_out) & " Expected " & to_hstring(r_lfsr_data)
                                severity error;
                            if rsp_rdata_out /= r_lfsr_data then
                                test_fail <= '1';
                                state <= S_FAIL;
                            end if;
                            
                            -- setup next transaction
                            r_lfsr_next <= '1'; -- one cycle pulse
                            read_test_count <= read_test_count + 1;
                            read_address_under_test <= read_address_under_test + C_ADDR_INCREMENT;
                        end if;
                        
                    when S_PASS =>
                        null;
                    when S_FAIL =>
                        null;
                    when others =>
                        null;
                end case;

            end if;
        end if;

    end process;

    w_lfsr32_inst : entity work.lfsr32
        port map
        (
            clk   => clk,
            reset => reset,
            en    => w_lfsr_next,
            dout  => w_lfsr_data
        );
    r_lfsr32_inst : entity work.lfsr32
        port map
        (
            clk   => clk,
            reset => reset,
            en    => r_lfsr_next,
            dout  => r_lfsr_data
        );

    psram_aps6404_ctrl_wrap32_inst : entity work.psram_aps6404_ctrl_wrap32
        generic
        map (
        G_BURST_LEN => G_BURST_LEN,
        G_FREQ_KHZ  => G_FREQ_KHZ,
        G_SIM       => G_SIM
        )
        port
        map
        (
        clk            => clk,
        reset          => reset,
        cmd_valid      => cmd_valid,
        cmd_ready      => cmd_ready,
        cmd_address_in => cmd_address_in,
        cmd_we_in      => cmd_we_in,
        cmd_wdata_in   => cmd_wdata_in,
        rsp_valid      => rsp_valid,
        rsp_rdata_out  => rsp_rdata_out,
        psram_sel      => psram_sel,
        psram_clk      => psram_clk,
        psram_cs_n     => psram_cs_n,
        psram_sio      => psram_sio
        );
end architecture;