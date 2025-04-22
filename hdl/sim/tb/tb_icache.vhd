library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

entity tb_icache is
end entity tb_icache;

architecture RTL of tb_icache is
	constant G_NUM_BLOCKS : integer := 16;
	constant G_BLOCK_SIZE : integer := 32; -- bytes
	constant G_SET_SIZE : integer := 1; -- direct mapped
	signal clk : std_logic := '0';
	signal rst : std_logic := '1';
	signal in_addr : std_logic_vector(31 downto 0);
	signal in_addr_valid : std_logic;
	signal out_instr : std_logic_vector(31 downto 0);
	signal out_instr_valid : std_logic;
	signal in_invalidate : std_logic_vector(G_NUM_BLOCKS-1 downto 0);
	signal wb_mosi : t_wb_mosi;
	signal wb_miso : t_wb_miso;
    
begin

    clk <= not clk after 5 ns;
    rst <= '0' after 100 ns;

    stim_proc : process is
        procedure read_instr(addr : integer) is            
            variable v_addr : std_logic_vector(31 downto 0) := uint2slv(addr);
            variable v_addr_next : std_logic_vector(31 downto 0) := uint2slv(addr+1);
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
            -- if 32-bit aligned, expected=addr
            if v_addr(1 downto 0) = "00" then
                expected := v_addr;
            -- 16-bit aligned, bottom 16bits is upper 16-bits of addr, uppwer
            elsif v_addr(1 downto 0) = "10" then
                expected(15 downto 0) := v_addr(31 downto 16);
                expected(31 downto 16) := v_addr_next(15 downto 0);
            else
                report "Misaligned transfer from " & to_hstring(v_addr);
            end if;
            assert out_instr = expected report "Expected " & to_hstring(expected) & " Got " & to_hstring(out_instr) severity error;
            if out_instr = expected then
                msg("OK");
            end if;


        end procedure read_instr;
    begin
        wait for 150 ns;
        read_instr(0);
        read_instr(4);
        read_instr(8);
        read_instr(12);
        read_instr(40);
        read_instr(1024);
        wait;
    end process;


dut_icache : entity work.icache
    generic map(
        G_NUM_BLOCKS => G_NUM_BLOCKS,
        G_BLOCK_SIZE => G_BLOCK_SIZE,
        G_SET_SIZE   => G_SET_SIZE
    )
    port map(
        clk             => clk,
        rst             => rst,
        in_addr         => in_addr,
        in_addr_valid   => in_addr_valid,
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
