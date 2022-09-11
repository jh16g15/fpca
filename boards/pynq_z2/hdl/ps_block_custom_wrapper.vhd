library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.axi_pkg.all;


-- ps_block_custom_wrapper.vhd
--
-- A wrapper around a block diagram containing a Zynq PS block
-- Converts to record types from axi_pkg for ease of use.
--
entity ps_block_custom_wrapper is
    port (
        AXI_CLK_IN : in std_logic;
        DDR        : inout t_ddr;

        FCLK_CLK0_100     : out std_logic;
        FCLK_RESET0_N     : out std_logic;
        FIXED_IO_ddr_vrn  : inout std_logic;
        FIXED_IO_ddr_vrp  : inout std_logic;
        FIXED_IO_mio      : inout std_logic_vector (53 downto 0);
        FIXED_IO_ps_clk   : inout std_logic;
        FIXED_IO_ps_porb  : inout std_logic;
        FIXED_IO_ps_srstb : inout std_logic;
        IRQ_P2F_UART0     : out std_logic;
        -- Control PL peripherals from Zynq
        M_AXI_GP0_MOSI    : out t_axi_mosi;
        M_AXI_GP0_MISO    : in t_axi_miso;
        -- Control PS peripherals from PL
        S_AXI_GP0_MOSI : in t_axi_mosi;
        S_AXI_GP0_MISO : out t_axi_miso;

        -- Access DDR3 from PL
        S_AXI_HP0_MOSI : in t_axi_mosi;
        S_AXI_HP0_MISO : out t_axi_miso

    );
end ps_block_custom_wrapper;

architecture STRUCTURE of ps_block_custom_wrapper is

begin
    u_ps_block_wrapper : entity work.ps_block_wrapper
        port map(
            AXI_CLK_IN                    => AXI_CLK_IN,
            DDR_addr(14 downto 0)         => DDR.addr(14 downto 0),
            DDR_ba(2 downto 0)            => DDR.ba(2 downto 0),
            DDR_cas_n                     => DDR.cas_n,
            DDR_ck_n                      => DDR.ck_n,
            DDR_ck_p                      => DDR.ck_p,
            DDR_cke                       => DDR.cke,
            DDR_cs_n                      => DDR.cs_n,
            DDR_dm(3 downto 0)            => DDR.dm(3 downto 0),
            DDR_dq(31 downto 0)           => DDR.dq(31 downto 0),
            DDR_dqs_n(3 downto 0)         => DDR.dqs_n(3 downto 0),
            DDR_dqs_p(3 downto 0)         => DDR.dqs_p(3 downto 0),
            DDR_odt                       => DDR.odt,
            DDR_ras_n                     => DDR.ras_n,
            DDR_reset_n                   => DDR.reset_n,
            DDR_we_n                      => DDR.we_n,
            FCLK_CLK0_100                 => FCLK_CLK0_100,
            FCLK_RESET0_N                 => FCLK_RESET0_N,
            FIXED_IO_ddr_vrn              => FIXED_IO_ddr_vrn,
            FIXED_IO_ddr_vrp              => FIXED_IO_ddr_vrp,
            FIXED_IO_mio(53 downto 0)     => FIXED_IO_mio(53 downto 0),
            FIXED_IO_ps_clk               => FIXED_IO_ps_clk,
            FIXED_IO_ps_porb              => FIXED_IO_ps_porb,
            FIXED_IO_ps_srstb             => FIXED_IO_ps_srstb,
            IRQ_P2F_UART0                 => IRQ_P2F_UART0,
            M_AXI_GP0_araddr(31 downto 0) => M_AXI_GP0_MOSI.araddr(31 downto 0),
            M_AXI_GP0_arburst(1 downto 0) => M_AXI_GP0_MOSI.arburst(1 downto 0),
            M_AXI_GP0_arcache(3 downto 0) => M_AXI_GP0_MOSI.arcache(3 downto 0),
            M_AXI_GP0_arid(11 downto 0)   => M_AXI_GP0_MOSI.arid(11 downto 0),
            M_AXI_GP0_arlen(3 downto 0)   => M_AXI_GP0_MOSI.arlen(3 downto 0),
            M_AXI_GP0_arlock(1 downto 0)  => M_AXI_GP0_MOSI.arlock(1 downto 0),
            M_AXI_GP0_arprot(2 downto 0)  => M_AXI_GP0_MOSI.arprot(2 downto 0),
            M_AXI_GP0_arqos(3 downto 0)   => M_AXI_GP0_MOSI.arqos(3 downto 0),
            M_AXI_GP0_arready             => M_AXI_GP0_MISO.arready,
            M_AXI_GP0_arsize(2 downto 0)  => M_AXI_GP0_MOSI.arsize(2 downto 0),
            M_AXI_GP0_arvalid             => M_AXI_GP0_MOSI.arvalid,
            M_AXI_GP0_awaddr(31 downto 0) => M_AXI_GP0_MOSI.awaddr(31 downto 0),
            M_AXI_GP0_awburst(1 downto 0) => M_AXI_GP0_MOSI.awburst(1 downto 0),
            M_AXI_GP0_awcache(3 downto 0) => M_AXI_GP0_MOSI.awcache(3 downto 0),
            M_AXI_GP0_awid(11 downto 0)   => M_AXI_GP0_MOSI.awid(11 downto 0),
            M_AXI_GP0_awlen(3 downto 0)   => M_AXI_GP0_MOSI.awlen(3 downto 0),
            M_AXI_GP0_awlock(1 downto 0)  => M_AXI_GP0_MOSI.awlock(1 downto 0),
            M_AXI_GP0_awprot(2 downto 0)  => M_AXI_GP0_MOSI.awprot(2 downto 0),
            M_AXI_GP0_awqos(3 downto 0)   => M_AXI_GP0_MOSI.awqos(3 downto 0),
            M_AXI_GP0_awready             => M_AXI_GP0_MISO.awready,
            M_AXI_GP0_awsize(2 downto 0)  => M_AXI_GP0_MOSI.awsize(2 downto 0),
            M_AXI_GP0_awvalid             => M_AXI_GP0_MOSI.awvalid,
            M_AXI_GP0_bid(11 downto 0)    => M_AXI_GP0_MISO.bid(11 downto 0),
            M_AXI_GP0_bready              => M_AXI_GP0_MOSI.bready,
            M_AXI_GP0_bresp(1 downto 0)   => M_AXI_GP0_MISO.bresp(1 downto 0),
            M_AXI_GP0_bvalid              => M_AXI_GP0_MISO.bvalid,
            M_AXI_GP0_rdata(31 downto 0)  => M_AXI_GP0_MISO.rdata(31 downto 0),
            M_AXI_GP0_rid(11 downto 0)    => M_AXI_GP0_MISO.rid(11 downto 0),
            M_AXI_GP0_rlast               => M_AXI_GP0_MISO.rlast,
            M_AXI_GP0_rready              => M_AXI_GP0_MOSI.rready,
            M_AXI_GP0_rresp(1 downto 0)   => M_AXI_GP0_MISO.rresp(1 downto 0),
            M_AXI_GP0_rvalid              => M_AXI_GP0_MISO.rvalid,
            M_AXI_GP0_wdata(31 downto 0)  => M_AXI_GP0_MOSI.wdata(31 downto 0),
            M_AXI_GP0_wid(11 downto 0)    => M_AXI_GP0_MOSI.wid(11 downto 0),
            M_AXI_GP0_wlast               => M_AXI_GP0_MOSI.wlast,
            M_AXI_GP0_wready              => M_AXI_GP0_MISO.wready,
            M_AXI_GP0_wstrb(3 downto 0)   => M_AXI_GP0_MOSI.wstrb(3 downto 0),
            M_AXI_GP0_wvalid              => M_AXI_GP0_MOSI.wvalid,
            S_AXI_GP0_araddr(31 downto 0) => S_AXI_GP0_MOSI.araddr(31 downto 0),
            S_AXI_GP0_arburst(1 downto 0) => S_AXI_GP0_MOSI.arburst(1 downto 0),
            S_AXI_GP0_arcache(3 downto 0) => S_AXI_GP0_MOSI.arcache(3 downto 0),
            S_AXI_GP0_arid(5 downto 0)    => S_AXI_GP0_MOSI.arid(5 downto 0),
            S_AXI_GP0_arlen(3 downto 0)   => S_AXI_GP0_MOSI.arlen(3 downto 0),
            S_AXI_GP0_arlock(1 downto 0)  => S_AXI_GP0_MOSI.arlock(1 downto 0),
            S_AXI_GP0_arprot(2 downto 0)  => S_AXI_GP0_MOSI.arprot(2 downto 0),
            S_AXI_GP0_arqos(3 downto 0)   => S_AXI_GP0_MOSI.arqos(3 downto 0),
            S_AXI_GP0_arready             => S_AXI_GP0_MISO.arready,
            S_AXI_GP0_arsize(2 downto 0)  => S_AXI_GP0_MOSI.arsize(2 downto 0),
            S_AXI_GP0_arvalid             => S_AXI_GP0_MOSI.arvalid,
            S_AXI_GP0_awaddr(31 downto 0) => S_AXI_GP0_MOSI.awaddr(31 downto 0),
            S_AXI_GP0_awburst(1 downto 0) => S_AXI_GP0_MOSI.awburst(1 downto 0),
            S_AXI_GP0_awcache(3 downto 0) => S_AXI_GP0_MOSI.awcache(3 downto 0),
            S_AXI_GP0_awid(5 downto 0)    => S_AXI_GP0_MOSI.awid(5 downto 0),
            S_AXI_GP0_awlen(3 downto 0)   => S_AXI_GP0_MOSI.awlen(3 downto 0),
            S_AXI_GP0_awlock(1 downto 0)  => S_AXI_GP0_MOSI.awlock(1 downto 0),
            S_AXI_GP0_awprot(2 downto 0)  => S_AXI_GP0_MOSI.awprot(2 downto 0),
            S_AXI_GP0_awqos(3 downto 0)   => S_AXI_GP0_MOSI.awqos(3 downto 0),
            S_AXI_GP0_awready             => S_AXI_GP0_MISO.awready,
            S_AXI_GP0_awsize(2 downto 0)  => S_AXI_GP0_MOSI.awsize(2 downto 0),
            S_AXI_GP0_awvalid             => S_AXI_GP0_MOSI.awvalid,
            S_AXI_GP0_bid(5 downto 0)     => S_AXI_GP0_MISO.bid(5 downto 0),
            S_AXI_GP0_bready              => S_AXI_GP0_MOSI.bready,
            S_AXI_GP0_bresp(1 downto 0)   => S_AXI_GP0_MISO.bresp(1 downto 0),
            S_AXI_GP0_bvalid              => S_AXI_GP0_MISO.bvalid,
            S_AXI_GP0_rdata(31 downto 0)  => S_AXI_GP0_MISO.rdata(31 downto 0),
            S_AXI_GP0_rid(5 downto 0)     => S_AXI_GP0_MISO.rid(5 downto 0),
            S_AXI_GP0_rlast               => S_AXI_GP0_MISO.rlast,
            S_AXI_GP0_rready              => S_AXI_GP0_MOSI.rready,
            S_AXI_GP0_rresp(1 downto 0)   => S_AXI_GP0_MISO.rresp(1 downto 0),
            S_AXI_GP0_rvalid              => S_AXI_GP0_MISO.rvalid,
            S_AXI_GP0_wdata(31 downto 0)  => S_AXI_GP0_MOSI.wdata(31 downto 0),
            S_AXI_GP0_wid(5 downto 0)     => S_AXI_GP0_MOSI.wid(5 downto 0),
            S_AXI_GP0_wlast               => S_AXI_GP0_MOSI.wlast,
            S_AXI_GP0_wready              => S_AXI_GP0_MISO.wready,
            S_AXI_GP0_wstrb(3 downto 0)   => S_AXI_GP0_MOSI.wstrb(3 downto 0),
            S_AXI_GP0_wvalid              => S_AXI_GP0_MOSI.wvalid,
            S_AXI_HP0_araddr(31 downto 0) => S_AXI_HP0_MOSI.araddr(31 downto 0),
            S_AXI_HP0_arburst(1 downto 0) => S_AXI_HP0_MOSI.arburst(1 downto 0),
            S_AXI_HP0_arcache(3 downto 0) => S_AXI_HP0_MOSI.arcache(3 downto 0),
            S_AXI_HP0_arid(5 downto 0)    => S_AXI_HP0_MOSI.arid(5 downto 0),
            S_AXI_HP0_arlen(3 downto 0)   => S_AXI_HP0_MOSI.arlen(3 downto 0),
            S_AXI_HP0_arlock(1 downto 0)  => S_AXI_HP0_MOSI.arlock(1 downto 0),
            S_AXI_HP0_arprot(2 downto 0)  => S_AXI_HP0_MOSI.arprot(2 downto 0),
            S_AXI_HP0_arqos(3 downto 0)   => S_AXI_HP0_MOSI.arqos(3 downto 0),
            S_AXI_HP0_arready             => S_AXI_HP0_MISO.arready,
            S_AXI_HP0_arsize(2 downto 0)  => S_AXI_HP0_MOSI.arsize(2 downto 0),
            S_AXI_HP0_arvalid             => S_AXI_HP0_MOSI.arvalid,
            S_AXI_HP0_awaddr(31 downto 0) => S_AXI_HP0_MOSI.awaddr(31 downto 0),
            S_AXI_HP0_awburst(1 downto 0) => S_AXI_HP0_MOSI.awburst(1 downto 0),
            S_AXI_HP0_awcache(3 downto 0) => S_AXI_HP0_MOSI.awcache(3 downto 0),
            S_AXI_HP0_awid(5 downto 0)    => S_AXI_HP0_MOSI.awid(5 downto 0),
            S_AXI_HP0_awlen(3 downto 0)   => S_AXI_HP0_MOSI.awlen(3 downto 0),
            S_AXI_HP0_awlock(1 downto 0)  => S_AXI_HP0_MOSI.awlock(1 downto 0),
            S_AXI_HP0_awprot(2 downto 0)  => S_AXI_HP0_MOSI.awprot(2 downto 0),
            S_AXI_HP0_awqos(3 downto 0)   => S_AXI_HP0_MOSI.awqos(3 downto 0),
            S_AXI_HP0_awready             => S_AXI_HP0_MISO.awready,
            S_AXI_HP0_awsize(2 downto 0)  => S_AXI_HP0_MOSI.awsize(2 downto 0),
            S_AXI_HP0_awvalid             => S_AXI_HP0_MOSI.awvalid,
            S_AXI_HP0_bid(5 downto 0)     => S_AXI_HP0_MISO.bid(5 downto 0),
            S_AXI_HP0_bready              => S_AXI_HP0_MOSI.bready,
            S_AXI_HP0_bresp(1 downto 0)   => S_AXI_HP0_MISO.bresp(1 downto 0),
            S_AXI_HP0_bvalid              => S_AXI_HP0_MISO.bvalid,
            S_AXI_HP0_rdata(31 downto 0)  => S_AXI_HP0_MISO.rdata(31 downto 0),
            S_AXI_HP0_rid(5 downto 0)     => S_AXI_HP0_MISO.rid(5 downto 0),
            S_AXI_HP0_rlast               => S_AXI_HP0_MISO.rlast,
            S_AXI_HP0_rready              => S_AXI_HP0_MOSI.rready,
            S_AXI_HP0_rresp(1 downto 0)   => S_AXI_HP0_MISO.rresp(1 downto 0),
            S_AXI_HP0_rvalid              => S_AXI_HP0_MISO.rvalid,
            S_AXI_HP0_wdata(31 downto 0)  => S_AXI_HP0_MOSI.wdata(31 downto 0),
            S_AXI_HP0_wid(5 downto 0)     => S_AXI_HP0_MOSI.wid(5 downto 0),
            S_AXI_HP0_wlast               => S_AXI_HP0_MOSI.wlast,
            S_AXI_HP0_wready              => S_AXI_HP0_MISO.wready,
            S_AXI_HP0_wstrb(3 downto 0)   => S_AXI_HP0_MOSI.wstrb(3 downto 0),
            S_AXI_HP0_wvalid              => S_AXI_HP0_MOSI.wvalid
        );
end STRUCTURE;