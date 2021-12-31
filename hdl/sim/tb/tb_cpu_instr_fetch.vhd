library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;
--
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_cpu_instr_fetch is
    generic (runner_cfg : string);
end;

architecture bench of tb_cpu_instr_fetch is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant G_PC_RESET_ADDR : unsigned(31 downto 0) := x"0000_0000";

    -- Ports
    signal clk   : std_logic;
    signal reset : std_logic := '0';

    signal branch_addr_in  : std_logic_vector(31 downto 0);
    signal branch_en_in    : std_logic;
    signal pc_out          : std_logic_vector(31 downto 0);
    signal next_pc_out     : std_logic_vector(31 downto 0);
    signal fetch_req_in    : std_logic;
    signal instr_valid_out : std_logic;
    signal instr_out       : std_logic_vector(31 downto 0);
    signal fetch_err_out   : std_logic;
    signal fetch_busy_out  : std_logic;
    signal if_wb_mosi_out  : t_wb_mosi;
    signal if_wb_miso_in   : t_wb_miso;

    signal exp_instrs : t_slv32_arr(0 to 9) := (
        x"0000_0000", 
        x"0000_0001", 
        x"0000_0002", 
        x"0000_0003", 
        x"0000_0004", 
        x"0000_0005", 
        x"0000_000C", 
        x"0000_000D", 
        x"0000_000E", 
        x"0000_000F"
        );
    signal out_count : integer := 0;

    signal checks_done : std_logic := '0';
    
    constant tb_logger     : logger_t     := get_logger("tb");
    constant tb_checker    : checker_t    := new_checker("tb");

    type t_state is (FETCH, EXECUTE);
    signal state : t_state := FETCH;

begin

    cpu_instr_fetch_inst : entity work.cpu_instr_fetch
        generic map(
            G_PC_RESET_ADDR => G_PC_RESET_ADDR
        )
        port map(
            clk             => clk,
            reset           => reset,
            branch_addr_in  => branch_addr_in,
            branch_en_in    => branch_en_in,
            pc_out          => pc_out,
            next_pc_out     => next_pc_out,
            fetch_req_in    => fetch_req_in,
            instr_valid_out => instr_valid_out,
            instr_out       => instr_out,
            fetch_err_out   => fetch_err_out,
            fetch_busy_out  => fetch_busy_out,
            if_wb_mosi_out  => if_wb_mosi_out,
            if_wb_miso_in   => if_wb_miso_in
        );

    prog_mem : entity work.wb_sp_bram
        generic map(
            G_MEM_DEPTH_WORDS => 256,
            G_INIT_FILE       => "data/data.txt" -- path is relative from Simulation directory
        )
        port map(
            wb_clk      => clk,
            wb_reset    => reset,
            wb_mosi_in  => if_wb_mosi_out,
            wb_miso_out => if_wb_miso_in
        );

    main : process
    begin
        test_runner_setup(runner, runner_cfg);

        show(tb_logger, display_handler, verbose);
        -- show passing assertions for tb_checker
        show(get_logger(tb_checker), display_handler, pass);
        -- continue simulating on error
        set_stop_level(failure);

        while test_suite loop
            if run("test_alive") then
                info("Hello world test_alive");

                fetch_req_in   <= '0';
                branch_addr_in <= x"0000_0030";
                branch_en_in <= '0';
                wait for 10 * clk_period;
                fetch_req_in <= '1';
                
                wait until instr_out = x"0000_0005" and instr_valid_out = '1';

                branch_en_in <= '1';
                wait until fetch_busy_out = '0' and rising_edge(clk); -- wait until accepted
                branch_en_in <= '0'; -- now stop branching
                
                wait until checks_done = '1';
                test_runner_cleanup(runner);

            end if;
        end loop;
    end process main;

    -- stim_proc : process (clk)
    -- begin
    --     if rising_edge(clk) then
    --         case(state) is
    --         when FETCH =>
    --             if instr_valid_out = '1' then 
    --                 state <= EXECUTE;
    --                 fetch_req_in <= '0';
    --             end if;
    --         when EXECUTE => 
    --     end case;
    --     end if;
    -- end process;

    check_proc : process (clk)
    begin
        if rising_edge(clk) then
            if instr_valid_out = '1' then
                check_equal(tb_checker, instr_out, exp_instrs(out_count), "Instruction Check");
                out_count <= out_count + 1;
                if out_count = 9 then 
                    checks_done <= '1';
                end if;
            end if;
        end if;
    end process;


    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;

end;