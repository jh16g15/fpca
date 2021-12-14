library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package riscv_instructions_pkg is

  constant INSTR_ADDR_W : integer := 32;
  constant REG_ADDR_W : integer := 5;
  constant IMM_ADDR_W : integer := 32;
  constant OPCODE_ADDR_W : integer := 7;
  constant FUNCT7_ADDR_W : integer := 7;
  constant FUNCT3_ADDR_W : integer := 3;

  type t_encoding is (R_type, I_type, S_type, B_type, U_type, J_type);

  -- Opcodes
  ------------------------------------
  -- most of these I am not implementing in RV32I
  constant OPCODE_LOAD : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"00_000_11"; -- I
  constant OPCODE_LOAD_FP : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"00_001_11"; -- Float
  constant OPCODE_CUSTOM0 : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"00_010_11";
  constant OPCODE_MISC_MEM : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"00_011_11"; -- I, FENCEs not implemented
  constant OPCODE_OP_IMM : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"00_100_11"; -- I 
  constant OPCODE_AUIPC : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"00_101_11"; -- I
  constant OPCODE_OP_IMM_32 : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"00_110_11"; -- 64+?

  constant OPCODE_STORE : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"01_000_11"; -- I
  constant OPCODE_STORE_FP : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"01_001_11"; -- Float
  constant OPCODE_CUSTOM1 : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"01_010_11";
  constant OPCODE_AMO : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"01_011_11"; -- Atomic
  constant OPCODE_OP : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"01_100_11"; -- I
  constant OPCODE_LUI : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"01_101_11"; -- I
  constant OPCODE_OP_32 : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"01_110_11"; -- 64+?

  constant OPCODE_MADD : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"10_000_11"; -- Float
  constant OPCODE_MSUB : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"10_001_11"; -- Float
  constant OPCODE_NMSUB : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"10_010_11"; -- Float
  constant OPCODE_NMADD : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"10_011_11"; -- Float
  constant OPCODE_OP_FP : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"10_100_11"; -- Float
  -- constant OPCODE_RESERVED : std_logic_vector(OPCODE_ADDR_W-1 downto 0) := b"10_101_11";
  constant OPCODE_CUSTOM2 : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"10_110_11";

  constant OPCODE_BRANCH : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"11_000_11"; -- I
  constant OPCODE_JALR : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"11_001_11"; -- I
  -- constant OPCODE_RESERVED : std_logic_vector(OPCODE_ADDR_W-1 downto 0) := b"11_010_11";
  constant OPCODE_JAL : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"11_011_11"; -- I
  constant OPCODE_SYSTEM : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"11_100_11"; -- I
  -- constant OPCODE_RESERVED : std_logic_vector(OPCODE_ADDR_W-1 downto 0) := b"11_101_11";
  constant OPCODE_CUSTOM3 : std_logic_vector(OPCODE_ADDR_W - 1 downto 0) := b"11_110_11";
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
  --! Sign Extends a std_logic_vector
  function extend_slv(in_vec : std_logic_vector; new_len : integer := 32) return std_logic_vector;
  --! converts integer to "signed" slv 
  function int2slv(in_int : integer; new_len : integer := 32) return std_logic_vector;
  --! converts integer to "unsigned" slv 
  function uint2slv(in_uint : integer; new_len : integer := 32) return std_logic_vector;
  --! converts "unsigned" slv to integer
  function slv2uint(in_vec : std_logic_vector) return integer;
  --! converts "signed" slv to integer
  function slv2int(in_vec : std_logic_vector) return integer;
  --! adds two std_logic_vectors as "unsigned" and returns as a slv
  function u_add(a, b : std_logic_vector) return std_logic_vector;
  --! adds two std_logic_vectors as "signed" and returns as a slv
  function s_add(a, b : std_logic_vector) return std_logic_vector;
  function s_sub(a, b : std_logic_vector) return std_logic_vector;

end package;

package body riscv_instructions_pkg is

  --! Sign Extends a std_logic_vector
  function extend_slv(in_vec : std_logic_vector; new_len : integer := 32) return std_logic_vector is
  begin
    return std_logic_vector(resize(signed(in_vec), new_len));
  end function;

  --! converts integer to "signed" slv 
  function int2slv(in_int : integer; new_len : integer := 32) return std_logic_vector is
  begin
    return std_logic_vector(to_signed(in_int, new_len));
  end function;
  --! converts integer to "unsigned" slv 
  function uint2slv(in_uint : integer; new_len : integer := 32) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(in_uint, new_len));
  end function;

  --! converts "unsigned" slv to integer
  function slv2uint(in_vec : std_logic_vector) return integer is
  begin
    return to_integer(unsigned(in_vec));
  end function;

  --! converts "signed" slv to integer
  function slv2int(in_vec : std_logic_vector) return integer is
  begin
    return to_integer(signed(in_vec));
  end function;

  --! adds two std_logic_vectors as "unsigned" and returns as a slv
  function u_add(a, b : std_logic_vector) return std_logic_vector is
  begin
    return std_logic_vector(unsigned(a) + unsigned(b));
  end function;

  --! adds two std_logic_vectors as "signed" and returns as a slv
  function s_add(a, b : std_logic_vector) return std_logic_vector is
  begin
    return std_logic_vector(signed(a) + signed(b));
  end function;

  --! subtracts two std_logic_vectors as "signed" and returns as a slv
  function s_sub(a, b : std_logic_vector) return std_logic_vector is
  begin
    return std_logic_vector(signed(a) - signed(b));
  end function;
end package body;