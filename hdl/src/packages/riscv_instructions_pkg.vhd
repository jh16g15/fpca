library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;

package riscv_instructions_pkg is

  constant INSTR_W : integer := 32;
  constant REG_ADDR_W : integer := 5;
  constant IMM_W : integer := 32;
  constant OPCODE_W : integer := 7;
  constant FUNCT7_W : integer := 7;
  constant FUNCT3_W : integer := 3;


  -- type t_control_sigs is record
  --   alu_add : std_logic;


  -- end record t_control_sigs;


  type t_encoding is (R_type, I_type, S_type, B_type, U_type, J_type);
  type t_dbg_decode is (ERR, LUI, AUIPC, JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU, LOAD, STORE, ADD_SUB, SLT, SLTU, XORR, ORR, ANDR, SLLR, SR_LA, ADDI, SLTI, SLTUI, XORI, ORI, ANDI, SLLI, SRLAI );

  -- Instruction Encodings
  

--+----------------------------+----------+------------+---------+------------------+---------+---------+---------+
--|          31 - 25           | 24 - 20  |  19 - 15   | 14 - 12 |      11 - 7      |  6 - 0  |  Type   | Example |
--+----------------------------+----------+------------+---------+------------------+---------+---------+---------+
--| funct7                     | rs2      | rs1        | funct3  | rd               | opcode  | R-Type  | OP      |
--|              Imm[11:0]                | rs1        | funct3  | rd               | opcode  | I-Type  | OP-IMM  |
--| Imm[11:5]                  | rs2      | rs1        | funct3  | imm[4:0]         | opcode  | S-Type  | Store   |
--| Imm[12] Imm[10:5]          | rs2      | rs1        | funct3  | Imm[4:1] Imm[11] | opcode  | B-type  | Branch  |
--|                                  Imm[31:12]                  | rd               | opcode  | U-Type  | LUI     |
--| Imm[20]        Imm[10:1]     Imm[11]  |       Imm[19:12]     | rd               | opcode  | J-Type  | JAL     |
--+----------------------------+----------+------------+---------+------------------+---------+---------+---------+

  --! Assembles a 32 bit instruction from its arguments
  function f_build_instr(
    opcode : std_logic_vector(OPCODE_W-1 downto 0) := (others => '0');
    rs1 : std_logic_vector(REG_ADDR_W-1 downto 0) := (others => '0');
    rs2 : std_logic_vector(REG_ADDR_W-1 downto 0) := (others => '0');
    rd  : std_logic_vector(REG_ADDR_W-1 downto 0) := (others => '0');
    funct3 : std_logic_vector(FUNCT3_W-1 downto 0) := (others => '0');
    funct7 : std_logic_vector(FUNCT7_W-1 downto 0) := (others => '0');
    Imm12 : std_logic_vector(12-1 downto 0) := (others => '0');
    Imm20 : std_logic_vector(20-1 downto 0) := (others => '0')
    ) return std_logic_vector;

  -- Opcodes
  ------------------------------------
  -- most of these I am not implementing in RV32I
  constant OPCODE_LOAD : std_logic_vector(OPCODE_W - 1 downto 0) := b"00_000_11"; -- I
  constant OPCODE_LOAD_FP : std_logic_vector(OPCODE_W - 1 downto 0) := b"00_001_11"; -- Float
  constant OPCODE_CUSTOM0 : std_logic_vector(OPCODE_W - 1 downto 0) := b"00_010_11";
  constant OPCODE_MISC_MEM : std_logic_vector(OPCODE_W - 1 downto 0) := b"00_011_11"; -- I, FENCEs not implemented
  constant OPCODE_OP_IMM : std_logic_vector(OPCODE_W - 1 downto 0) := b"00_100_11"; -- I 
  constant OPCODE_AUIPC : std_logic_vector(OPCODE_W - 1 downto 0) := b"00_101_11"; -- I
  constant OPCODE_OP_IMM_32 : std_logic_vector(OPCODE_W - 1 downto 0) := b"00_110_11"; -- 64+?

  constant OPCODE_STORE : std_logic_vector(OPCODE_W - 1 downto 0) := b"01_000_11"; -- I
  constant OPCODE_STORE_FP : std_logic_vector(OPCODE_W - 1 downto 0) := b"01_001_11"; -- Float
  constant OPCODE_CUSTOM1 : std_logic_vector(OPCODE_W - 1 downto 0) := b"01_010_11";
  constant OPCODE_AMO : std_logic_vector(OPCODE_W - 1 downto 0) := b"01_011_11"; -- Atomic
  constant OPCODE_OP : std_logic_vector(OPCODE_W - 1 downto 0) := b"01_100_11"; -- I
  constant OPCODE_LUI : std_logic_vector(OPCODE_W - 1 downto 0) := b"01_101_11"; -- I
  constant OPCODE_OP_32 : std_logic_vector(OPCODE_W - 1 downto 0) := b"01_110_11"; -- 64+?

  constant OPCODE_MADD : std_logic_vector(OPCODE_W - 1 downto 0) := b"10_000_11"; -- Float
  constant OPCODE_MSUB : std_logic_vector(OPCODE_W - 1 downto 0) := b"10_001_11"; -- Float
  constant OPCODE_NMSUB : std_logic_vector(OPCODE_W - 1 downto 0) := b"10_010_11"; -- Float
  constant OPCODE_NMADD : std_logic_vector(OPCODE_W - 1 downto 0) := b"10_011_11"; -- Float
  constant OPCODE_OP_FP : std_logic_vector(OPCODE_W - 1 downto 0) := b"10_100_11"; -- Float
  -- constant OPCODE_RESERVED : std_logic_vector(OPCODE_W-1 downto 0) := b"10_101_11";
  constant OPCODE_CUSTOM2 : std_logic_vector(OPCODE_W - 1 downto 0) := b"10_110_11";

  constant OPCODE_BRANCH : std_logic_vector(OPCODE_W - 1 downto 0) := b"11_000_11"; -- I
  constant OPCODE_JALR : std_logic_vector(OPCODE_W - 1 downto 0) := b"11_001_11"; -- I
  -- constant OPCODE_RESERVED : std_logic_vector(OPCODE_W-1 downto 0) := b"11_010_11";
  constant OPCODE_JAL : std_logic_vector(OPCODE_W - 1 downto 0) := b"11_011_11"; -- I
  constant OPCODE_SYSTEM : std_logic_vector(OPCODE_W - 1 downto 0) := b"11_100_11"; -- I
  -- constant OPCODE_RESERVED : std_logic_vector(OPCODE_W-1 downto 0) := b"11_101_11";
  constant OPCODE_CUSTOM3 : std_logic_vector(OPCODE_W - 1 downto 0) := b"11_110_11";
  -- Instruction Encoding Definitions:
  ----------------------------------------------
  constant ENC_TYPE_LOAD : t_encoding := I_type;
  -- constant ENC_TYPE_MISC_MEM  : t_encoding := ;
  constant ENC_TYPE_OP_IMM : t_encoding := I_type;
  constant ENC_TYPE_AUIPC : t_encoding := U_type;
  constant ENC_TYPE_STORE : t_encoding := S_type;
  constant ENC_TYPE_OP : t_encoding := R_type;
  constant ENC_TYPE_LUI : t_encoding := U_type;
  constant ENC_TYPE_BRANCH : t_encoding := B_type;
  constant ENC_TYPE_JALR : t_encoding := I_type;
  constant ENC_TYPE_JAL : t_encoding := J_type;
  constant ENC_TYPE_SYSTEM : t_encoding := I_type;

  -- ALU decoding

  -- LUI :
  -- Set ALU muxes to
  -- AUIPC : 
  -- Set ALU muxes to

  -- JAL : 
  -- Uses BRANCH TARGET ADDER in dataflow/control section (have in ALU block anyway?)
  --  PC+4 sent directly through from Program Counter block to dataflow muxes for Return Address

  -- JALR : 
  -- Set ALU muxes to

  -- Branch : 
  -- Set ALU muxes to
  constant BRANCH_BEQ_FUNC3 : std_logic_vector(2 downto 0) := b"000"; -- A = B?
  constant BRANCH_BNE_FUNC3 : std_logic_vector(2 downto 0) := b"001"; -- A = B? (inverse)
  constant BRANCH_BLT_FUNC3 : std_logic_vector(2 downto 0) := b"100"; -- A < B (signed)
  constant BRANCH_BGE_FUNC3 : std_logic_vector(2 downto 0) := b"101"; -- A >= B (signed)
  constant BRANCH_BLTU_FUNC3 : std_logic_vector(2 downto 0) := b"110"; -- A < B (unsigned)
  constant BRANCH_BGEU_FUNC3 : std_logic_vector(2 downto 0) := b"111"; -- A >= B (unsigned)

  constant LOAD_LB_FUNC3 : std_logic_vector(2 downto 0) := b"000";
  constant LOAD_LH_FUNC3 : std_logic_vector(2 downto 0) := b"001";
  constant LOAD_LW_FUNC3 : std_logic_vector(2 downto 0) := b"010";
  constant LOAD_LBU_FUNC3 : std_logic_vector(2 downto 0) := b"100";
  constant LOAD_LHU_FUNC3 : std_logic_vector(2 downto 0) := b"101";

  constant STORE_SB_FUNC3 : std_logic_vector(2 downto 0) := b"000";
  constant STORE_SH_FUNC3 : std_logic_vector(2 downto 0) := b"001";
  constant STORE_SW_FUNC3 : std_logic_vector(2 downto 0) := b"010";

  --Set ALU muxes to rs1, Imm
  constant OP_IMM_ADDI_FUNC3 : std_logic_vector(2 downto 0) := b"000"; -- A+B 
  constant OP_IMM_SLTI_FUNC3 : std_logic_vector(2 downto 0) := b"010"; -- A<B (signed)
  constant OP_IMM_SLTIU_FUNC3 : std_logic_vector(2 downto 0) := b"011"; -- A<B (unsigned)
  constant OP_IMM_XORI_FUNC3 : std_logic_vector(2 downto 0) := b"100"; -- A XOR B 
  constant OP_IMM_ORI_FUNC3 : std_logic_vector(2 downto 0) := b"110"; -- A OR B
  constant OP_IMM_ANDI_FUNC3 : std_logic_vector(2 downto 0) := b"111"; -- A AND B
  constant OP_IMM_SLLI_FUNC3 : std_logic_vector(2 downto 0) := b"001"; -- A << B 
  constant OP_IMM_SRLI_FUNC3 : std_logic_vector(2 downto 0) := b"101"; -- A >> B (logical, see f7)
  constant OP_IMM_SRAI_FUNC3 : std_logic_vector(2 downto 0) := b"101"; -- A >> B (arith, see f7)

  constant OP_IMM_SRLI_FUNC7 : std_logic_vector(6 downto 0) := b"000_0000";
  constant OP_IMM_SRAI_FUNC7 : std_logic_vector(6 downto 0) := b"010_0000";

  --Set ALU muxes to rs1, rs2
  constant OP_ADD_FUNC3 : std_logic_vector(2 downto 0) := b"000"; -- A+B (see f7)
  constant OP_SUB_FUNC3 : std_logic_vector(2 downto 0) := b"000"; -- A-B (see f7)
  constant OP_SLT_FUNC3 : std_logic_vector(2 downto 0) := b"010"; -- A<B (signed)
  constant OP_SLTU_FUNC3 : std_logic_vector(2 downto 0) := b"011"; -- A<B (unsigned)  
  constant OP_XOR_FUNC3 : std_logic_vector(2 downto 0) := b"100"; -- A XOR B 
  constant OP_OR_FUNC3 : std_logic_vector(2 downto 0) := b"110"; -- A OR B
  constant OP_AND_FUNC3 : std_logic_vector(2 downto 0) := b"111"; -- A AND B
  constant OP_SLL_FUNC3 : std_logic_vector(2 downto 0) := b"001"; -- A << B 
  constant OP_SRL_FUNC3 : std_logic_vector(2 downto 0) := b"101"; -- A >> B (logical, see f7)
  constant OP_SRA_FUNC3 : std_logic_vector(2 downto 0) := b"101"; -- A >> B (arith, see f7)

  constant OP_ADD_FUNC7 : std_logic_vector(6 downto 0) := b"000_0000";
  constant OP_SUB_FUNC7 : std_logic_vector(6 downto 0) := b"010_0000";
  constant OP_SRL_FUNC7 : std_logic_vector(6 downto 0) := b"000_0000";
  constant OP_SRA_FUNC7 : std_logic_vector(6 downto 0) := b"010_0000";
  

end package;

package body riscv_instructions_pkg is

  --! Assembles a 32 bit instruction from its arguments
  function f_build_instr(
  opcode : std_logic_vector(OPCODE_W-1 downto 0) := (others => '0');
  rs1 : std_logic_vector(REG_ADDR_W-1 downto 0) := (others => '0');
  rs2 : std_logic_vector(REG_ADDR_W-1 downto 0) := (others => '0');
  rd : std_logic_vector(REG_ADDR_W-1 downto 0) := (others => '0');
  funct3 : std_logic_vector(FUNCT3_W-1 downto 0) := (others => '0');
  funct7 : std_logic_vector(FUNCT7_W-1 downto 0) := (others => '0');
  Imm12 : std_logic_vector(12-1 downto 0) := (others => '0');
  Imm20 : std_logic_vector(20-1 downto 0) := (others => '0')
  ) return std_logic_vector is 
    variable enc : t_encoding;
    variable instr : std_logic_vector(INSTR_W-1 downto 0) := (others => '0');
  begin
    case (opcode) is
      when OPCODE_OP => enc := R_type;
      when OPCODE_LOAD | OPCODE_OP_IMM | OPCODE_JALR | OPCODE_SYSTEM => enc := I_type;
      when OPCODE_STORE => enc := S_type;
      when OPCODE_BRANCH => enc := B_type;
      when OPCODE_AUIPC | OPCODE_LUI => enc := U_type;
      when OPCODE_JAL => enc := J_type;
      when others => null;
    end case;
    case(enc) is
      when R_type => instr := funct7 & rs2 & rs1 & funct3 & rd & opcode; 
      when I_type => instr := imm12  & rs1 & funct3 & rd & opcode;
      when S_type => instr := imm12(11 downto 5) & rs2 & rs1 & funct3 & imm12(4 downto 0) & opcode;      
      when B_type => instr := imm12(12-1) & imm12(10-1 downto 5-1) & rs2 & rs1 & funct3 & imm12(4-1 downto 1-1) & imm12(11-1) & opcode;
      when U_type => instr := imm20 & rd & opcode;
      when J_type => instr := imm20(20-1) & imm20(10-1 downto 1-1)  & imm20(11-1)  & imm20(19-1 downto 12-1)  & rd & opcode;
    end case;
    return instr;
  end function f_build_instr;

  
end package body;