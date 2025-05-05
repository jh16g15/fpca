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
	signal interrupts : t_interrupts := C_INTERRUPTS_NULL;
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
            -- wait until rising_edge(clk);
            -- Set up OP
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
            -- Execute
            wait until rising_edge(clk);
            csr_op_enable <= '0';
            wait for 0 ns;  -- delta cycle fun
            info("Old value of CSR was " & to_hstring(csr_rdata));
            rdat := csr_rdata;

        end procedure;

        variable rdat : std_logic_vector(31 downto 0);
        
    begin
        test_runner_setup(runner, runner_cfg);
        info("Vunit is alive!");
        show(get_logger(default_checker), display_handler, pass);
        info("Test MSCRATCH register");
        wait until reset = '0';
        wait for 4 ns;
        csr_op(CSR_MSCRATCH_ADDR, rdat, CSR_FUNCT3_CSRRW, x"1234_5678");    -- write
        -- check(rdat = x"0000_0000");  -- don't check initial value
        csr_op(CSR_MSCRATCH_ADDR, rdat, CSR_FUNCT3_CSRRC, x"0000_000F");    -- clear bottom 4 bits
        check_equal(rdat, std_logic_vector'(x"1234_5678"));
        csr_op(CSR_MSCRATCH_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0008_0000");    -- set bit
        check_equal(rdat, std_logic_vector'(x"1234_5670"));
        csr_op(CSR_MSCRATCH_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");    -- read, don't change
        check_equal(rdat, std_logic_vector'(x"123C_5670"));
        info("done");
        wait for 100 ns;

        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRSI, x"0000_0010"); -- expect fail to write to CYCLE reg
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_MCYCLE_ADDR, rdat, CSR_FUNCT3_CSRRW, x"0000_0010"); -- expect successful write to MCYCLE reg
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");   --  which is then mirrored to the CYCLE reg
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");   --  ...eventually
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");   --  ...eventually
        csr_op(CSR_CYCLE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");   --  ...eventually

        info("done check for CYCLE register");
        
        info("Enable Interrupts");

        -- assert external and timer interrupts
        interrupts.mei <= '1';
        interrupts.mti <= '1';

        csr_op(CSR_MIP_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000"); -- check pending interrupts
        check_equal(rdat, std_logic_vector'(x"0000_0000"), "Check all interrupts are masked off");

        csr_op(CSR_MSTATUS_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0008"); -- set mstatus.mie (global interrupt enable)
        csr_op(CSR_MSTATUS_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000");
        csr_op(CSR_MTVEC_ADDR, rdat, CSR_FUNCT3_CSRRW, x"0001_0001"); -- VECTORED mode @0x00010000
        csr_op(CSR_MTVEC_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000"); 
        check_equal(rdat, std_logic_vector'(x"0001_0001"), "Check MTVEC set correctly");

        csr_op(CSR_MIP_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000"); -- check pending interrupts
        check_equal(rdat, std_logic_vector'(x"0000_0000"), "Check all interrupts are masked off");

        csr_op(CSR_MIE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0800"); -- enable M External Interrupt
        
        csr_op(CSR_MIP_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000"); -- check pending interrupts
        check_equal(rdat, std_logic_vector'(x"0000_0800"), "Check only Machine External Interrupt (11) pending");
        check_equal(trap_pc_out, std_logic_vector'(x"0001_002C"), "Check Trap branch address");
        csr_op(CSR_MCAUSE_ADDR, rdat, CSR_FUNCT3_CSRRS, x"0000_0000"); -- check mcause
        check_equal(rdat, std_logic_vector'(x"8000_000B"), "Check Exception Code in MCAUSE");
                -- check_equal(rdat, std_logic_vector'(x"8000_000B"), "Check Exception Code in MCAUSE");
        
        wait for 100 ns;
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
            -- exception       => exception,
            exceptions      => exceptions,
            -- interrupt       => interrupt,
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
