library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.joe_common_pkg.all;
use work.rv_csr_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;


entity tb_rv_csr is
    generic(
        runner_cfg : string 
    );
end entity tb_rv_csr;


architecture tb of tb_rv_csr is
	signal clk : std_logic  := '0';
	signal reset : std_logic := '1';
	signal cycle_incr : std_logic;
	signal instret_incr : std_logic;
	signal exception : std_logic;
	signal exceptions : t_exceptions;
	signal interrupt : std_logic;
	signal interrupts : t_interrupts;
	signal exec_pc : std_logic_vector(31 downto 0);
	signal exec_instr : std_logic_vector(31 downto 0);
	signal fault_addr : std_logic_vector(31 downto 0);
	signal mret : std_logic;
	signal trap_pc_out : std_logic_vector(31 downto 0);
	signal use_trap_pc_out : std_logic;
	signal mtime : unsigned(63 downto 0);
	signal csr_op_enable : std_logic;
	signal csr_addr : std_logic_vector(11 downto 0);
	signal csr_rdata : std_logic_vector(31 downto 0);
	signal csr_funct3 : std_logic_vector(2 downto 0);
	signal rs1 : std_logic_vector(4 downto 0);
	signal rs1_data : std_logic_vector(31 downto 0);
	signal imm : std_logic_vector(4 downto 0);
    
begin

    cycle_incr <= '1'; -- increment while not halted


    clk <= not clk after 5 ns;  
    reset <='0' after 15 ns;  

    stim : process is
        procedure csr_op(
            addr : in std_logic_vector(11 downto 0); 
            rdat : out std_logic_vector(31 downto 0); 
            funct3 : in std_logic_vector(2 downto 0);
            wdat : in std_logic_vector(31 downto 0)
        ) is
        begin
            csr_op_enable <= '0';
            wait until rising_edge(clk);
            csr_addr <= addr;
            csr_funct3 <= funct3;
            csr_op_enable <= '1';
            case funct3 is
                when "001" => 
                    info("performing CSRRW on " & to_hstring(addr) & " wdat = " & to_hstring(wdat));
                    rs1_data <= wdat;
                when "010" => 
                    info("performing CSRRS on " & to_hstring(addr) & " wdat = " & to_hstring(wdat));
                    rs1_data <= wdat;
                when "011" =>
                    info("performing CSRRC on " & to_hstring(addr) & " wdat = " & to_hstring(wdat));
                    rs1_data <= wdat;
                when "101" => 
                    info("performing CSRRWI on " & to_hstring(addr) & " wdat = " & to_hstring(wdat(4 downto 0)));
                    imm <= wdat(4 downto 0);
                when "110" => 
                    info("performing CSRRSI on " & to_hstring(addr) & " wdat = " & to_hstring(wdat(4 downto 0)));
                    imm <= wdat(4 downto 0);
                when "111" =>
                    info("performing CSRRCI on " & to_hstring(addr) & " wdat = " & to_hstring(wdat(4 downto 0)));
                    imm <= wdat(4 downto 0);
                when others => failure("invalid funct3");
            end case;
            
            wait until rising_edge(clk);
            csr_op_enable <= '0';
            info("Old value of CSR was " & to_hstring(csr_rdata));
            rdat := csr_rdata;

        end procedure;

        variable rdat : std_logic_vector(31 downto 0);
        
    begin
        test_runner_setup(runner, runner_cfg);
        info("Vunit is alive!");
        wait for 100 ns;
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRSI, x"0000_0010"); -- expect fail to write to CYCLE reg
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_MCYCLE_ADDR, rdat, CSR_FUNCT3_CSRRW, x"0000_0010"); -- expect successful write to MCYCLE reg
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");   --  which is then mirrored to the CYCLE reg
        test_runner_cleanup(runner);
        wait;
    end process;

    dut : entity work.rv_csr
        -- generic map(
            -- G_CSR_MISA_INIT       => G_CSR_MISA_INIT,
            -- G_CSR_MARCHID_INIT    => G_CSR_MARCHID_INIT,
            -- G_CSR_MIMPID_INIT     => G_CSR_MIMPID_INIT,
            -- G_CSR_MHARTID_INIT    => G_CSR_MHARTID_INIT,
            -- G_CSR_MCONFIGPTR_INIT => G_CSR_MCONFIGPTR_INIT,
            -- G_INCL_M_REGS         => G_INCL_M_REGS,
            -- G_INCL_S_REGS         => G_INCL_S_REGS
        -- )
        port map(
            clk             => clk,
            reset           => reset,
            cycle_incr      => cycle_incr,
            instret_incr    => instret_incr,
            exception       => exception,
            exceptions      => exceptions,
            interrupt       => interrupt,
            interrupts      => interrupts,
            exec_pc         => exec_pc,
            exec_instr      => exec_instr,
            fault_addr      => fault_addr,
            mret            => mret,
            trap_pc_out     => trap_pc_out,
            use_trap_pc_out => use_trap_pc_out,
            mtime           => mtime,
            csr_op_enable   => csr_op_enable,
            csr_addr        => csr_addr,
            csr_rdata       => csr_rdata,
            funct3          => csr_funct3,
            rs1_data        => rs1_data,
            imm             => imm
        );
    

end architecture tb;
