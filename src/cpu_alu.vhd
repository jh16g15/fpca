library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.riscv_instructions_pkg.all;

-- types of Jump instructions in RV32I:

-- Unconditional

entity cpu_alu is
  -- generic (

  -- )
  port (
    clk : in std_logic; -- unused, combinational module

    -- data inputs
    pc : in std_logic_vector(31 downto 0);
    rs1 : in std_logic_vector(31 downto 0);
    rs2 : in std_logic_vector(31 downto 0);
    imm : in std_logic_vector(31 downto 0); -- pre sign-extended in decode
    
    -- data outputs 
    alu_out : out std_logic_vector(31 downto 0);
    branch_en : out std_logic;

    -- control signals from instruction decode
    opcode : in std_logic_vector(6 downto 0);
    funct7 : in std_logic_vector(6 downto 0);
    funct3 : in std_logic_vector(2 downto 0)

  );
end entity;

architecture rtl of cpu_alu is
  constant ALU_A_RS1  : std_logic := '0';  
  constant ALU_A_PC   : std_logic := '1';  
  
  constant ALU_B_RS2  : std_logic := '0';  
  constant ALU_B_IMM  : std_logic := '1';  

  signal alu_A_sel : std_logic;
  signal alu_B_sel : std_logic;

  -- selected ALU input from muxes
  signal alu_A : std_logic_vector(31 downto 0);
  signal alu_B : std_logic_vector(31 downto 0);

  type t_alu_op is (ADD_SUB_op, SLL_op, SLT_op, SLTU_op, XOR_op, SRL_op, SRA_op, OR_op, AND_op);
  signal operation_type : t_alu_op;
begin

  -- alu input muxes
  alu_A <= rs1 when alu_A_sel = ALU_A_RS1 else pc;
  alu_B <= rs2 when alu_B_sel = ALU_B_RS2 else imm;

  -- alu_comb : process(all) is
  -- begin
  --   -- default outputs 
  --   branch_en <= '0';
  --   alu_out <= x"DEADBEEF";
  --   case(opcode) is 
  --     when OPCODE_LUI => 
  --       -- 
  --     when OPCODE_AUIPC => 
      
  --     when OPCODE_JAL => 
      
  --     when OPCODE_JALR => 

  --     when OPCODE_BRANCH => 
  --       case(funct3) is 
  --         when BRANCH_BEQ_FUNC3 => 
  --         when BRANCH_BNE_FUNC3 => 
  --         when BRANCH_BLT_FUNC3  => 
  --         when BRANCH_BGE_FUNC3  => 
  --         when BRANCH_BLTU_FUNC3 => 
  --         when BRANCH_BGEU_FUNC3 => 
  --         when others => 
  --       end case;
  --     when OPCODE_LOAD => 

  --     when OPCODE_STORE =>

  --     when OPCODE_OP =>
        
  --     when OPCODE_OP_IMM => 
      
  --   end case;
  -- end process;
    

    alu_op_select_comb : process (all) is
      
      -- main inputs/outputs
      variable alu_input_A : std_logic_vector(31 downto 0);
      variable alu_input_B : std_logic_vector(31 downto 0);
      variable alu_output  : std_logic_vector(31 downto 0);
      
      -- intermediate unsigned 
      variable alu_input_A_u : unsigned(31 downto 0);
      variable alu_input_B_u : unsigned(31 downto 0);
      variable alu_output_u  : unsigned(31 downto 0);
      
      -- intermediate signed
      variable alu_input_A_s : signed(31 downto 0);
      variable alu_input_B_s : signed(31 downto 0);
      variable alu_output_s  : signed(31 downto 0);

      variable shamt : unsigned(4 downto 0);
      variable shamt_int : natural range 0 to 31;

      variable sub_select : std_logic;
    begin
      -- set up the intermediate variables
      sub_select := funct7(5);
      alu_input_A_u := unsigned(alu_input_A);
      alu_input_B_u := unsigned(alu_input_B);
      alu_input_A_s := signed(alu_input_A);
      alu_input_B_s := signed(alu_input_B);

      shamt_int := to_integer(shamt);

      case(operation_type) is 
        when ADD_SUB_op =>                         
          if sub_select = '0' then 
            alu_output := std_logic_vector(alu_input_A_s + alu_input_B_s);
          else
            alu_output := std_logic_vector(alu_input_A_s - alu_input_B_s);
          end if;
        when SLL_op => -- shift left (signed/unsigned) <<
          alu_output := std_logic_vector(alu_input_A_u sll shamt_int);
          
        when SLT_op => -- set if A less than B
          if alu_input_A_s < alu_input_B_s then 
            alu_output := x"0000_0001";
          else
            alu_output := x"0000_0000";
          end if;
        when SLTU_op => -- set if A less than B (unsigned comparison)
          if alu_input_A_u < alu_input_B_u then 
            alu_output := x"0000_0001";
          else
            alu_output := x"0000_0000";
        end if;
        when XOR_op => 
          alu_output := alu_input_A xor alu_input_B;
        when SRL_op => -- logical shift right (unsigned) >>
          alu_output := std_logic_vector(alu_input_A_u srl shamt_int);
        when SRA_op => -- arithmetic shift right (signed) >>
          alu_output := std_logic_vector(alu_input_A_s srl shamt_int);
        when OR_op => 
          alu_output := alu_input_A or alu_input_B;
        when AND_op => 
          alu_output := alu_input_A and alu_input_B;
        when others =>
          null;
      end case;

    end process alu_op_select_comb;


end architecture;
