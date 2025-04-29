library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rv_csr_pkg is

    constant CSR_FUNCT3_CSRRW : std_logic_vector(2 downto 0) := "001";
    constant CSR_FUNCT3_CSRRS : std_logic_vector(2 downto 0) := "010";
    constant CSR_FUNCT3_CSRRC : std_logic_vector(2 downto 0) := "011";
    constant CSR_FUNCT3_CSRRWI : std_logic_vector(2 downto 0) := "101";
    constant CSR_FUNCT3_CSRRSI : std_logic_vector(2 downto 0) := "110";
    constant CSR_FUNCT3_CSRRCI : std_logic_vector(2 downto 0) := "111";

    --Unpriviliged Counters/Timers (Zicntr) (all read-only)
    constant CSR_CYCLE_ADDR : std_logic_vector(11 downto 0) := x"C00";
    constant CSR_TIME_ADDR : std_logic_vector(11 downto 0) := x"C01";
    constant CSR_INSTRET_ADDR : std_logic_vector(11 downto 0) := x"C02";
    constant CSR_CYCLEH_ADDR : std_logic_vector(11 downto 0) := x"C80";
    constant CSR_TIMEH_ADDR : std_logic_vector(11 downto 0) := x"C81";
    constant CSR_INSTRETH_ADDR : std_logic_vector(11 downto 0) := x"C82";

    -- Machine Information Registers (Machine mode read-only)
    constant CSR_MVENDORID_ADDR : std_logic_vector(11 downto 0) := x"F11";
    constant CSR_MARCHID_ADDR : std_logic_vector(11 downto 0) := x"F12";
    constant CSR_MIMPID_ADDR : std_logic_vector(11 downto 0) := x"F13";
    constant CSR_MHARTID_ADDR : std_logic_vector(11 downto 0) := x"F14";
    constant CSR_MCONFIGPTR_ADDR : std_logic_vector(11 downto 0) := x"F15";
    
    -- Machine Trap Setup (RW)
    constant CSR_MSTATUS_ADDR : std_logic_vector(11 downto 0) := x"300";
    constant CSR_MISA_ADDR : std_logic_vector(11 downto 0) := x"301";
    constant CSR_MEDELEG_ADDR : std_logic_vector(11 downto 0) := x"302";    -- exception delegation
    constant CSR_MIDELEG_ADDR : std_logic_vector(11 downto 0) := x"303";    -- interrupt delegation
    constant CSR_MIE_ADDR : std_logic_vector(11 downto 0) := x"304";         -- interrupt enable
    constant CSR_MTVEC_ADDR : std_logic_vector(11 downto 0) := x"305";         -- trap handler base address
    constant CSR_MCOUNTEREN_ADDR : std_logic_vector(11 downto 0) := x"306";
    constant CSR_MSTATUSH_ADDR : std_logic_vector(11 downto 0) := x"310";
    constant CSR_MEDELEGH_ADDR : std_logic_vector(11 downto 0) := x"312";

    -- Machine Trap Handling (RW)
    constant CSR_MSCRATCH_ADDR : std_logic_vector(11 downto 0) := x"340";
    constant CSR_MEPC_ADDR : std_logic_vector(11 downto 0) := x"341";
    constant CSR_MCAUSE_ADDR : std_logic_vector(11 downto 0) := x"342"; -- trap cause
    constant CSR_MTVAL_ADDR : std_logic_vector(11 downto 0) := x"343";  -- trap value
    constant CSR_MIP_ADDR : std_logic_vector(11 downto 0) := x"344";    -- interrupt pending
    constant CSR_MTINST_ADDR : std_logic_vector(11 downto 0) := x"34A";    -- trap instruction (transformed)
    constant CSR_MTVAL2_ADDR : std_logic_vector(11 downto 0) := x"34B";  -- second trap value

    -- Machine Counter/Timers (RW)
    constant CSR_MCYCLE_ADDR : std_logic_vector(11 downto 0) := x"B00";  -- 
    constant CSR_MINSTRET_ADDR : std_logic_vector(11 downto 0) := x"B02";  -- 
    
    constant CSR_MCYCLEH_ADDR : std_logic_vector(11 downto 0) := x"B80";  -- 
    constant CSR_MINSTRETH_ADDR : std_logic_vector(11 downto 0) := x"B82";  -- 


    -- Machine Counter Setup (RW)
    constant CSR_MCOUNTINHIBIT_ADDR : std_logic_vector(11 downto 0) := x"320";  -- prevent counters from incrementing

    function set(orig, mask : in std_logic_vector(31 downto 0)) return std_logic_vector;
    function clr(orig, mask : in std_logic_vector(31 downto 0)) return std_logic_vector;
    function set(orig, mask : in unsigned(31 downto 0)) return unsigned;
    function clr(orig, mask : in unsigned(31 downto 0)) return unsigned;

    -- only implement bits we care about for now
    type t_mstatus is record
        mpp : std_logic_vector(1 downto 0); --! mpp: Machine Previous Privilige
        mpie : std_logic;  --! mpie: Machine Previous Interrupt Enable
        mie : std_logic;--! mie: Machine Interrupt Enable
    end record;
    function read_mstatus(m : in t_mstatus) return std_logic_vector;
    function write_mstatus(val : in std_logic_vector(31 downto 0)) return t_mstatus;

    type t_mtvec is record 
        base : std_logic_vector(31 downto 2);   -- 4 byte aligned
        mode : std_logic_vector(1 downto 0);
    end record;
    function read_mtvec(m : in t_mtvec) return std_logic_vector;
    function write_mtvec(val : in std_logic_vector(31 downto 0)) return t_mtvec;
    function mtvec_base(m : in t_mtvec) return std_logic_vector;
    constant MTVEC_MODE_DIRECT : std_logic_vector(1 downto 0)  := "00";
    constant MTVEC_MODE_VECTORED : std_logic_vector(1 downto 0)  := "01";

    -- use for mie (enabled) and mip (pending), as they have the same fields
    type t_mi is record
        msi : std_logic;    -- machine software interrupt
        mti : std_logic;    -- machine timer interrupt
        mei : std_logic;    -- machine external interrupt
        platform : std_logic_vector(15 downto 0); -- platform specific interrupts
    end record;
    function read_mip(m : in t_mi) return std_logic_vector;
    function write_mip(val : in std_logic_vector(31 downto 0)) return t_mi;
    function read_mie(m : in t_mi) return std_logic_vector;
    function write_mie(val : in std_logic_vector(31 downto 0)) return t_mi;

    
    -- use for mie (enabled) and mip (pending), as they have the same fields
    type t_misa is record
        mxl : std_logic_vector(1 downto 0);    -- machine XLEN
        a : std_logic;  -- atomic
        c : std_logic;  -- compressed
        i : std_logic;  -- integer
        m : std_logic;  -- multiply/divide
        s : std_logic;  -- supervisor mode
        u : std_logic;  -- user mode
        x : std_logic;  -- non standard extensions
    end record;
    function read_misa(m : in t_misa) return std_logic_vector;
    function write_misa(val : in std_logic_vector(31 downto 0)) return t_misa;
    
    type t_exceptions is record
        -- Highest Priority
        instr_misaligned : std_logic;
        instr_access : std_logic;
        illegal_instr : std_logic;
        ebreak : std_logic;
        load_misaligned : std_logic;
        load_access : std_logic;
        store_amo_misaligned : std_logic;
        store_amo_access : std_logic;
        ecall_from_u : std_logic;
        ecall_from_s : std_logic;
        ecall_from_m : std_logic;
        instr_page_fault : std_logic;
        load_page_fault : std_logic;
        store_amo_page_fault : std_logic;
        double_trap : std_logic;
        software_check : std_logic;
        hardware_error : std_logic;
        -- Lowest Priority
    end record;
    function read_exceptions(m : in t_exceptions) return std_logic_vector;
    function write_exceptions(val : in std_logic_vector(31 downto 0)) return t_exceptions;
    
    type t_interrupts is record
        ssi : std_logic;    -- supervisor software interrupt
        msi : std_logic;    -- machine software interrupt
        sti : std_logic;    -- supervisor timer interrupt
        mti : std_logic;    -- machine timer interrupt
        sei : std_logic;    -- supervisor external interrupt
        mei : std_logic;    -- machine external interrupt
        lcofi : std_logic;  -- local counter overflow interrupt
        platform : std_logic_vector(14 downto 0);
    end record;
    function read_interrupts(m : in t_interrupts) return std_logic_vector;
    function write_interrupts(val : in std_logic_vector(31 downto 0)) return t_interrupts;

end package rv_csr_pkg;

package body rv_csr_pkg is

    function read_interrupts(m : in t_interrupts) return std_logic_vector is 
        variable val : std_logic_vector(31 downto 0)  := (others => '0');
    begin
        val(1) := m.ssi;
        val(3) := m.msi;
        val(5) := m.sti;        
        val(7) := m.mti;
        val(9) := m.sei;
        val(11) := m.mei;
        val(13) := m.lcofi;
        val(30 downto 16) := m.platform;
        val(31) := '1'; -- INTERRUPT, not exception
        return val;
    end function;
    
    function write_interrupts(val : in std_logic_vector(31 downto 0)) return t_interrupts is
        variable m : t_interrupts; 
    begin        
        m.ssi := val(1);
        m.msi := val(3);        
        m.sti := val(5);        
        m.mti := val(7);
        m.sei := val(9);
        m.mei := val(11);        
        m.lcofi := val(13);
        m.platform := val(30 downto 16);
        return m;
    end function;

    function read_exceptions(m : in t_exceptions) return std_logic_vector is 
        variable val : std_logic_vector(31 downto 0)  := (others => '0');
    begin
        val(0) := m.instr_misaligned;
        val(1) := m.instr_access;
        val(2) := m.illegal_instr;
        val(3) := m.ebreak;
        val(4) := m.load_misaligned;
        val(5) := m.load_access;
        val(6) := m.store_amo_misaligned;
        val(7) := m.store_amo_access;
        val(8) := m.ecall_from_u;
        val(9) := m.ecall_from_s;
        val(11) := m.ecall_from_m;
        val(12) := m.instr_page_fault;
        val(13) := m.load_page_fault;
        val(15) := m.store_amo_page_fault;
        val(16) := m.double_trap;
        val(18) := m.software_check;
        val(19) := m.hardware_error;
        return val;
    end function;
    
    function write_exceptions(val : in std_logic_vector(31 downto 0)) return t_exceptions is
        variable m : t_exceptions; 
    begin
        m.instr_misaligned := val(0);
        m.instr_access := val(1);
        m.illegal_instr := val(2);
        m.ebreak := val(3);
        m.load_misaligned := val(4);
        m.load_access := val(5);
        m.store_amo_misaligned := val(6);
        m.store_amo_access := val(7);
        m.ecall_from_u := val(8);
        m.ecall_from_s := val(9);
        m.ecall_from_m := val(11);
        m.instr_page_fault := val(12);
        m.load_page_fault := val(13);
        m.store_amo_page_fault := val(15);
        m.double_trap := val(16);
        m.software_check := val(18);
        m.hardware_error := val(19);
        return m;
    end function;

    function read_misa(m : in t_misa) return std_logic_vector is
        variable val : std_logic_vector(31 downto 0)  := (others => '0');
    begin
        val(31 downto 30) := m.mxl;
        val(0) := m.a;
        val(2) := m.c;
        val(8) := m.i;
        val(12) := m.m;
        val(18) := m.s;
        val(20) := m.u;
        val(23) := m.x;
        return val;
    end function;

    function write_misa(val : in std_logic_vector(31 downto 0)) return t_misa is
        variable m : t_misa;  
    begin
        m.mxl := val(31 downto 30);
        m.a := val(0);
        m.c := val(2);
        m.i := val(8);
        m.m := val(12);
        m.s := val(18);
        m.u := val(20);
        m.x := val(23);
        return m;
    end function;
    
    function read_mip(m : in t_mi) return std_logic_vector is 
        variable val : std_logic_vector(31 downto 0)  := (others => '0');
    begin 
        val(31 downto 16) := m.platform;
        val(11) := m.mei;
        val(7) := m.mti;
        val(3) := m.msi;
        return val;
    end function;

    function read_mie(m : in t_mi) return std_logic_vector is 
    begin 
        -- MIP and MIE have same format for reads
        return read_mip(m);
    end function;
    
    function write_mie(val : in std_logic_vector(31 downto 0)) return t_mi is
        variable m : t_mi;
    begin
        m.platform := val(31 downto 16);
        m.mei := val(11);
        m.mti := val(7);
        m.msi := val(3);
        return m;
    end function;

    function write_mip(val : in std_logic_vector(31 downto 0)) return t_mi is
        variable m : t_mi;
    begin
        m.platform := val(31 downto 16); -- assume these are all R/W in mip for now
        -- m.mei := val(11);    -- mei is read-only, cleared by platform interrupt controller
        -- m.mti := val(7);     -- mti is read-only, cleared by writing to memory mapped mtcmp (machine timer compare)
        -- m.msi := val(3);     -- msi is read-only, cleared by interprocessor comms memory mapped control reg
        return m;
    end function;


    function read_mtvec(m : in t_mtvec) return std_logic_vector is 
        variable val : std_logic_vector(31 downto 0)  := (others => '0');
    begin 
        val(31 downto 2) := m.base;
        val(1 downto 0) := m.mode;
        return val;
    end function;
    function write_mtvec(val : in std_logic_vector(31 downto 0)) return t_mtvec is
        variable m : t_mtvec;
    begin 
        m.base := val(31 downto 2);
        m.mode := val(1 downto 0);
        return m;
    end function;
    function mtvec_base(m : in t_mtvec) return std_logic_vector is
    begin
        return m.base & "00";
    end function;

    function read_mstatus(m : in t_mstatus) return std_logic_vector is
        variable val : std_logic_vector(31 downto 0)  := (others => '0');
    begin
        val(12 downto 11) := m.mpp;
        val(7) := m.mpie;
        val(3) := m.mie;
        return val;
    end function read_mstatus;
    function write_mstatus(val : in std_logic_vector(31 downto 0)) return t_mstatus is
        variable m : t_mstatus;
    begin
        m.mpp := val(12 downto 11);
        m.mpie := val(7);
        m.mie := val(3);
        return m;
    end function write_mstatus;
    function set(orig, mask : in std_logic_vector(31 downto 0)) return std_logic_vector is
    begin 
        return orig or mask;
    end function set;
    function clr(orig, mask : in std_logic_vector(31 downto 0)) return std_logic_vector is
    begin 
        return orig and not mask;
    end function clr;
    function set(orig, mask : in unsigned(31 downto 0)) return unsigned is
    begin 
        return orig or mask;
    end function set;
    function clr(orig, mask : in unsigned(31 downto 0)) return unsigned is
    begin 
        return orig and not mask;
    end function clr;
    

end package body;
