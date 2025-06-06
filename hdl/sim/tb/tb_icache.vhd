library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_icache is
    generic (runner_cfg : string);
end entity tb_icache;

architecture RTL of tb_icache is
	constant G_NUM_BLOCKS : integer := 16;
	constant G_BLOCK_SIZE : integer := 32; -- bytes
	constant G_SET_SIZE : integer := 2; -- 1=direct mapped 2+ = set associativity
	constant G_RV32C_OPT : boolean := true;
    signal clk : std_logic := '0';
	signal rst : std_logic := '1';
	signal in_addr : std_logic_vector(31 downto 0);
	signal in_addr_valid : std_logic;
	signal out_instr : std_logic_vector(31 downto 0);
	signal out_instr_valid : std_logic;
	signal in_invalidate : std_logic_vector(G_NUM_BLOCKS-1 downto 0);
	signal wb_mosi : t_wb_mosi;
	signal wb_miso : t_wb_miso;
	signal out_addr_ready : std_logic;
	
    
begin

    clk <= not clk after 5 ns;
    rst <= '0' after 100 ns;

    stim_proc : process is
        procedure read_instr(addr : integer) is            
            variable v_addr : std_logic_vector(31 downto 0) := uint2slv(addr);
            variable v_addr_next : std_logic_vector(31 downto 0) := uint2slv(addr+2); -- byte addressed, 16-bit aligned
            variable expected : std_logic_vector(31 downto 0);
            
        begin
            msg("Read Instruction at Address " & to_string(addr) & " (0x" & to_hstring(uint2slv(addr)) & ")");
            in_addr <= v_addr;
            in_addr_valid <= '1';
            wait until rising_edge(clk);
            in_addr_valid <= '0';
            if out_instr_valid = '0' then
                wait until out_instr_valid = '1' and rising_edge(clk);
            end if;

            -- rdata is halfword address
            -- eg 0x0 => 0x0001_0000 
            --    0x2 => 0x0002_0001 
            --    0x4 => 0x0003_0002
            --    0x6 => 0x0004_0003
            --    0x8 => 0x0005_0004
            expected(15 downto 0) := uint2slv(addr/2, 16);
            expected(31 downto 16) := uint2slv((addr/2)+1, 16);

            assert out_instr = expected report "Expected " & to_hstring(expected) & " Got " & to_hstring(out_instr) severity error;
            if out_instr = expected then
                msg("OK");
            end if;


        end procedure read_instr;
    begin
        test_runner_setup(runner, runner_cfg);
        info("Vunit is alive!");
        show(get_logger(default_checker), display_handler, pass);

        info("G_NUM_BLOCKS = " & to_string(G_NUM_BLOCKS));
        info("G_BLOCK_SIZE = " & to_string(G_BLOCK_SIZE));
        info("G_SET_SIZE   = " & to_string(G_SET_SIZE));
        
        
        wait for 150 ns;
        msg("=== Test basic 32-bit aligned cache misses, hits and block replacement ===");
        read_instr(0);
        read_instr(4);
        read_instr(8);
        read_instr(12);
        read_instr(40);
        read_instr(1024);
        read_instr(2060);

        msg("=== Test 16-bit aligned ===");
        read_instr(2062);
        read_instr(28);
        read_instr(30);
        read_instr(32);

        msg("=== Test 16-bit aligned with both halves misses ===");
        read_instr(1024+32+30);

        msg("=== Test cache invalidate ===");
        for i in 0 to 100 loop
            read_instr(2*i);
        end loop;
        msg("INVALIDATE");
        in_invalidate <= (others => '1');
        wait until rising_edge(clk);
        in_invalidate <= (others => '0');
        for i in 0 to 100 loop
            read_instr(2*i);
        end loop;

        msg("=== Test cache disable by holding INVALIDATE high ===");
        in_invalidate <= (others => '1');
        for i in 0 to 100 loop
            read_instr(2*i);
        end loop;
        in_invalidate <= (others => '0');
        
        msg("=== Test back-to-back requests with backpressure ====");
        wait until rising_edge(clk);
        in_addr_valid <= '1';
        in_addr <= x"0000_0000";
        wait until rising_edge(clk) and out_addr_ready = '1';
        in_addr <= x"0000_0002";
        wait until rising_edge(clk) and out_addr_ready = '1';
        in_addr <= x"0000_0004";
        wait until rising_edge(clk) and out_addr_ready = '1';
        in_addr <= x"0000_0006";
        wait until rising_edge(clk) and out_addr_ready = '1';
        in_addr <= x"0000_0008";
        wait until rising_edge(clk) and out_addr_ready = '1';
        in_addr_valid <= '0';
        msg("All tests done");
        wait for 100 ns;
        test_runner_cleanup(runner);
        wait;
    end process;


dut_icache : entity work.icache
    generic map(
        G_DBG_LOG => true,
        G_RV32C_OPT => G_RV32C_OPT,
        G_NUM_BLOCKS => G_NUM_BLOCKS,
        G_BLOCK_SIZE => G_BLOCK_SIZE,
        G_SET_SIZE   => G_SET_SIZE
    )
    port map(
        clk             => clk,
        rst             => rst,
        in_addr         => in_addr,
        in_addr_valid   => in_addr_valid,
        out_addr_ready  => out_addr_ready,
        out_instr       => out_instr,
        out_instr_valid => out_instr_valid,
        in_invalidate   => in_invalidate,
        wb_mosi         => wb_mosi,
        wb_miso         => wb_miso
    );


ro_mem_inst : entity work.sim_wb_ro_mem
    port map(
        clk     => clk,
        wb_mosi => wb_mosi,
        wb_miso => wb_miso
    );



end architecture RTL;
