
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
-- use std.textio.all;
library vunit_lib;
context vunit_lib.vunit_context;
-- use work.vivado_vunit_pkg.all;

use work.joe_common_pkg.all;
use work.riscv_instructions_pkg.all;

entity tb_cpu_decode is
    generic (runner_cfg : string := "");
end entity tb_cpu_decode;

architecture rtl of tb_cpu_decode is
    signal clk : std_logic := '0';
    constant CLK_PERIOD : time := 10 ns;
    signal reset : std_logic := '1';

    signal instr_in     : std_logic_vector(INSTR_W-1 downto 0); 
    signal instr_valid_in : std_logic := '1';
    signal rs1_addr_out : std_logic_vector(REG_ADDR_W-1 downto 0);  
    signal rs2_addr_out : std_logic_vector(REG_ADDR_W-1 downto 0);  
    signal rd_addr_out  : std_logic_vector(REG_ADDR_W-1 downto 0); 
    signal imm_out      : std_logic_vector(IMM_W-1 downto 0);   
    signal opcode_out   : std_logic_vector(OPCODE_W-1 downto 0); 
    signal funct7_out   : std_logic_vector(FUNCT7_W-1 downto 0); 
    signal funct3_out   : std_logic_vector(FUNCT3_W-1 downto 0); 

   
begin

    clk <= not clk after CLK_PERIOD/2;
    reset <= '0' after 15 ns;
    
    u_cpu_decode : entity work.cpu_decode
    Port map (
        instr_in => instr_in,
        instr_valid_in => instr_valid_in, 
        rs1_addr_out => rs1_addr_out,
        rs2_addr_out => rs2_addr_out,
        rd_addr_out => rd_addr_out,
        imm_out => imm_out,
        opcode_out => opcode_out,
        funct7_out => funct7_out,
        funct3_out => funct3_out
    );

    test_proc : process is 
    begin
        for i in 0 to 10 loop
            info("#" & integer'image(i));
            wait for 2 ns;
        end loop;
        wait;
    end process;


    stim : process is 
        -- set immediates here
        variable imm12 : std_logic_vector(11 downto 0);
        variable imm20 : std_logic_vector(19 downto 0);

        -- constant IMM12_MAX : std_logic_vector(11 downto 0) := (others => '1');
        -- constant IMM20_MAX : std_logic_vector(19 downto 0) := (others => '1');
        constant IMM12_MAX : std_logic_vector(11 downto 0) := int2slv(4000, 12);
        constant IMM20_MAX : std_logic_vector(19 downto 0) := int2slv(4000, 20);

        variable rs1 : std_logic_vector(4 downto 0) := b"1_0110";
        variable rs2 : std_logic_vector(4 downto 0) := b"1_0101";
        variable rd  : std_logic_vector(4 downto 0) := b"0_1100";

        -- index off these (includes 1-bit of 0padding for B/J type encodings)
        variable imm12_plus : std_logic_vector(12 downto 0);
        variable imm20_plus : std_logic_vector(20 downto 0);
        variable imm20_upper : std_logic_vector(31 downto 0);   -- for U type
    begin
        test_runner_setup(runner, runner_cfg);

        info("IMM12_MAX= " & to_hstring(IMM12_MAX) & " int= " & to_string(slv2int(IMM12_MAX)) & " uint= " & to_string(slv2uint(IMM12_MAX)));
        info("IMM20_MAX= " & to_hstring(IMM20_MAX) & " int= " & to_string(slv2int(IMM20_MAX)) & " uint= " & to_string(slv2uint(IMM20_MAX)));
        
        -- test immediate encoding/decoding
        info("I type (OP_IMM) Test starting...");

        -- check_equal('0', '1', "test");

        for i in 0 to slv2uint(IMM12_MAX)-1 loop
            -- info("i=" & to_string(i));
            imm12 := int2slv(i, imm12'length);
            -- Set INSTRUCTION INPUT
            --           Imm      rs1        funct3      rd        opcode
            instr_in <= imm12 & rs1 & OP_ADD_FUNC3 & rd & OPCODE_OP_IMM;
            -- WAIT AND CHECK 
            wait for 1 ns;
            check_equal(rs1_addr_out,  rs1, "$RS1 Check");
            -- check_equal(rs2_addr_out,  b"0_0000", "$RS2 Check");
            check_equal(rd_addr_out,  rd, "$RD  Check");
            check_equal(imm_out, extend_slv(imm12), "Imm  Check"); 
            check_equal(opcode_out, OPCODE_OP_IMM, "Opcode Check");
            -- check_equal(funct7_out,  b"000_0000", "funct7 Check");
            check_equal(funct3_out, OP_ADD_FUNC3, "funct3 Check");
        end loop;
        
        
        info("R type (OP) Test starting...");
        --           funct7          rs2       rs1        funct3      rd        opcode
        instr_in <= OP_SRA_FUNC7 & rs2 & rs1 & OP_SRA_FUNC3 & rd & OPCODE_OP;
        wait for 1 ns;
        check_equal(rs1_addr_out,  rs1, "$RS1 Check");
        check_equal(rs2_addr_out, rs2, "$RS2 Check");
        check_equal(rd_addr_out,   rd, "$RD  Check");
        -- check_equal(imm_out,    x"0000_0000", "Imm  Check");
        check_equal(opcode_out,  OPCODE_OP, "Opcode Check");
        check_equal(funct7_out,  OP_SRA_FUNC7, "funct7 Check");
        check_equal(funct3_out,  OP_SRA_FUNC3, "funct3 Check");


        info("S type (STORE) Test starting...");
        for i in 0 to slv2uint(IMM12_MAX)-1 loop
            imm12 := int2slv(i, imm12'length);
             --           Imm                   rs2      rs1            funct3      Imm                  opcode
            instr_in <= imm12(11 downto 5) & rs2 & rs1 & STORE_SW_FUNC3 & imm12(4 downto 0) & OPCODE_STORE;
            wait for 1 ns;
            check_equal(rs1_addr_out,  rs1, "$RS1 Check");
            check_equal(rs2_addr_out,  rs2, "$RS2 Check");
            check_equal(imm_out,    extend_slv(imm12),  "Imm  Check");  -- sign extend zero's
            check_equal(opcode_out, OPCODE_STORE, "Opcode Check");
            check_equal(funct3_out, STORE_SW_FUNC3, "funct3 Check");
        end loop;


        info("B type (BRANCH) Test starting...");

        for i in 0 to slv2uint(IMM12_MAX)-1 loop
            imm12 := int2slv(i, imm12'length);
            imm12_plus := imm12 & b"0"; -- imm12 is multiple of 2 bytes
            --           Imm                                           rs2      rs1            funct3            Imm                  opcode
            instr_in <= imm12_plus(12) & imm12_plus(10 downto 5) & rs2 & rs1 & BRANCH_BNE_FUNC3 & imm12_plus(4 downto 1) & imm12_plus(11) & OPCODE_BRANCH;

            wait for 1 ns;
            check_equal(rs1_addr_out, rs1, "$RS1 Check");
            check_equal(rs2_addr_out,  rs2, "$RS2 Check");
            check_equal(imm_out,    extend_slv(imm12_plus),  "Imm  Check");  -- sign extend zero's
            check_equal(opcode_out, OPCODE_BRANCH, "Opcode Check");
            check_equal(funct3_out, BRANCH_BNE_FUNC3, "funct3 Check");
        end loop;

        info("U type (LUI) Test starting...");
        -- might need to reduce this loop a bit, depending on GHDL speed
        for i in 0 to slv2uint(IMM20_MAX)-1 loop
            imm20 := int2slv(i, imm20'length);
            imm20_upper := imm20 & x"000"; -- set bottom 12 bits to 0
            --           Imm     rd           opcode
            instr_in <= imm20 &rd & OPCODE_LUI;

            wait for 1 ns;
            check_equal(rd_addr_out, rd, "$RD  Check");
            check_equal(imm_out,  imm20_upper,  "Imm  Check");  
            check_equal(opcode_out, OPCODE_LUI, "Opcode Check");
        end loop;

        info("J type (JAL) Test starting...");
        -- might need to reduce this loop a bit, depending on GHDL speed
        for i in 0 to slv2uint(IMM20_MAX)-1 loop
            imm20 := int2slv(i, imm20'length);
            imm20_plus := imm20 & b"0"; ---- imm20 is multiple of 2 bytes
            --           Imm                                                              rd    opcode
            instr_in <= imm20_plus(20) & imm20_plus(10 downto 1) & imm20_plus(11) & imm20_plus(19 downto 12) & rd & OPCODE_JAL;

            wait for 1 ns;
            check_equal(rd_addr_out,  rd, "$RD  Check");
            check_equal(imm_out, extend_slv(imm20_plus),  "Imm  Check");  
            check_equal(opcode_out, OPCODE_JAL, "Opcode Check");
        end loop;


        wait for 152 ns;
        
       test_runner_cleanup(runner); -- Simulation ends here
        
    end process;

end architecture rtl;