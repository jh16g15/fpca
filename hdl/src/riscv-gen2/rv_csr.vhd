library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.rv_csr_pkg.all;

--! RISC-V Priviledged CSRs 20240411
--! in the EXECUTE pipeline state
entity rv_csr is
generic (
    -- RV32I. Edit this if more extensions are added
    G_CSR_MISA_INIT : t_misa := (
        mxl => "01",    -- XLEN=32 bits
        a => '0',
        c => '0',
        i => '1',
        m => '0',
        s => '0',
        u => '0',
        x => '0'
     ); 
    G_CSR_MARCHID_INIT : std_logic_vector(31 downto 0) := x"0000_0000";
    G_CSR_MIMPID_INIT : std_logic_vector(31 downto 0) := x"0000_0000";
    G_CSR_MHARTID_INIT : std_logic_vector(31 downto 0) := x"0000_0000"; -- each core needs a unique Hart ID
    G_CSR_MCONFIGPTR_INIT : std_logic_vector(31 downto 0) := x"0000_0000"; -- if more config info is stored somewhere

    G_INCL_M_REGS : boolean := true;
    G_INCL_S_REGS : boolean := false
);
port (
    clk : in std_logic;
    reset : in std_logic;

    cycle_incr : in std_logic;  --! Increase Cycle Counter
    instret_incr : in std_logic; --! Increase Instructions Retired (complete)
    
    exception : in std_logic;
    exceptions : in t_exceptions;

    interrupt : in std_logic;
    interrupts : in t_interrupts;

    exec_pc : in std_logic_vector(31 downto 0);     -- Address of Instruction Currently being executed
    exec_instr : in std_logic_vector(31 downto 0);  -- Instruction Currently being executed
    fault_addr : in std_logic_vector(31 downto 0);  -- Address of instr/data access fault

    mret : in std_logic;
    trap_pc_out : out std_logic_vector(31 downto 0);
    use_trap_pc_out : out std_logic;
    -- sret : in std_logic;

    mtime : in unsigned(63 downto 0) := (others => '0'); -- from memory mapped reg

    csr_op_enable : in std_logic;
    csr_addr : in std_logic_vector(11 downto 0);
    csr_rdata : out std_logic_vector(31 downto 0); -- data from the CSR
    
    funct3 : in std_logic_vector(2 downto 0);   -- determines which Zicsr instruction this is

    -- Technically, we need these to determine if CSR reads/write take place (sometimes skipped if x0)
    -- rd : in std_logic_vector(4 downto 0);
    -- rs1 : in std_logic_vector(4 downto 0);

    rs1_data : in std_logic_vector(31 downto 0);    -- data to write/set/clear to the CSR
    imm : in std_logic_vector(4 downto 0) -- zero-extend this, data to write/set/clear to the CSR
);
end entity;

architecture rtl of rv_csr is

    -- CSR Instructions
    -- CSRRW (Atomic Read/Write CSR): reads CSR, zero-extends, writes to rd (unless rd=x0). New value of CSR=rs1
    -- CSRRS (Atomic Read and Set Bits CSR): reads CSR, zero-extends, writes to rd. New value of CSR= CSR | rs1 (for writeable bits). No write if rs1=x0
    -- CSRRS (Atomic Read and Set Bits CSR): reads CSR, zero-extends, writes to rd. New value of CSR= CSR & ~rs1 (for writeable bits). No write if rs1=x0

    signal use_imm : std_logic; -- funct3(2)
    signal csr_opcode : std_logic_vector(1 downto 0); -- funct3(1:0)
    signal imm_extended : std_logic_vector(31 downto 0) := (others => '0');
    signal csr_wdata : std_logic_vector(31 downto 0);
    signal illegal_csr : std_logic;
    constant CSRRW : std_logic_vector(1 downto 0) := "01";  -- Read/Write
    constant CSRRS : std_logic_vector(1 downto 0) := "10";  -- Read/Set
    constant CSRRC : std_logic_vector(1 downto 0) := "11";  -- Read/Clear

    -- CSR Fields 
    -- WPRI - reserved -> read-only '0'
    -- WLRL - reserved -> can be read-only '0' (software should not write these bits)
    -- WARL - reserved -> read-only '0'

    

    constant CSR_MVENDORID_INIT : std_logic_vector(31 downto 0) := x"0000_0000";

    -- When a trap is taken from privilege mode y into privilege mode x, 
    --  xPIE is set to the value of xIE; xIE is set to 0; and xPP is set to y.

    -- When executing an xRET instruction, supposing xPP holds the value y, 
    --  xIE is set to xPIE; the privilege mode is changed to y; xPIE is set to 1; 
    --  and xPP is set to the least-privileged supported mode (U if U-mode is implemented, else M). If y≠M, xRET also sets MPRV=0.

    -- function csr_op(csr_op : std_logic_vector(1 downto 0); wdata(31 downnto 0))
    
    signal misa : t_misa := G_CSR_MISA_INIT;
    signal mstatus : t_mstatus; --! Machine Mode Status 
    signal mtvec : t_mtvec; --! Machine Mode Trap Vectir
    signal mie : t_mi; --! Machine Mode Interrupt Enable
    signal mip : t_mi; --! Machine Mode Interrupt Pending
    signal mcountinhibit : std_logic_vector(31 downto 0) := (others => '0');
    signal mscratch : std_logic_vector(31 downto 0) := (others => '0');
    signal mepc : std_logic_vector(31 downto 0) := (others => '0');
    signal mcause : std_logic_vector(31 downto 0) := (others => '0');
    signal mtval : std_logic_vector(31 downto 0) := (others => '0');


    signal current_privilege : std_logic_vector(1 downto 0); -- enum?
    constant C_MODE_M : std_logic_vector(1 downto 0) := "11";
    constant C_MODE_S : std_logic_vector(1 downto 0) := "01";
    constant C_MODE_U : std_logic_vector(1 downto 0) := "00";

    -- signal mtime : unsigned(63 downto 0) := (others => '0'); -- this should be memory mapped externally
    signal mcycle : unsigned(63 downto 0) := (others => '0');
    signal minstret : unsigned(63 downto 0) := (others => '0');
begin
    imm_extended(4 downto 0) <= imm; -- zero extend
    use_imm <= funct3(2);
    csr_opcode <= funct3(1 downto 0);
    csr_wdata <= rs1_data when use_imm = '0' else imm_extended;

    -- RW - so write the fields
    
    csr_proc : process(clk) is
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_privilege <= C_MODE_M;
                mstatus <= (mpp=>"11", mpie=>'0', mie=>'0'); -- no interrupts until setup complete
                mtvec <= (base => (others => '0'), mode => MTVEC_MODE_DIRECT); -- must be written by software on boot!
                misa <= G_CSR_MISA_INIT;
                mcountinhibit <= (others => '0');
            else

                -- increment counters (overwritten by CSR write below)
                if mcountinhibit(0) = '0' and cycle_incr = '1' then
                    mcycle <= mcycle + 1;
                end if;
                if mcountinhibit(2) = '0' and instret_incr = '1' then
                    minstret <= minstret + 1;
                end if;
                
                if csr_op_enable then
                    --======= Unpriviliged Read-only shadows of m-counters ==========
                    -- TODO: access permissions based on mcounteren (currently unimplemented)
                    case(csr_addr) is
                        when CSR_CYCLE_ADDR => 
                            csr_rdata <= std_logic_vector(mcycle(31 downto 0));
                        when CSR_CYCLEH_ADDR => 
                            csr_rdata <= std_logic_vector(mcycle(63 downto 32));
                        when CSR_TIME_ADDR => 
                            csr_rdata <= std_logic_vector(mtime(31 downto 0));
                        when CSR_TIMEH_ADDR => 
                            csr_rdata <= std_logic_vector(mtime(63 downto 32));
                        when CSR_INSTRET_ADDR  => 
                            csr_rdata <= std_logic_vector(minstret(31 downto 0));
                        when CSR_INSTRETH_ADDR => 
                            csr_rdata <= std_logic_vector(minstret(63 downto 32));
                        when others => null;
                    end case;
                    if current_privilege = C_MODE_M then
                        --======= Machine Mode CSRs ==========
                        case(csr_addr) is
                            ------- Machine CSR Read Only Registers -------
                            when CSR_MVENDORID_ADDR => 
                                csr_rdata <= CSR_MVENDORID_INIT;
                            when CSR_MARCHID_ADDR => 
                                csr_rdata <= G_CSR_MARCHID_INIT;
                            when CSR_MIMPID_ADDR => 
                                csr_rdata <= G_CSR_MIMPID_INIT;
                            when CSR_MHARTID_ADDR => 
                                csr_rdata <= G_CSR_MHARTID_INIT;
                            when CSR_MCONFIGPTR_ADDR => 
                                csr_rdata <= G_CSR_MCONFIGPTR_INIT;
                            ------- CSR Read/Write Registers -------
                            when CSR_MISA_ADDR=> 
                                csr_rdata <=  read_misa(misa);
                                case (csr_opcode) is
                                    when CSRRW => misa <= write_misa(csr_wdata);
                                    when CSRRS => misa <= write_misa(set(read_misa(misa), csr_wdata));
                                    when CSRRC => misa <= write_misa(clr(read_misa(misa), csr_wdata));    
                                    when others => null;    -- TODO Illegal instruction
                                end case;

                            when CSR_MSTATUS_ADDR => 
                                csr_rdata <= read_mstatus(mstatus); -- Technically we shouldn't read if rd=x0, but there are no side effects
                                case (csr_opcode) is
                                    when CSRRW => mstatus <= write_mstatus(csr_wdata);
                                    when CSRRS => mstatus <= write_mstatus(set(read_mstatus(mstatus), csr_wdata));
                                    when CSRRC => mstatus <= write_mstatus(clr(read_mstatus(mstatus), csr_wdata));    
                                    when others => null;    -- TODO Illegal instruction
                                end case;

                            when CSR_MTVEC_ADDR =>
                                csr_rdata <=  read_mtvec(mtvec);
                                case (csr_opcode) is
                                    when CSRRW => mtvec <= write_mtvec(csr_wdata);
                                    when CSRRS => mtvec <= write_mtvec(set(read_mtvec(mtvec), csr_wdata));
                                    when CSRRC => mtvec <= write_mtvec(clr(read_mtvec(mtvec), csr_wdata));    
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                            
                            when CSR_MIE_ADDR =>
                                csr_rdata <=  read_mie(mie);
                                case (csr_opcode) is
                                    when CSRRW => mie <= write_mie(csr_wdata);
                                    when CSRRS => mie <= write_mie(set(read_mie(mie), csr_wdata));
                                    when CSRRC => mie <= write_mie(clr(read_mie(mie), csr_wdata));    
                                    when others => null;    -- TODO Illegal instruction
                                end case;

                            when CSR_MIP_ADDR =>
                                csr_rdata <=  read_mip(mip);
                                case (csr_opcode) is
                                    when CSRRW => mip <= write_mip(csr_wdata);
                                    when CSRRS => mip <= write_mip(set(read_mip(mip), csr_wdata));
                                    when CSRRC => mip <= write_mip(clr(read_mip(mip), csr_wdata));    
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                            
                            when CSR_MCYCLE_ADDR => 
                                csr_rdata <= std_logic_vector(mcycle(31 downto 0));
                                case (csr_opcode) is
                                    when CSRRW => mcycle(31 downto 0) <= unsigned(csr_wdata);
                                    when CSRRS => mcycle(31 downto 0) <= set(mcycle(31 downto 0), unsigned(csr_wdata));
                                    when CSRRC => mcycle(31 downto 0) <= clr(mcycle(31 downto 0), unsigned(csr_wdata));
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                            
                            when CSR_MCYCLEH_ADDR => 
                                csr_rdata <= std_logic_vector(mcycle(63 downto 32));
                                case (csr_opcode) is
                                    when CSRRW => mcycle(63 downto 32) <= unsigned(csr_wdata);
                                    when CSRRS => mcycle(63 downto 32) <= set(mcycle(63 downto 32), unsigned(csr_wdata));
                                    when CSRRC => mcycle(63 downto 32) <= clr(mcycle(63 downto 32), unsigned(csr_wdata));
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                            
                            when CSR_MINSTRET_ADDR => 
                                csr_rdata <= std_logic_vector(minstret(31 downto 0));
                                case (csr_opcode) is
                                    when CSRRW => minstret(31 downto 0) <= unsigned(csr_wdata);
                                    when CSRRS => minstret(31 downto 0) <= set(minstret(31 downto 0), unsigned(csr_wdata));
                                    when CSRRC => minstret(31 downto 0) <= clr(minstret(31 downto 0), unsigned(csr_wdata));
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                            
                            when CSR_MINSTRETH_ADDR=> 
                                csr_rdata <= std_logic_vector(minstret(63 downto 32));
                                case (csr_opcode) is
                                    when CSRRW => minstret(63 downto 32) <= unsigned(csr_wdata);
                                    when CSRRS => minstret(63 downto 32) <= set(minstret(63 downto 32), unsigned(csr_wdata));
                                    when CSRRC => minstret(63 downto 32) <= clr(minstret(63 downto 32), unsigned(csr_wdata));
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                            
                            when CSR_MCOUNTINHIBIT_ADDR=> 
                                csr_rdata <= mcountinhibit;
                                case (csr_opcode) is
                                    when CSRRW => mcountinhibit <= csr_wdata;
                                    when CSRRS => mcountinhibit <= set(mcountinhibit, csr_wdata);
                                    when CSRRC => mcountinhibit <= clr(mcountinhibit, csr_wdata);    
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                            
                            when CSR_MSCRATCH_ADDR=> 
                                csr_rdata <= mscratch;
                                case (csr_opcode) is
                                    when CSRRW => mscratch <= csr_wdata;
                                    when CSRRS => mscratch <= set(mscratch, csr_wdata);
                                    when CSRRC => mscratch <= clr(mscratch, csr_wdata);
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                                
                            when CSR_MEPC_ADDR=> 
                                csr_rdata <= mepc;
                                case (csr_opcode) is
                                    when CSRRW => mepc <= csr_wdata;
                                    when CSRRS => mepc <= set(mepc, csr_wdata);
                                    when CSRRC => mepc <= clr(mepc, csr_wdata);    
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                            
                            when CSR_MCAUSE_ADDR=> 
                                csr_rdata <= mcause;
                                case (csr_opcode) is
                                    when CSRRW => mcause <= csr_wdata;
                                    when CSRRS => mcause <= set(mcause, csr_wdata);
                                    when CSRRC => mcause <= clr(mcause, csr_wdata);    
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                                
                            when CSR_MTVAL_ADDR=> 
                                csr_rdata <= mtval;
                                case (csr_opcode) is
                                    when CSRRW => mtval <= csr_wdata;
                                    when CSRRS => mtval <= set(mtval, csr_wdata);
                                    when CSRRC => mtval <= clr(mtval, csr_wdata);    
                                    when others => null;    -- TODO Illegal instruction
                                end case;
                            
                           
                            when others => null;
                        end case;
                    end if; -- end machine-mode only CSRs
                end if; -- end CSR op

                ------- Trap Handling (overwrite normal CSR read/write) -------
                -- TODO set this interrupt flag via mip/mie/mstatus
                use_trap_pc_out <= '0';
                if exception = '1' or interrupt = '1' then
                    use_trap_pc_out <= '1';
                    
                    mepc <= exec_pc;    -- save PC to resume to (ISR may need to increment past this)
                    mstatus.mpp <= current_privilege;   -- save privilege level to come back to
                    mstatus.mpie <= mstatus.mie;    -- save interrupt enable status
                    mstatus.mie <= '0';     -- disable interrupts
                    if interrupt = '1' then -- interrupts take prio over exceptions
                        mcause  <=  read_interrupts(interrupts);
                        mtval <= (others => '0');
                        case mtvec.mode is
                            when MTVEC_MODE_DIRECT => 
                                trap_pc_out <= mtvec_base(mtvec);
                            when MTVEC_MODE_VECTORED => 
                                -- TODO vectored mode
                                trap_pc_out <= mtvec_base(mtvec);
                                -- trap_pc_out <= mtvec_base(mtvec) + to_unsigned(find_highest_set_bit(read_interrupts(interrupts))(29 downto 0) & unsigned'("00"));
                            when others => null;
                        end case;
                    else    -- Exception
                        trap_pc_out <= mtvec_base(mtvec); 
                        mcause <= read_exceptions(exceptions);
                        if exceptions.instr_misaligned = '1' or exceptions.instr_access = '1'  or exceptions.instr_page_fault = '1' or 
                            exceptions.load_misaligned = '1' or exceptions.load_access = '1' or exceptions.load_page_fault = '1' or
                            exceptions.store_amo_misaligned = '1' or exceptions.store_amo_access = '1' or exceptions.store_amo_page_fault = '1' or
                            exceptions.ebreak = '1'
                        then
                            mtval <= fault_addr;
                        elsif exceptions.illegal_instr then -- save instruction bits for instruction emulation or debug
                            mtval <= exec_instr; 
                        else
                            mtval <= (others => '0');

                        end if;
                    end if;
                
                end if;    
                ------- MRET Handling -------
                if mret = '1' then
                    use_trap_pc_out <= '1';
                    trap_pc_out <= mepc; -- resume interrputed instruction
                    current_privilege <= mstatus.mpp; -- restore previous privilege
                    mstatus.mie <= mstatus.mpie; -- re-enable interrupts if they were enabled previously
                end if;
            end if;
        end if;
    end process;



end architecture;