library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package riscv_instructions_pkg is 

    type t_encoding is (R_type, I_type, S_type, B_type, U_type, J_type);

    -- Opcodes
    ------------------------------------
    -- most of these I am not implementing in RV32I
    constant OPCODE_LOAD        : std_logic_vector(6 downto 0) := b"00_000_11"; -- I
    constant OPCODE_LOAD_FP     : std_logic_vector(6 downto 0) := b"00_001_11"; -- Float
    constant OPCODE_CUSTOM0     : std_logic_vector(6 downto 0) := b"00_010_11"; 
    constant OPCODE_MISC_MEM    : std_logic_vector(6 downto 0) := b"00_011_11"; -- I, FENCEs not implemented
    constant OPCODE_OP_IMM      : std_logic_vector(6 downto 0) := b"00_100_11"; -- I 
    constant OPCODE_AUIPC       : std_logic_vector(6 downto 0) := b"00_101_11"; -- I
    constant OPCODE_OP_IMM_32   : std_logic_vector(6 downto 0) := b"00_110_11"; -- 64+?

    constant OPCODE_STORE       : std_logic_vector(6 downto 0) := b"01_000_11"; -- I
    constant OPCODE_STORE_FP    : std_logic_vector(6 downto 0) := b"01_001_11"; -- Float
    constant OPCODE_CUSTOM1     : std_logic_vector(6 downto 0) := b"01_010_11";
    constant OPCODE_AMO         : std_logic_vector(6 downto 0) := b"01_011_11"; -- Atomic
    constant OPCODE_OP          : std_logic_vector(6 downto 0) := b"01_100_11"; -- I
    constant OPCODE_LUI         : std_logic_vector(6 downto 0) := b"01_101_11"; -- I
    constant OPCODE_OP_32       : std_logic_vector(6 downto 0) := b"01_110_11"; -- 64+?

    constant OPCODE_MADD        : std_logic_vector(6 downto 0) := b"10_000_11"; -- Float
    constant OPCODE_MSUB        : std_logic_vector(6 downto 0) := b"10_001_11"; -- Float
    constant OPCODE_NMSUB       : std_logic_vector(6 downto 0) := b"10_010_11"; -- Float
    constant OPCODE_NMADD       : std_logic_vector(6 downto 0) := b"10_011_11"; -- Float
    constant OPCODE_OP_FP       : std_logic_vector(6 downto 0) := b"10_100_11"; -- Float
    -- constant OPCODE_RESERVED : std_logic_vector(6 downto 0) := b"10_101_11";
    constant OPCODE_CUSTOM2     : std_logic_vector(6 downto 0) := b"10_110_11";

    constant OPCODE_BRANCH      : std_logic_vector(6 downto 0) := b"11_000_11"; -- I
    constant OPCODE_JALR        : std_logic_vector(6 downto 0) := b"11_001_11"; -- I
    -- constant OPCODE_RESERVED : std_logic_vector(6 downto 0) := b"11_010_11";
    constant OPCODE_JAL         : std_logic_vector(6 downto 0) := b"11_011_11"; -- I
    constant OPCODE_SYSTEM      : std_logic_vector(6 downto 0) := b"11_100_11"; -- I
    -- constant OPCODE_RESERVED : std_logic_vector(6 downto 0) := b"11_101_11";
    constant OPCODE_CUSTOM3     : std_logic_vector(6 downto 0) := b"11_110_11";
    
    
    -- Instruction Encoding Definitions:
    ----------------------------------------------
    constant ENC_TYPE_LOAD      : t_encoding := I_type;
    -- constant ENC_TYPE_MISC_MEM  : t_encoding := ;
    constant ENC_TYPE_OP_IMM    : t_encoding := I_type;
    constant ENC_TYPE_AUIPC     : t_encoding := U_type;
    constant ENC_TYPE_STORE     : t_encoding := S_type;
    constant ENC_TYPE_OP        : t_encoding := R_type;
    constant ENC_TYPE_LUI       : t_encoding := U_type;
    constant ENC_TYPE_BRANCH    : t_encoding := B_type;
    constant ENC_TYPE_JALR      : t_encoding := I_type;
    constant ENC_TYPE_JAL       : t_encoding := J_type;
    constant ENC_TYPE_SYSTEM    : t_encoding := I_type;
    
end package;