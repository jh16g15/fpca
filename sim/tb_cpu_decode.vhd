
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
-- use std.textio.all;
library vunit_lib;
context vunit_lib.vunit_context;

use work.riscv_instructions_pkg.all;

entity tb_cpu_decode is
    generic (runner_cfg : string);
end entity tb_cpu_decode;

architecture rtl of tb_cpu_decode is
    signal clk : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    signal reset : std_logic := '1';

    signal instr_in     : std_logic_vector(INSTR_ADDR_W-1 downto 0); 
    signal rs1_addr_out : std_logic_vector(REG_ADDR_W-1 downto 0);  
    signal rs2_addr_out : std_logic_vector(REG_ADDR_W-1 downto 0);  
    signal rd_addr_out  : std_logic_vector(REG_ADDR_W-1 downto 0); 
    signal imm_out      : std_logic_vector(IMM_ADDR_W-1 downto 0);   
    signal opcode_out   : std_logic_vector(OPCODE_ADDR_W-1 downto 0); 
    signal funct7_out   : std_logic_vector(FUNCT7_ADDR_W-1 downto 0); 
    signal funct3_out   : std_logic_vector(FUNCT3_ADDR_W-1 downto 0); 



    
    impure function add_instrs return integer_array_t is
        -- for unsigned, needs to be between 1 and 31 bits - 32bit ints must be signed
        variable tmp : integer_array_t := new_1d(length=>10, bit_width=>32, is_signed=>true);
        variable int : integer := 0;
    begin
        report to_hstring(to_signed(int, 32));
        for i in 0 to 9 loop
            info( to_hstring(to_signed(get(tmp, i), 32)));
        end loop;
        return tmp;    
    end function;
        
    signal instructions : integer_array_t := add_instrs;    
begin

    clk <= not clk after CLK_PERIOD/2;
    reset <= '0' after 15 ns;
    
    u_cpu_decode : entity work.cpu_decode
    Port map (
        instr_in => instr_in,
        rs1_addr_out => rs1_addr_out,
        rs2_addr_out => rs2_addr_out,
        rd_addr_out => rd_addr_out,
        imm_out => imm_out,
        opcode_out => opcode_out,
        funct7_out => funct7_out,
        funct3_out => funct3_out
    );

    stim : process is 
    begin
        test_runner_setup(runner, runner_cfg);

        -- test immediate encoding/decoding
        -- I type (OP_IMM)
        -- Test Immediate all 0's
        info("I type (OP_IMM) Test Immediate all 0's");
        --           Imm      rs1        funct3      rd        opcode
        instr_in <= x"000" & b"00010" & OP_ADD_FUNC3 & b"00001" & OPCODE_OP_IMM;
        wait for 1 ns;
        check(rs1_addr_out=  b"0_0010", "$RS1 Check");
        -- check(rs2_addr_out=  b"0_0000", "$RS2 Check");
        check(rd_addr_out=   b"0_0001", "$RD  Check");
        check(imm_out=    x"0000_0000", "Imm  Check");  -- sign extend zeros
        check(opcode_out= OPCODE_OP_IMM, "Opcode Check");
        -- check(funct7_out=  b"000_0000", "funct7 Check");
        check(funct3_out= OP_ADD_FUNC3, "funct3 Check");
        
        -- test immediate encoding/decoding
        
        info("I type (OP_IMM) Test Immediate all 1's");
        --           Imm      rs1        funct3      rd        opcode
        instr_in <= x"FFF" & b"00010" & OP_ADD_FUNC3 & b"00001" & OPCODE_OP_IMM;
        wait for 1 ns;
        check(rs1_addr_out=  b"0_0010", "$RS1 Check");
        -- check(rs2_addr_out=  b"0_0000", "$RS2 Check");
        check(rd_addr_out=   b"0_0001", "$RD  Check");
        check(imm_out=    x"FFFF_FFFF", "Imm  Check");  -- sign extend one's
        check(opcode_out= OPCODE_OP_IMM, "Opcode Check");
        -- check(funct7_out=  b"000_0000", "funct7 Check");
        check(funct3_out= OP_ADD_FUNC3, "funct3 Check");
        
        -- test immediate encoding/decoding
        info("I type (OP_IMM) Test Immediate Random value (sign extend ones)");
        --           Imm      rs1        funct3      rd        opcode
        instr_in <= x"87E" & b"00010" & OP_ADD_FUNC3 & b"00001" & OPCODE_OP_IMM;
        wait for 1 ns;
        check(rs1_addr_out=  b"0_0010", "$RS1 Check");
        -- check(rs2_addr_out=  b"0_0000", "$RS2 Check");
        check(rd_addr_out=   b"0_0001", "$RD  Check");
        check(imm_out=    x"FFFF_F87E", "Imm  Check");  -- sign extend one's
        check(opcode_out= OPCODE_OP_IMM, "Opcode Check");
        -- check(funct7_out=  b"000_0000", "funct7 Check");
        check(funct3_out= OP_ADD_FUNC3, "funct3 Check");
        
        -- test immediate encoding/decoding
        info("I type (OP_IMM) Test Immediate Random value (sign extend zeroes)");
        --           Imm      rs1        funct3      rd        opcode
        instr_in <= x"45A" & b"00010" & OP_ADD_FUNC3 & b"00001" & OPCODE_OP_IMM;
        wait for 1 ns;
        check(rs1_addr_out=  b"0_0010", "$RS1 Check");
        -- check(rs2_addr_out=  b"0_0000", "$RS2 Check");
        check(rd_addr_out=   b"0_0001", "$RD  Check");
        check(imm_out=    x"0000_045A", "Imm  Check");  -- sign extend zero's
        check(opcode_out= OPCODE_OP_IMM, "Opcode Check");
        -- check(funct7_out=  b"000_0000", "funct7 Check");
        check(funct3_out= OP_ADD_FUNC3, "funct3 Check");
        











-------------------------------------------



        -- --           Imm      rs1        funct3      rd        opcode
        -- instr_in <= x"000" & b"00000" & OP_ADD_FUNC3 & b"00000" & OPCODE_OP_IMM;
        -- wait for 1 ns;
        -- check(rs1_addr_out=  b"0_0000", "$RS1 Check");
        -- check(rs2_addr_out=  b"0_0000", "$RS2 Check");
        -- check(rd_addr_out=   b"0_0000", "$RD  Check");
        -- check(imm_out=    x"0000_0000", "Imm  Check");
        -- check(opcode_out=  b"000_0000", "Opcode Check");
        -- check(funct7_out=  b"000_0000", "funct7 Check");
        -- check(funct3_out=       b"000", "funct3 Check");
        
 

        -- wait for 152 ns;
        
        test_runner_cleanup(runner); -- Simulation ends here
        
    end process;

end architecture rtl;