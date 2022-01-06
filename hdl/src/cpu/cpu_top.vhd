--! Top level module of the FPCA CPU (RV32I)
--! Instantiates all of the other

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all;
use work.riscv_instructions_pkg.all;

entity cpu_top is
    generic (
        G_PC_RESET_ADDR : unsigned(31 downto 0)
    );
    port (
        clk            : in std_logic;
        reset          : in std_logic;
        extern_halt_in : in std_logic;
        cpu_err_out    : out std_logic;
        -- Instruction Fetch Wishbone Master
        if_wb_mosi_out : out t_wb_mosi;
        if_wb_miso_in  : in t_wb_miso;

        -- Memory Wishbone Master
        mem_wb_mosi_out : out t_wb_mosi;
        mem_wb_miso_in  : in t_wb_miso

    );
end entity cpu_top;

architecture rtl of cpu_top is
    signal branch_addr         : std_logic_vector(31 downto 0);
    signal branch_target_final : std_logic_vector(31 downto 0);
    signal branch_en           : std_logic;
    signal branch_en_reg       : std_logic;
    signal branch_en_final     : std_logic;

    signal current_pc : std_logic_vector(31 downto 0);
    signal ret_addr   : std_logic_vector(31 downto 0);

    signal fetch_req     : std_logic;
    signal fetch_busy    : std_logic;
    signal fetch_err     : std_logic;
    signal instr_valid   : std_logic;
    signal rdat_instr    : std_logic_vector(31 downto 0); --! raw data from InstrFetch WB bus
    signal current_instr : std_logic_vector(31 downto 0); --! Saved when raw_instr valid

    signal rs1_addr     : std_logic_vector(REG_ADDR_W - 1 downto 0);
    signal rs2_addr     : std_logic_vector(REG_ADDR_W - 1 downto 0);
    signal rd_addr      : std_logic_vector(REG_ADDR_W - 1 downto 0);
    signal imm_extended : std_logic_vector(31 downto 0);

    -- decoded control signals
    signal opcode_err      : std_logic;
    signal uses_writeback  : std_logic;
    signal write_load      : std_logic;
    signal write_alu       : std_logic;
    signal write_ret_addr  : std_logic;
    signal uses_mem_access : std_logic;
    signal store_enable    : std_logic;
    signal current_opcode  : std_logic_vector(OPCODE_W - 1 downto 0);
    signal current_func7   : std_logic_vector(FUNCT7_W - 1 downto 0);
    signal current_func3   : std_logic_vector(FUNCT3_W - 1 downto 0);

    signal rs1_data      : std_logic_vector(31 downto 0);
    signal rs2_data      : std_logic_vector(31 downto 0);
    signal alu_en        : std_logic;
    signal alu_output    : std_logic_vector(31 downto 0);
    signal alu_func3_err : std_logic;

    signal write_reg_data : std_logic_vector(31 downto 0);
    signal write_reg_we   : std_logic;

    signal addr_align_err : std_logic;
    signal mem_req        : std_logic;
    signal mem_busy       : std_logic;
    signal mem_err        : std_logic;
    signal mem_done       : std_logic;

    attribute mark_debug                   : boolean;
    attribute mark_debug of current_pc     : signal is true;
    attribute mark_debug of current_instr  : signal is true;
    attribute mark_debug of addr_align_err : signal is true;
    attribute mark_debug of alu_func3_err  : signal is true;
    attribute mark_debug of opcode_err     : signal is true;
    attribute mark_debug of mem_err        : signal is true;

begin

    cpu_instr_fetch_inst : entity work.cpu_instr_fetch
        generic map(
            G_PC_RESET_ADDR => G_PC_RESET_ADDR
        )
        port map(
            clk             => clk,
            reset           => reset,
            branch_addr_in  => branch_target_final,
            branch_en_in    => branch_en_final,
            pc_out          => current_pc,
            ret_addr_out    => ret_addr,
            fetch_req_in    => fetch_req,
            instr_valid_out => instr_valid,
            instr_out       => rdat_instr,
            fetch_err_out   => fetch_err,
            fetch_busy_out  => fetch_busy,
            if_wb_mosi_out  => if_wb_mosi_out,
            if_wb_miso_in   => if_wb_miso_in
        );

    cpu_decode_inst : entity work.cpu_decode
        port map(
            instr_in     => current_instr,
            rs1_addr_out => rs1_addr,
            rs2_addr_out => rs2_addr,
            rd_addr_out  => rd_addr,
            imm_out      => imm_extended,
            -- replace with individual control signals to ALU
            opcode_out          => current_opcode,
            funct7_out          => current_func7,
            funct3_out          => current_func3,
            uses_writeback_out  => uses_writeback,
            write_load_out      => write_load,
            write_alu_out       => write_alu,
            write_ret_addr_out  => write_ret_addr,
            uses_mem_access_out => uses_mem_access,
            store_enable_out    => store_enable,
            opcode_err_out      => opcode_err
        );

    cpu_regs_inst : entity work.cpu_regs
        port map(
            CPU_CLK_IN           => clk,
            CPU_RST_IN           => reset,
            READ_PORT_A_ADDR_IN  => rs1_addr,
            READ_PORT_A_DATA_OUT => rs1_data,
            READ_PORT_B_ADDR_IN  => rs2_addr,
            READ_PORT_B_DATA_OUT => rs2_data,
            WRITE_PORT_ADDR_IN   => rd_addr,
            WRITE_PORT_DATA_IN   => write_reg_data,
            WRITE_PORT_EN_IN     => write_reg_we
        );

    cpu_alu_inst : entity work.cpu_alu
        port map(
            clk               => clk,
            alu_en_in         => alu_en,
            pc                => current_pc,
            rs1               => rs1_data,
            rs2               => rs2_data,
            imm               => imm_extended,
            alu_out           => alu_output,
            branch_en_out     => branch_en,   -- could be modified by an error during MEM access
            branch_target_out => branch_addr, -- could be modified by an error during MEM access
            opcode            => current_opcode,
            funct7            => current_func7,
            funct3            => current_func3,
            alu_func3_err_out => alu_func3_err
        );

    cpu_dataflow_inst : entity work.cpu_dataflow
        port map(
            clk                => clk,
            reset              => reset,
            alu_output_in      => alu_output,
            ret_addr_in        => ret_addr,
            rs2_data_in        => rs2_data,
            branch_en_in       => branch_en_reg,
            branch_en_out      => branch_en_final,
            branch_target_in   => branch_addr,
            branch_target_out  => branch_target_final,
            write_load_in      => write_load,
            write_alu_in       => write_alu,
            write_ret_addr_in  => write_ret_addr,
            write_reg_data_out => write_reg_data,
            addr_align_err_out => addr_align_err,
            mem_req_in         => mem_req,
            mem_busy_out       => mem_busy,
            mem_err_out        => mem_err,
            mem_done_out       => mem_done,
            mem_we_in          => store_enable,
            func3_in           => current_func3,
            mem_wb_mosi_out    => mem_wb_mosi_out,
            mem_wb_miso_in     => mem_wb_miso_in
        );
    cpu_control_inst : entity work.cpu_control
        port map(
            clk                => clk,
            reset              => reset,
            fetch_req_out      => fetch_req,
            fetch_busy_in      => fetch_busy,
            fetch_err_in       => fetch_err,
            instr_valid_in     => instr_valid,
            rdat_instr_in      => rdat_instr,
            current_instr_out  => current_instr,
            opcode_err_in      => opcode_err,
            alu_en_out         => alu_en,
            alu_err_in         => alu_func3_err,
            branch_en_alu_in   => branch_en,
            branch_en_reg_out  => branch_en_reg,
            uses_mem_access_in => uses_mem_access,
            uses_writeback_in  => uses_writeback,
            addr_align_err_in  => addr_align_err,
            mem_req_out        => mem_req,
            mem_busy_in        => mem_busy,
            mem_err_in         => mem_err,
            mem_done_in        => mem_done,
            write_reg_we_out   => write_reg_we,
            cpu_err_out        => cpu_err_out,
            extern_halt_in     => extern_halt_in
        );
end architecture;