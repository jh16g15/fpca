library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.riscv_instructions_pkg.all;
use work.joe_common_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_cpu_instruction_mem is
    generic (runner_cfg : string);
end;

architecture bench of tb_cpu_instruction_mem is
    -- Clock period
    constant clk_period : time := 10 ns;
    -- Generics
    constant G_IMEM_ADDR_W : integer := 8;
    constant G_INSTR_W     : integer := 32;
    constant G_INIT_SRC    : string  := "";
    constant G_MEM_IMPL    : string  := "bram";

    -- Ports
    signal clk             : std_logic;
    signal addr_in         : std_logic_vector(G_IMEM_ADDR_W + 2 - 1 downto 0);
    signal instruction_out : std_logic_vector(G_INSTR_W - 1 downto 0);

    type t_mem is array (0 to 2 ** G_IMEM_ADDR_W - 1) of std_logic_vector(G_INSTR_W - 1 downto 0);
    signal exp_mem : t_mem := (0 => x"40000093", 1 => x"00100113", 2 => x"00008193", others => x"0000_0000");

begin

    cpu_instruction_mem_inst : entity work.cpu_instruction_mem
        generic map(
            G_IMEM_ADDR_W => G_IMEM_ADDR_W,
            G_INSTR_W     => G_INSTR_W,
            G_INIT_SRC    => G_INIT_SRC,
            G_MEM_IMPL    => G_MEM_IMPL
        )
        port map(
            clk             => clk,
            addr_in         => addr_in,
            instruction_out => instruction_out
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);
        while test_suite loop
            if run("test") then

                for i in 0 to 15 loop
                    addr_in <= uint2slv(i * 4, 10);
                    wait until rising_edge(clk);
                    wait for 0 ns;
                    check_equal(instruction_out, exp_mem(i));
                end loop;

                test_runner_cleanup(runner);

            end if;
        end loop;
    end process main;

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;