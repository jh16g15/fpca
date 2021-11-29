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
begin
  opcode <= instr_in(6 downto 0);
  opcode_out <= opcode;
  
  -- not always used as these, but if we need them they are here
  rs1_addr_out <= instr_in(19 downto 15);
  rs2_addr_out <= instr_in(24 downto 20);
  rd_addr_out  <= instr_in(11 downto  7);



  imm_assemble : process(instr_in) is 
  begin
    -- defaults
    opcode_err <= '0';
    encoding <= R_type;

      -- decode the instruction format
      case (opcode) is
        when OPCODE_OP => 
          encoding <= R_type;
        
        when OPCODE_LOAD, OPCODE_OP_IMM, OPCODE_JALR, OPCODE_SYSTEM => 
          encoding <= I_type;

        when OPCODE_STORE => 
          encoding <= S_type;

        when OPCODE_BRANCH => 
          encoding <= B_type;
        
        when OPCODE_AUIPC, OPCODE_LUI => 
          encoding <= U_type;
        
        when OPCODE_JAL => 
          encoding <= J_type;

        when others => 
          opcode_err <= '1';

      end case;


      case(encoding) is 
        when R_type => 
          
        when I_type => 
        when S_type => 
        when B_type => 
        when U_type => 
        when J_type => 

      end case;



  end process;

    

end architecture;
