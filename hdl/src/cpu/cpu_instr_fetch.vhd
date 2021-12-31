library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;

entity cpu_instr_fetch is
    generic (
        G_PC_RESET_ADDR : unsigned(31 downto 0) := x"0000_0000"
    );
    port (
        clk            : in std_logic;
        reset          : in std_logic;
        branch_addr_in : in std_logic_vector(31 downto 0);
        branch_en_in   : in std_logic;
        pc_out         : out std_logic_vector(31 downto 0);
        ret_addr_out   : out std_logic_vector(31 downto 0); -- PC+4, used to save Return Address

        fetch_req_in    : in std_logic;
        instr_valid_out : out std_logic;
        instr_out       : out std_logic_vector(31 downto 0);
        fetch_err_out   : out std_logic;
        fetch_busy_out  : out std_logic;

        -- out to program memory
        if_wb_mosi_out : out t_wb_mosi;
        if_wb_miso_in  : in t_wb_miso

    );
end entity cpu_instr_fetch;

architecture rtl of cpu_instr_fetch is
    signal pc      : unsigned(31 downto 0) := G_PC_RESET_ADDR;
    signal next_pc : unsigned(31 downto 0);

    signal fetch_addr : std_logic_vector(31 downto 0);
begin

    -- combinational
    ret_addr_out <= std_logic_vector(unsigned(pc_out) + to_unsigned(4, 32));

    -- branch select
    next_pc    <= pc + to_unsigned(4, 32) when branch_en_in = '0' else unsigned(branch_addr_in) + to_unsigned(4, 32);
    fetch_addr <= std_logic_vector(pc) when branch_en_in = '0' else branch_addr_in;

    main_proc : process (clk, reset) is
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pc <= G_PC_RESET_ADDR;
            else
                if fetch_req_in = '1' and fetch_busy_out = '0' then
                    pc <= next_pc;

                    pc_out <= fetch_addr; -- address currently being fetched
                end if;
            end if;
        end if;
    end process;

    -- wishbone master to fetch instructions
    -- We could use a simpler 32b only master as well, or a direct connection 
    -- that only takes 1 cycle to fetch an instruction from BRAM for improved 
    -- CPU performance

    wb_master_inst : entity work.wb_master
        port map(
            wb_clk               => clk,
            wb_reset             => reset,
            wb_mosi_out          => if_wb_mosi_out,
            wb_miso_in           => if_wb_miso_in,
            cmd_addr_in          => fetch_addr,
            cmd_wdata_in => (others => '0'),
            cmd_sel_in           => x"F",
            cmd_we_in            => '0',
            cmd_req_in           => fetch_req_in,
            cmd_stall_out        => fetch_busy_out,
            cmd_unsigned_flag_in => '1',
            rsp_rdata_out        => instr_out,
            rsp_valid_out        => instr_valid_out,
            rsp_err_out          => fetch_err_out
        );

end architecture;