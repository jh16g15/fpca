library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.riscv_instructions_pkg.all;

-- 
-- Instruction Decoder
--
-- Extracts Register Addresses, assembles and sign-extends immediates
-- For now is combinational
--
-- Instruction Codings: R, I, S, B, U, J
entity cpu_decode is
  -- generic (

  -- )
  port (
    
    instr_in : in std_logic_vector(31 downto 0);
    
    -- Register Addresses
    rs1_addr_out : out std_logic_vector(4 downto 0);  -- R, I, S, B
    rs2_addr_out : out std_logic_vector(4 downto 0);  -- R, S, B
    rd_addr_out  : out std_logic_vector(4 downto 0);  -- R, I, U, J

    -- Sign Extended Immediate
    imm_out : out std_logic_vector(31 downto 0);      -- I, S, B, U, J
    
    -- control signals
    opcode_out : out std_logic_vector(6 downto 0);    -- ALL
    funct7_out : out std_logic_vector(6 downto 0);    -- R
    funct3_out : out std_logic_vector(2 downto 0)     -- R, I, S, B

  );
end entity;

architecture rtl of cpu_decode is
    signal opcode : std_logic_vector(6 downto 0);
    signal opcode_err : std_logic;
    
    signal encoding : t_encoding;

    
    signal imm32 : std_logic_vector(31 downto 0);

begin
  opcode <= instr_in(6 downto 0);
  opcode_out <= opcode;
  
  -- not always used as these, but if we need them they are here
  rs1_addr_out <= instr_in(19 downto 15);
  rs2_addr_out <= instr_in(24 downto 20);
  rd_addr_out  <= instr_in(11 downto  7);

  funct3_out <= instr_in(14 downto 12);
  funct7_out <= instr_in(31 downto 25);

  imm_out <= imm32;


  imm_assemble : process(all) is 
    variable imm12 : std_logic_vector(11 downto 0);
    variable imm20 : std_logic_vector(19 downto 0);
  begin
    -- defaults
    opcode_err <= '0';
    encoding <= R_type;
    imm32 <= (others => '0');

      -- decode the instruction format
      case (opcode) is
        when OPCODE_OP => 
          encoding <= R_type;
        
        when OPCODE_LOAD | OPCODE_OP_IMM | OPCODE_JALR | OPCODE_SYSTEM => 
          encoding <= I_type;

        when OPCODE_STORE => 
          encoding <= S_type;

        when OPCODE_BRANCH => 
          encoding <= B_type;
        
        when OPCODE_AUIPC | OPCODE_LUI => 
          encoding <= U_type;
        
        when OPCODE_JAL => 
          encoding <= J_type;

        when others => 
          opcode_err <= '1';

      end case;

      -- Immediate rearranging
      case(encoding) is 
        when R_type => 
          imm32 <= (others => '-'); -- is "don't care" supported?
        when I_type => 
          imm12 := instr_in(31 downto 20);
          imm32(31 downto 12) <= (others => instr_in(31)); -- sign extension
          imm32(11 downto 0) <= imm12;

        when S_type => 
          imm12(11 downto 5) := instr_in(31 downto 25);
          imm12( 4 downto 0) := instr_in(11 downto 7);
          imm32(31 downto 12) <= (others => instr_in(31)); -- sign extension
          imm32(11 downto 0) <= imm12;
        when B_type => -- imm[12:1], as in 2 byte increments, so we '-1' from each index
          imm12(12-1)           := instr_in(31); -- technically bits 12
          imm12(10-1 downto 5-1)   := instr_in(30 downto 25); -- technically bits 10:5
          imm12( 4-1 downto 1-1)  := instr_in(11 downto 8); -- technically bits 4:1
          imm12(11-1)           := instr_in(7); -- technically bits 11

          imm32(31 downto 13) <= (others => instr_in(31)); -- sign extension
          imm32(12 downto 1) <= imm12;
          imm32(0) <= '0';
        when U_type => -- for LUI/AUIPC, load top 20 bits
          imm20 := instr_in(31 downto 12);
          imm32(31 downto 12) <= imm20;
          imm32(11 downto  0) <= (others => '0');
        when J_type => -- imm[20:1], as in 2 byte increments, so we '-1' from each index to match the RV32 numbering
          imm20(20-1) := instr_in(31);
          imm20(10-1 downto 1-1) := instr_in(30 downto 21);
          imm20(11-1) := instr_in(20);
          imm20(19-1 downto 12-1) := instr_in(19 downto 12);

          imm32(31 downto 21) <= (others => instr_in(31)); -- sign extension
          imm32(20 downto  1) <= imm20;
          imm32(0) <= '0';

        when others => 
          imm32 <= (others => '-'); -- is "don't care" supported?

      end case;



  end process;

    

end architecture;
