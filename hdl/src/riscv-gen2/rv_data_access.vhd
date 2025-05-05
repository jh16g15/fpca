library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all;


--! Load/Store Unit that converts RISC-V byte-aligned 8/16/32bit transfers to Wishbone
--! May assert Load/Store Misaligned exceptions pending hardware misaligned support
entity rv_data_access is
    port(
        clk : in std_logic;
        reset : in std_logic;

        --! 
        req_valid_in : in std_logic; 
        req_stall_out : out std_logic;
        byte_address_in : in std_logic_vector(31 downto 0);
        data_in : in std_logic_vector(31 downto 0); --! 32-bit aligned to bottom

        data_out : out std_logic_vector(31 downto 0); --! 32-bit aligned to the bottom
        rsp_valid_out : out std_logic; -- either valid data, or an exception
        -- rsp_stall_in : in std_logic; -- no backpressure implemented here

        write_en_in : std_logic; -- load vs store
        func3_in : in std_logic_vector(2 downto 0); -- contains signed/unsigned and size info

        -- Exceptions
        faulting_addr : out std_logic_vector(31 downto 0); -- for MTVAL
        err_load_misaligned : out std_logic;
        err_load_access : out std_logic;
        err_store_amo_misaligned : out std_logic;
        err_store_amo_access : out std_logic;
        err_load_page_fault : out std_logic;
        err_store_amo_page_fault : out std_logic;

        -- out to wishbone bus
        mem_wb_mosi_out : out t_wb_mosi;
        mem_wb_miso_in  : in t_wb_miso

    );
    
end entity rv_data_access;


architecture RTL of rv_data_access is
    signal reg_byte_addr     : std_logic_vector(31 downto 0);
    signal size           : t_transfer_size;
    signal wb_addr        : std_logic_vector(31 downto 0);
    signal wb_sel         : std_logic_vector(3 downto 0);
    
    signal wb_req         : std_logic; -- don't request if misalign error
    signal wb_err         : std_logic;
    
    signal addr_align_err : std_logic;
    signal unsigned_flag : std_logic;
    
    -- for load rdata handling
    signal reg_unsigned_flag : std_logic;
    signal reg_wr_en : std_logic;
    signal reg_wb_sel : std_logic_vector(3 downto 0);
    
    signal mem_wdata     : std_logic_vector(31 downto 0);
    signal mem_rdata     : std_logic_vector(31 downto 0);
    -- signal mem_rdata_reg : std_logic_vector(31 downto 0);
begin
    
    --! Alignment Handling (base on bottom two bits)
    -- decode the LOAD/STORE funct3 field
    size          <= wb_get_transfer_size(func3_in); -- b8, b16, b32
    unsigned_flag <= func3_in(2);


    process (all)
        variable var_wb_addr : std_logic_vector(31 downto 0);
        variable var_wb_sel  : std_logic_vector(3 downto 0);
        variable var_addr_align_error  : std_logic;
    begin
        -- calculate the Wishbone Select lines
        wb_byte_addr_to_byte_sel(byte_address_in, size, var_wb_addr, var_wb_sel, var_addr_align_error);
        wb_addr <= var_wb_addr;
        wb_sel  <= var_wb_sel;
        
        --TODO clock this?
        addr_align_err <= var_addr_align_error and req_valid_in; -- mask with mem_req_in
        
        -- align the WDATA to send, and the RDATA received
        mem_wdata <= wb_align_store_data(data_in, var_wb_sel);
        data_out  <= wb_align_load_data(mem_rdata, reg_wb_sel, sign_ext => not reg_unsigned_flag);

    end process;

    -- save these for rdata processing on LOADs
    process(clk) is
    begin
        if rising_edge(clk) then
            if req_valid_in = '1' then
                reg_byte_addr <= byte_address_in;
                reg_unsigned_flag <= unsigned_flag;
                reg_wb_sel <= wb_sel;
                reg_wr_en <= write_en_in;
            end if;
        end if;
    end process;

    -- Load/Store Unit: Wishbone B4 Pipelined (single transactions only)
    wb_master_inst : entity work.wb_master_noalign
    port map(
        wb_clk               => clk,
        wb_reset             => reset,
        wb_mosi_out          => mem_wb_mosi_out,
        wb_miso_in           => mem_wb_miso_in,
        cmd_addr_in          => wb_addr,
        cmd_wdata_in         => mem_wdata,
        cmd_sel_in           => wb_sel,
        cmd_we_in            => write_en_in,
        cmd_req_in           => wb_req,
        cmd_stall_out        => req_stall_out,
        rsp_rdata_out        => mem_rdata,
        rsp_valid_out        => rsp_valid_out, --might need to register this
        rsp_err_out          => wb_err
    );

    -- Exceptions
    -- upfront exceptions
    wb_req <= req_valid_in and not addr_align_err; -- don't request transaction if address is misaligned - throw exception
    err_load_misaligned <= not write_en_in and addr_align_err;
    err_store_amo_misaligned <= write_en_in and addr_align_err;
    -- return exceptions
    err_load_access <= not reg_wr_en and wb_err;
    err_store_amo_access <= reg_wr_en and wb_err;

    -- not supported
    err_load_page_fault <= '0';
    err_store_amo_page_fault <= '0';

    -- for MTVAL
    process(all) is
    begin
        if addr_align_err then -- current address fault
            faulting_addr  <= byte_address_in;
        end if;
        if wb_err then  -- saved address fault
            faulting_addr <= reg_byte_addr;
        end if;
    end process;


end architecture RTL;
