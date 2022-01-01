library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all;

--! State Machine controlling the operation of the CPU
entity cpu_control is
    port (
        clk   : in std_logic;
        reset : in std_logic;

        -- control signals
        -- Instruction Fetch
        fetch_req_out  : out std_logic;
        fetch_busy_in : in std_logic;
        fetch_err_in : in std_logic;
        instr_valid_in : in std_logic;
        -- Decode
        opcode_err_in : in std_logic;
        uses_mem_access_in : in std_logic;
        -- Execute ALU
        alu_en_out : out std_logic;
        alu_err_in : in std_logic;
        -- Execute Mem
        mem_req_out : out std_logic;
        mem_busy_in : in std_logic;
        mem_err_in : in std_logic;
        mem_done_in : in std_logic;

        -- Writeback
        cpu_err_out : out std_logic;
        extern_halt_in : in std_logic := '0'
    );
end entity cpu_control;

architecture rtl of cpu_control is
    -- we probably won't need all of these
    type t_state is (INIT, FETCH, EXECUTE, MEM, ERROR);

    signal state : t_state := INIT;

    type t_error is (NONE, FETCH_ERR, OPCODE_ERR, ALU_ERR, MEM_ERR);
    signal error_status : t_error := NONE;
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= INIT;
                error_status <= NONE;
                cpu_err_out <= '0';
                alu_en_out <= '0';
            else
                if extern_halt_in = '0' then -- If we are not halted (by an external debugger etc)                    
                    -- defaults
                    cpu_err_out <= '0';
                    alu_en_out <= '0';
                    case state is
                        when INIT =>
                            fetch_req_out <= '1';
                            state         <= FETCH;

                        when FETCH =>
                            if fetch_busy_in = '0' then
                                fetch_req_out <= '0';
                            end if;

                            if instr_valid_in = '1' then
                                state <= EXECUTE;
                                alu_en_out <= '1';
                            end if;
                            if fetch_err_in = '1' then
                                state <= ERROR;
                                error_status <= FETCH_ERR;
                            end if;
                            -- combinational stuff happens here elsewhere in the CPU
                        when EXECUTE =>
                            if uses_mem_access_in = '1' then
                                state       <= MEM;
                                mem_req_out <= '1';
                            else 
                                state         <= FETCH;
                                fetch_req_out <= '1';
                            end if;
                            if alu_err_in = '1' then 
                                state <= ERROR;
                                error_status <= ALU_ERR;
                            end if;
                            if opcode_err_in = '1' then 
                                state <= ERROR;
                                error_status <= OPCODE_ERR;
                            end if;
                        when MEM =>
                            if mem_busy_in = '0' then
                                mem_req_out <= '0';
                            end if;
                            if mem_done_in = '1' then
                                state         <= FETCH;
                                fetch_req_out <= '1';
                            end if;
                            if mem_err_in = '1' then
                                state <= FETCH;
                                error_status <= MEM_ERR;
                            end if;
                        when ERROR =>
                            cpu_err_out <= '1';
                        when others =>
                            state <= ERROR;
                    end case;
                end if;
            end if;
        end if;
    end process;

end architecture;