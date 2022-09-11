library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- AXI3, for use with Zynq PS interfaces
package axi_pkg is
    type t_axi_mosi is record
        araddr  : std_logic_vector (31 downto 0);
        arburst : std_logic_vector (1 downto 0);
        arcache : std_logic_vector (3 downto 0);
        arid    : std_logic_vector (11 downto 0);
        arlen   : std_logic_vector (3 downto 0);
        arlock  : std_logic_vector (1 downto 0);
        arprot  : std_logic_vector (2 downto 0);
        arqos   : std_logic_vector (3 downto 0);
        arsize  : std_logic_vector (2 downto 0);
        arvalid : std_logic;
        awaddr  : std_logic_vector (31 downto 0);
        awburst : std_logic_vector (1 downto 0);
        awcache : std_logic_vector (3 downto 0);
        awid    : std_logic_vector (11 downto 0);
        awlen   : std_logic_vector (3 downto 0);
        awlock  : std_logic_vector (1 downto 0);
        awprot  : std_logic_vector (2 downto 0);
        awqos   : std_logic_vector (3 downto 0);
        awsize  : std_logic_vector (2 downto 0);
        awvalid : std_logic;
        bready  : std_logic;
        rready  : std_logic;
        wdata   : std_logic_vector (31 downto 0);
        wid     : std_logic_vector (11 downto 0);
        wlast   : std_logic;
        wstrb   : std_logic_vector (3 downto 0);
        wvalid  : std_logic;
    end record;

    type t_axi_miso is record
        arready : std_logic;
        awready : std_logic;
        bid     : std_logic_vector (11 downto 0);
        bresp   : std_logic_vector (1 downto 0);
        bvalid  : std_logic;
        rdata   : std_logic_vector (31 downto 0);
        rid     : std_logic_vector (11 downto 0);
        rlast   : std_logic;
        rresp   : std_logic_vector (1 downto 0);
        rvalid  : std_logic;
        wready  : std_logic;
    end record;

    -- 512MB, connected to Zynq PS DDR controller
    type t_ddr is record
        addr    : std_logic_vector (14 downto 0);
        ba      : std_logic_vector (2 downto 0);
        cas_n   : std_logic;
        ck_n    : std_logic;
        ck_p    : std_logic;
        cke     : std_logic;
        cs_n    : std_logic;
        dm      : std_logic_vector (3 downto 0);
        dq      : std_logic_vector (31 downto 0);
        dqs_n   : std_logic_vector (3 downto 0);
        dqs_p   : std_logic_vector (3 downto 0);
        odt     : std_logic;
        ras_n   : std_logic;
        reset_n : std_logic;
        we_n    : std_logic;
    end record;
end package axi_pkg;