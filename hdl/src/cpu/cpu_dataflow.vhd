library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.riscv_instructions_pkg.all;
use work.joe_common_pkg.all;
use work.wb_pkg.all;

--! Controls register writeback and Memory Loads/Stores
--! TODO: handle mem_err
entity cpu_dataflow is
    port (
        clk   : in std_logic;
        reset : in std_logic;

        alu_output_in : in std_logic_vector(31 downto 0);
        ret_addr_in   : in std_logic_vector(31 downto 0);

        rs2_data_in : in std_logic_vector(31 downto 0); --! store data
        --for future pipelining/error handling
        branch_en_in      : in std_logic;
        branch_en_out     : out std_logic;
        branch_target_in  : in std_logic_vector(31 downto 0);
        branch_target_out : out std_logic_vector(31 downto 0);
        -- writeback Mux control signals (from decoder)
        write_load_in     : in std_logic;
        write_alu_in      : in std_logic;
        write_ret_addr_in : in std_logic;
        uses_writeback_in : in std_logic;

        write_reg_data_out : out std_logic_vector(31 downto 0); --! Writeback Data
        write_reg_we_out   : out std_logic;

        -- MEM access status/control signals (from cpu_control)
        mem_req_in   : in std_logic;
        mem_busy_out : out std_logic;
        mem_done_out : out std_logic;
        mem_err_out : out std_logic;

        -- memory control signals (from decoder)
        mem_we_in : in std_logic;                    --! select 0=load, 1=store 
        func3_in  : in std_logic_vector(2 downto 0); --! contains Signed/Unsigned and Width info

        -- out to wishbone bus
        mem_wb_mosi_out : out t_wb_mosi;
        mem_wb_miso_in  : in t_wb_miso

    );
end entity cpu_dataflow;

architecture rtl of cpu_dataflow is
    signal store_data : std_logic_vector(31 downto 0);
    signal size       : t_transfer_size;
    signal wb_addr    : std_logic_vector(31 downto 0);
    signal wb_sel     : std_logic_vector(3 downto 0);
    signal mem_err    : std_logic;

    signal unsigned_flag : std_logic;

    signal mem_wdata : std_logic_vector(31 downto 0);
    signal mem_rdata : std_logic_vector(31 downto 0);
begin
    mem_err_out <= mem_err; -- from WB master

    -- for future pipelining/error handling
    branch_target_out <= branch_target_in;
    branch_en_out <= branch_en_in;

    -- gate register writeback enable based on the MEM RDATA VALID signal
    write_reg_we_out <= mem_done_out when write_load_in = '1' else uses_writeback_in;

    -- decode the LOAD/STORE funct3 field
    size          <= wb_get_transfer_size(func3_in); -- b8, b16, b32
    unsigned_flag <= func3_in(2);

    process (all)
        variable var_wb_addr : std_logic_vector(31 downto 0);
        variable var_wb_sel  : std_logic_vector(3 downto 0);
    begin
        -- calculate the Wishbone Select lines
        wb_byte_addr_to_byte_sel(alu_output_in, size, var_wb_addr, var_wb_sel);
        wb_addr <= var_wb_addr;
        wb_sel  <= var_wb_sel;

        -- calculate the WDATA to send
        mem_wdata <= wb_align_store_data(rs2_data_in, wb_sel);

        -- writeback_mux
        if write_load_in = '1' then
            write_reg_data_out <= mem_rdata;
        elsif write_ret_addr_in = '1' then
            write_reg_data_out <= ret_addr_in;
        else -- write ALU result
            write_reg_data_out <= alu_output_in;
        end if;
    end process;

    -- Load/Store Unit: Wishbone B4 Pipelined (single transactions only)
    wb_master_inst : entity work.wb_master
        port map(
            wb_clk               => clk,
            wb_reset             => reset,
            wb_mosi_out          => mem_wb_mosi_out,
            wb_miso_in           => mem_wb_miso_in,
            cmd_addr_in          => wb_addr,
            cmd_wdata_in         => mem_wdata,
            cmd_sel_in           => wb_sel,
            cmd_we_in            => mem_we_in,
            cmd_req_in           => mem_req_in,
            cmd_stall_out        => mem_busy_out,
            cmd_unsigned_flag_in => unsigned_flag,
            rsp_rdata_out        => mem_rdata,
            rsp_valid_out        => mem_done_out,
            rsp_err_out          => mem_err
        );
end architecture;