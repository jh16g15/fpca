----------------------------------------------------------------------------------
-- Joseph Hindmarsh Septemper 2022
--
-- A simple wrapper around the Vunit AXI Read Slave and AXI Write Slave verification
-- components, using my record structures for ease of re-use
--
-- TODOs:
--  * AXI3 specific?
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

use work.axi_pkg.all;
entity vunit_axi_slave is
    generic (
        G_NAME        : string                := "VUNIT_AXI_SLAVE";
        G_BASE_ADDR   : unsigned(31 downto 0) := x"0000_0000"; --! keep this as low as possible! GHDL doesn't like large values here
        G_BYTES       : natural               := 512;
        G_DEBUG_PRINT : boolean               := false
    );
    port (
        axi_clk  : in std_logic;
        axi_mosi : in t_axi_mosi;
        axi_miso : out t_axi_miso;
        memory_ref_out : out memory_t   -- so tb can access it

    );
end entity vunit_axi_slave;

architecture rtl of vunit_axi_slave is
    constant logger    : logger_t    := get_logger(G_NAME);
    constant mem       : memory_t    := new_memory;
    constant axi_slave : axi_slave_t := new_axi_slave(memory => mem);

    function int_to_hstring(val : integer; width : integer := 32) return string is
    begin
        return to_hstring(to_unsigned(val, width));
    end function;

    procedure print_mem_region(
        memory         : memory_t;
        address        : std_logic_vector;
        words          : positive;
        bytes_per_word : positive := 4
    ) is
        constant addr : natural := to_integer(unsigned(address));
    begin
        for i in addr to addr + words - 1 loop
            info(logger, int_to_hstring(i * bytes_per_word) & ": " & to_hstring(read_word(memory, i*bytes_per_word, bytes_per_word)));
        end loop;
    end procedure;

begin
    -- so testbench can access it
    memory_ref_out <= mem;

    p_alloc : process
        variable empty_buf : buffer_t;
        variable buf       : buffer_t;
    begin
        if G_BASE_ADDR /= x"0000_0000" then
            info(logger, "Allocating empty buffer to have our real buffer at the correct base address");
            empty_buf := allocate(mem, to_integer(unsigned(G_BASE_ADDR)));
            info(logger, "Base Address: " & int_to_hstring(base_address(empty_buf)));
            info(logger, "Last Address: " & int_to_hstring(last_address(empty_buf)));
        end if;
        info(logger, "Allocating axi_slave memory buffer");
        buf := allocate(mem, G_BYTES);
        info(logger, "Base Address: " & int_to_hstring(base_address(buf)));
        info(logger, "Last Address: " & int_to_hstring(last_address(buf)));

        info(logger, "Number of bytes (mem): " & to_string(num_bytes(mem)));
        info(logger, "Number of bytes (buf): " & to_string(num_bytes(buf)));

        -- info(logger, describe_address(mem, 0));
        -- info(logger, describe_address(mem, 4));
        -- info(logger, describe_address(mem, 8));
        -- info(logger, describe_address(mem, 12));
        -- info(logger, describe_address(mem, 16));
        -- info(logger, "Initial Memory Contents");
        -- print_mem_region(mem, x"0000_0000", 5);
        wait;
    end process;

    p_print : process (axi_clk)
    begin
        if G_DEBUG_PRINT = true then
            if rising_edge(axi_clk) then
                info(logger, "Memory Contents");
                print_mem_region(mem, x"0000_0000", 5);
            end if;
        end if;
    end process;

    axi_read : entity vunit_lib.axi_read_slave
        generic map(
            axi_slave => axi_slave)
        port map(
            aclk => axi_clk,

            arvalid => axi_mosi.arvalid,
            arready => axi_miso.arready,
            arid    => axi_mosi.arid,
            araddr  => axi_mosi.araddr,
            arlen   => axi_mosi.arlen,
            arsize  => axi_mosi.arsize,
            arburst => axi_mosi.arburst,

            rvalid => axi_miso.rvalid,
            rready => axi_mosi.rready,
            rid    => axi_miso.rid,
            rdata  => axi_miso.rdata,
            rresp  => axi_miso.rresp,
            rlast  => axi_miso.rlast);

    axi_write : entity vunit_lib.axi_write_slave
        generic map(
            axi_slave => axi_slave)
        port map(
            aclk    => axi_clk,
            awvalid => axi_mosi.awvalid,
            awready => axi_miso.awready,
            awid    => axi_mosi.awid,
            awaddr  => axi_mosi.awaddr,
            awlen   => axi_mosi.awlen,
            awsize  => axi_mosi.awsize,
            awburst => axi_mosi.awburst,
            wvalid  => axi_mosi.wvalid,
            wready  => axi_miso.wready,
            wdata   => axi_mosi.wdata,
            wstrb   => axi_mosi.wstrb,
            wlast   => axi_mosi.wlast,
            bvalid  => axi_miso.bvalid,
            bready  => axi_mosi.bready,
            bid     => axi_miso.bid,
            bresp   => axi_miso.bresp);

end architecture;