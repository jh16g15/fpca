
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_psram_aps6404_streaming_ctrl is
  generic (
    runner_cfg : string
  );
end;

architecture bench of tb_psram_aps6404_streaming_ctrl is
  -- Clock period
  constant clk_period : time := 40 ns;
  -- Generics
  constant MEM_CTRL_CLK_FREQ_KHZ : integer := 25000;
  constant BURST_LENGTH_BYTES : integer := 4;
  -- Ports
  signal mem_ctrl_clk : std_logic := '0';
  signal reset : std_logic := '1';
  signal cmd_valid : std_logic;
  signal cmd_ready : std_logic;
  signal cmd_address_in : std_logic_vector(22 downto 0);
  signal cmd_wdata_in : std_logic_vector(7 downto 0);
  signal cmd_we_in : std_logic;
  signal rsp_valid : std_logic;
  signal rsp_rdata_out : std_logic_vector(7 downto 0);
  signal psram_clk : std_logic;
  signal psram_cs_n : std_logic;
  signal psram_sio : std_logic_vector(3 downto 0);
begin

    reset <= '0' after 100 ns;

  main : process

    procedure psram_byte_write(byte_address : in integer; wdata : in std_logic_vector(7 downto 0)) is
    begin
        info("Start PSRAM write of 0x" & to_hstring(wdata) & " to byte address " & to_string(byte_address));
        cmd_valid <= '1';
        cmd_address_in <= std_logic_vector(to_unsigned(byte_address, 23));
        cmd_wdata_in <= wdata;
        cmd_we_in <= '1';
        wait until cmd_ready = '1' and rising_edge(mem_ctrl_clk);
        cmd_valid <= '0';
        wait until rsp_valid = '1';
        info("PSRAM write done");
    end procedure;

    procedure psram_byte_check(byte_address : in integer; exp_rdata : in std_logic_vector(7 downto 0)) is
    begin
        info("Start PSRAM read of byte address " & to_string(byte_address));
        cmd_valid <= '1';
        cmd_address_in <= std_logic_vector(to_unsigned(byte_address, 23));
        cmd_we_in <= '0';
        wait until cmd_ready = '1' and rising_edge(mem_ctrl_clk);
        cmd_valid <= '0';
        wait until rsp_valid = '1' and rising_edge(mem_ctrl_clk);
        check_equal(rsp_rdata_out, exp_rdata);
        info("PSRAM read done");
    end procedure;

    -- trims 2 cycles (6 min per byte instead of 8)
    procedure psram_byte_write_non_blocking(byte_address : in integer; wdata : in std_logic_vector(7 downto 0)) is
    begin
        info("Start PSRAM write of 0x" & to_hstring(wdata) & " to byte address " & to_string(byte_address));
        cmd_valid <= '1';
        cmd_address_in <= std_logic_vector(to_unsigned(byte_address, 23));
        cmd_wdata_in <= wdata;
        cmd_we_in <= '1';
        wait until cmd_ready = '1' and rising_edge(mem_ctrl_clk);
        cmd_valid <= '0';
        info("PSRAM non-blocking write issued");
    end procedure;

begin
    test_runner_setup(runner, runner_cfg);
    while test_suite loop
        if run("test_alive") then
            info("Hello world test_alive");
            show(get_logger("check"), display_handler, pass);

            wait for 10 * clk_period;
            psram_byte_write(0, x"78");
            -- check a little burst too
            psram_byte_write(1024, x"11");
            psram_byte_write(1025, x"22");

            -- verify written data
            psram_byte_check(0, x"78");
            psram_byte_check(1024, x"11");
            psram_byte_check(1025, x"22");

            -- check internal burst timeout deasserts CSn

            warning("long wait");
            wait for 9 us;

            -- check_equal(psram_cs_n, '1', "Check deassert CSn after max burst timeout");



            info("longer 32b burst");

            psram_byte_write(100, x"12");
            psram_byte_write(101, x"34");
            psram_byte_write(102, x"56");
            psram_byte_write(103, x"78");

            psram_byte_check(100, x"12");
            psram_byte_check(101, x"34");
            psram_byte_check(102, x"56");
            psram_byte_check(103, x"78");

            info("test long burst split into multiple smaller bursts");
            for i in 0 to 63 loop
                psram_byte_write(i, std_logic_vector(to_unsigned(i, 8)));
            end loop;
                for i in 0 to 63 loop
                    psram_byte_check(i, std_logic_vector(to_unsigned(i, 8)));
                end loop;

            wait for 10 * clk_period;

            info("test non blocking burst (as if from FIFO/DMA)");
            for i in 0 to 31 loop
                psram_byte_write_non_blocking(i+100, not std_logic_vector(to_unsigned(i, 8)));
            end loop;
            for i in 0 to 31 loop
                psram_byte_check(i+100, not std_logic_vector(to_unsigned(i, 8)));
            end loop;
            test_runner_cleanup(runner);

        end if;
    end loop;
end process main;

test_runner_watchdog(runner, 5 ms);

psram_aps6404_streaming_ctrl_inst : entity work.psram_aps6404_streaming_ctrl
generic map (
  MEM_CTRL_CLK_FREQ_KHZ => MEM_CTRL_CLK_FREQ_KHZ
)
port map (
  mem_ctrl_clk => mem_ctrl_clk,
  reset => reset,
  cmd_valid => cmd_valid,
  cmd_ready => cmd_ready,
  cmd_address_in => cmd_address_in,
  cmd_wdata_in => cmd_wdata_in,
  cmd_we_in => cmd_we_in,
  rsp_valid => rsp_valid,
  rsp_rdata_out => rsp_rdata_out,
  psram_clk => psram_clk,
  psram_cs_n => psram_cs_n,
  psram_sio => psram_sio
);

sim_psram_aps6404_inst : entity work.sim_psram_aps6404
        generic
        map (
        G_MEM_BYTES => 8
        )
        port
        map (
        psram_clk  => psram_clk,
        psram_cs_n => psram_cs_n,
        psram_sio  => psram_sio
        );

    mem_ctrl_clk <= not mem_ctrl_clk after clk_period/2;

end;