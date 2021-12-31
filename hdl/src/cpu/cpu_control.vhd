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
        instr_valid_in : in std_logic;
        -- Decode
        decode_err_in : in std_logic;
        uses_mem_access_in : in std_logic;
        -- Execute ALU

        -- Execute Mem
        mem_req_out : out std_logic;
        mem_busy_in : in std_logic;
        mem_done_in : in std_logic;

        -- Writeback

        extern_halt_in : in std_logic := '0'
    );
end entity cpu_control;

architecture rtl of cpu_control is
    -- we probably won't need all of these
    type t_state is (INIT, WAIT_FOR_FETCH, DECODE_EXECUTE, WAIT_FOR_MEM, ERROR);

    signal state : t_state := INIT;
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= INIT;
            else
                if extern_halt_in = '0' then -- If we are not halted (by an external debugger etc)                    
                    -- defaults

                    case state is
                        when INIT =>
                            fetch_req_out <= '1';
                            state         <= WAIT_FOR_FETCH;

                        when WAIT_FOR_FETCH =>
                            if fetch_busy_in = '0' then
                                fetch_req_out <= '0';
                            end if;

                            if instr_valid_in = '1' then
                                state <= DECODE_EXECUTE;
                            end if;
                            -- combinational stuff happens here elsewhere in the CPU
                        when DECODE_EXECUTE =>
                            if uses_mem_access_in = '1' then
                                state       <= WAIT_FOR_MEM;
                                mem_req_out <= '1';
                            else 
                                state         <= WAIT_FOR_FETCH;
                                fetch_req_out <= '1';
                            end if;

                            if decode_err_in = '1' then 
                                state <= ERROR;
                            end if;
                        when WAIT_FOR_MEM =>
                            if mem_busy_in = '0' then
                                mem_req_out <= '0';
                            end if;
                            if mem_done_in = '1' then
                                state         <= WAIT_FOR_FETCH;
                                fetch_req_out <= '1';
                            end if;
                        when ERROR =>

                        when others =>
                            state <= ERROR;
                    end case;
                end if;
            end if;
        end if;
    end process;

end architecture;