library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.riscv_instructions_pkg.all;

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
    branch_target_out : out std_logic_vector(31 downto 0);

    -- control signals from instruction decode
    opcode : in std_logic_vector(6 downto 0);
    funct7 : in std_logic_vector(6 downto 0);
    funct3 : in std_logic_vector(2 downto 0)

  );
end entity;

architecture rtl of cpu_alu is

begin

  alu_comb : process (all) is
  begin
    -- defaults
    alu_out <= x"DEADBEEF";
    branch_en <= '0';
    branch_target_out <= x"DEADBEEF";
    opcode_case : case(opcode) is
      when OPCODE_LUI => -- alu_out = Imm
        alu_out <= imm;
      when OPCODE_AUIPC => -- PC+Imm
        alu_out <= u_add(pc, imm);
      when OPCODE_JAL => -- PC+Imm, handle in Branch Target Adder
        branch_en <= '1';
        branch_target_out <= u_add(pc, imm);
      when OPCODE_JALR => -- RS1 + Imm,  then send result to branch target adder
        branch_en <= '1';
        branch_target_out <= u_add(u_add(rs1, imm), pc); -- ordering?
      when OPCODE_BRANCH => 
        branch_target_out <= u_add(pc, imm);  -- all branch targets the same
        case(funct3) is
          when BRANCH_BEQ_FUNC3  => branch_en <= '1' when rs1 = rs2 else '0';
          when BRANCH_BNE_FUNC3  => branch_en <= '1' when rs1 /= rs2 else '0';
          when BRANCH_BLT_FUNC3  => branch_en <= '1' when signed(rs1) < signed(rs2) else '0';
          when BRANCH_BGE_FUNC3  => branch_en <= '1' when signed(rs1) >= signed(rs2) else '0';
          when BRANCH_BLTU_FUNC3 => branch_en <= '1' when unsigned(rs1) < unsigned(rs2) else '0';
          when BRANCH_BGEU_FUNC3 => branch_en <= '1' when unsigned(rs1) >= unsigned(rs2) else '0';
          when others => report "Invalid FUNC3 for BRANCH" severity Failure;
      end case;
      when OPCODE_LOAD => -- address to fetch from = rs1+imm
        alu_out <= u_add(rs1, imm);
      when OPCODE_STORE => -- address to write to = rs1+imm
        alu_out <= u_add(rs1, imm);
      when OPCODE_OP => -- register-register arithmetic 
        case(funct3) is
          when OP_ADD_FUNC3   => alu_out <= s_add(rs1, rs2) when (funct7(5) = '0') else s_sub(rs1, rs2);
          when OP_SLT_FUNC3   => alu_out <= x"0000_0001" when signed(rs1) < signed(rs2) else x"0000_0000";  
          when OP_SLTU_FUNC3  => alu_out <= x"0000_0001" when unsigned(rs1) < unsigned(rs2) else x"0000_0000";  
          when OP_XOR_FUNC3   => alu_out <= rs1 xor rs2;
          when OP_OR_FUNC3    => alu_out <= rs1 or rs2;
          when OP_AND_FUNC3   => alu_out <= rs1 and rs2;
          when OP_SLL_FUNC3   => alu_out <= rs1 sll slv2uint(rs2(4 downto 0));
          when OP_SRL_FUNC3   => alu_out <= std_logic_vector(shift_right(unsigned(rs1), slv2uint(rs2(4 downto 0)))) when funct7(5) = '0' else std_logic_vector(shift_right(signed(rs1), slv2uint(rs2(4 downto 0))));
          when others => report "Invalid FUNC3 for OP" severity Failure;
        end case;
      when OPCODE_OP_IMM => --register-immmediate arithmetic 
        case(funct3) is
          when OP_ADD_FUNC3   => alu_out <= s_add(rs1, imm);
          when OP_SLT_FUNC3   => alu_out <= x"0000_0001" when signed(rs1) < signed(imm) else x"0000_0000";  
          when OP_SLTU_FUNC3  => alu_out <= x"0000_0001" when unsigned(rs1) < unsigned(imm) else x"0000_0000";  
          when OP_XOR_FUNC3   => alu_out <= rs1 xor imm;
          when OP_OR_FUNC3    => alu_out <= rs1 or imm;
          when OP_AND_FUNC3   => alu_out <= rs1 and imm;
          when OP_SLL_FUNC3   => alu_out <= rs1 sll slv2uint(imm(4 downto 0));
          when OP_SRL_FUNC3   => alu_out <= std_logic_vector(shift_right(unsigned(rs1), slv2uint(imm(4 downto 0)))) when funct7(5) = '0' else std_logic_vector(shift_right(signed(rs1), slv2uint(imm(4 downto 0))));
          when others => report "Invalid FUNC3 for OP-IMM" severity Failure;
        end case;
      when others => report "Invalid Opcode" severity Failure;
    end case opcode_case;
  end process alu_comb;

end architecture;