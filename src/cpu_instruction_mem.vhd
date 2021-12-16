library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use work.riscv_instructions_pkg.all;

--! Fetches 32bit words
entity cpu_instruction_mem is
  generic (
    G_IMEM_ADDR_W : integer := 8;  -- =256 words
    G_INSTR_W : integer := 32;
    G_INIT_SRC : string := "";  -- or filepath
    G_MEM_IMPL : string := "bram" -- 
  );
  port (
    clk : in std_logic;
       
    addr_in : in std_logic_vector(G_IMEM_ADDR_W+2-1 downto 0);  -- note, this is a BYTE ADDRESS, so we don't use [1:0], so width is 2 bits wider than word addr width
    -- addr_valid : in std_logic;

    -- instr_valid : out std_logic;
    instruction_out : out std_logic_vector(G_INSTR_W-1 downto 0)
  );
end entity;

architecture rtl of cpu_instruction_mem is
  constant C_INSTR_DEPTH : integer := 2 ** G_IMEM_ADDR_W; -- number of WORDS, not BYTES
  type t_mem is array (0 to C_INSTR_DEPTH-1) of std_logic_vector(G_INSTR_W-1 downto 0);
  
  function f_init_mem return t_mem is 
    variable init_mem : t_mem := (others => (others=> '0'));
  begin 
    if G_INIT_SRC = "" then
      -- init from constants here
      init_mem(0) := f_build_instr(opcode => OPCODE_OP_IMM, rs1 => b"0_0000", rd => b"0_0001", imm12 => x"400", funct3 => OP_IMM_ADDI_FUNC3);  -- Load x"400" into x1
      init_mem(1) := f_build_instr(opcode => OPCODE_OP_IMM, rs1 => b"0_0000", rd => b"0_0010", imm12 => x"001", funct3 => OP_IMM_ADDI_FUNC3);  -- Load x"001" into x2
      init_mem(2) := f_build_instr(opcode => OPCODE_OP_IMM, rs1 => b"0_0001", rs2 => b"0_0010", rd => b"0_0011", funct3 => OP_ADD_FUNC3, funct7 => OP_ADD_FUNC7);  -- add x1 to x2 and store in x3
    else 
      -- load from file
      null;
    end if;
    return init_mem;
  end function f_init_mem;
  
  signal mem : t_mem := f_init_mem;

  signal word_addr : std_logic_vector(G_IMEM_ADDR_W-1 downto 0);

begin

  word_addr <= addr_in(addr_in'left downto 2);  -- convert byte address to word address

gen_bram :  if G_MEM_IMPL = "bram" generate
  
  mem_proc : process(clk) is 
  begin 
    if rising_edge(clk) then
      instruction_out <= mem(slv2uint(word_addr));
    end if;

  end process mem_proc;
  

end generate;

end architecture;