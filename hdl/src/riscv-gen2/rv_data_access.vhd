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
        rst : in std_logic;

        --! 
        req_valid_in : in std_logic; 
        req_stall_out : out std_logic;
        byte_address_in : in std_logic_vector(31 downto 0);
        data_in : out std_logic_vector(31 downto 0); --! 32-bit aligned to bottom

        data_out : out std_logic_vector(31 downto 0); --! 32-bit aligned to the bottom
        rsp_valid_out : out std_logic;
        rsp_stall_in : in std_logic;

        write_en_in : std_logic; -- load vs store
        func3_in : in std_logic_vector(2 downto 0); -- contains signed/unsigned and size info

        -- Exceptions
        load_misaligned : out std_logic;
        load_access : out std_logic;
        store_amo_misaligned : out std_logic;
        store_amo_access : out std_logic;
        load_page_fault : out std_logic;
        store_amo_page_fault : out std_logic;

        -- out to wishbone bus
        mem_wb_mosi_out : out t_wb_mosi;
        mem_wb_miso_in  : in t_wb_miso

    );
    
end entity rv_data_access;


architecture RTL of rv_data_access is
    signal store_data     : std_logic_vector(31 downto 0);
    signal size           : t_transfer_size;
    signal wb_addr        : std_logic_vector(31 downto 0);
    signal wb_sel         : std_logic_vector(3 downto 0);
    signal mem_err        : std_logic;
    signal addr_align_err : std_logic;

    signal unsigned_flag : std_logic;
    signal mem_wdata     : std_logic_vector(31 downto 0);
    signal mem_rdata     : std_logic_vector(31 downto 0);
    signal mem_rdata_reg : std_logic_vector(31 downto 0);
begin
    -- not supported
    load_page_fault <= '0';
    store_amo_page_fault <= '0';

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
        wb_byte_addr_to_byte_sel(data_in, size, var_wb_addr, var_wb_sel, var_addr_align_error);
        wb_addr <= var_wb_addr;
        wb_sel  <= var_wb_sel;
        
        --TODO clock this?
        addr_align_err <= var_addr_align_error and req_valid_in; -- mask with mem_req_in
        
        -- align the WDATA to send, and the RDATA received
        mem_wdata <= wb_align_store_data(data_in, var_wb_sel);
        data_out  <= wb_align_load_data(mem_rdata, var_wb_sel);

        
    end process;
end architecture RTL;
