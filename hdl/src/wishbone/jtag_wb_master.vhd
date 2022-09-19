----------------------------------------------------------------------------------
-- Joseph Hindmarsh Septemper 2022
--
-- Connects a Xilinx JTAG AXI4-Lite Master to a wishbone bus
--
-- TODOs:
--  * testbench
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;

entity jtag_wb_master is
    generic (
        G_ILA : boolean := true
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;

        wb_mosi_out : out t_wb_mosi;
        wb_miso_in  : in t_wb_miso

    );
end entity jtag_wb_master;

architecture rtl of jtag_wb_master is
    component jtag_axi_0
        port (
            aclk          : in std_logic;
            aresetn       : in std_logic;
            m_axi_awaddr  : out std_logic_vector(31 downto 0);
            m_axi_awprot  : out std_logic_vector(2 downto 0);
            m_axi_awvalid : out std_logic;
            m_axi_awready : in std_logic;
            m_axi_wdata   : out std_logic_vector(31 downto 0);
            m_axi_wstrb   : out std_logic_vector(3 downto 0);
            m_axi_wvalid  : out std_logic;
            m_axi_wready  : in std_logic;
            m_axi_bresp   : in std_logic_vector(1 downto 0);
            m_axi_bvalid  : in std_logic;
            m_axi_bready  : out std_logic;
            m_axi_araddr  : out std_logic_vector(31 downto 0);
            m_axi_arprot  : out std_logic_vector(2 downto 0);
            m_axi_arvalid : out std_logic;
            m_axi_arready : in std_logic;
            m_axi_rdata   : in std_logic_vector(31 downto 0);
            m_axi_rresp   : in std_logic_vector(1 downto 0);
            m_axi_rvalid  : in std_logic;
            m_axi_rready  : out std_logic
        );
    end component;

    signal resetn : std_logic;

    signal m_axi_awaddr  : std_logic_vector(31 downto 0);
    signal m_axi_awvalid : std_logic;
    signal m_axi_awready : std_logic;
    signal m_axi_wdata   : std_logic_vector(31 downto 0);
    signal m_axi_wstrb   : std_logic_vector(3 downto 0);
    signal m_axi_wvalid  : std_logic;
    signal m_axi_wready  : std_logic;
    signal m_axi_bresp   : std_logic_vector(1 downto 0);
    signal m_axi_bvalid  : std_logic;
    signal m_axi_bready  : std_logic;
    signal m_axi_araddr  : std_logic_vector(31 downto 0);
    signal m_axi_arvalid : std_logic;
    signal m_axi_arready : std_logic;
    signal m_axi_rdata   : std_logic_vector(31 downto 0);
    signal m_axi_rresp   : std_logic_vector(1 downto 0);
    signal m_axi_rvalid  : std_logic;
    signal m_axi_rready  : std_logic;

    type t_state is (IDLE, AXI_READ_RESPONSE, AXI_WRITE_RESPONSE, AXI_READ, AXI_GET_WDATA, AXI_WRITE);
    signal state : t_state := IDLE;

    attribute mark_debug                  : boolean;
    attribute mark_debug of state         : signal is G_ILA;
    attribute mark_debug of m_axi_awaddr  : signal is G_ILA;
    attribute mark_debug of m_axi_awvalid : signal is G_ILA;
    attribute mark_debug of m_axi_awready : signal is G_ILA;
    attribute mark_debug of m_axi_wdata   : signal is G_ILA;
    attribute mark_debug of m_axi_wstrb   : signal is G_ILA;
    attribute mark_debug of m_axi_wvalid  : signal is G_ILA;
    attribute mark_debug of m_axi_wready  : signal is G_ILA;
    attribute mark_debug of m_axi_bresp   : signal is G_ILA;
    attribute mark_debug of m_axi_bvalid  : signal is G_ILA;
    attribute mark_debug of m_axi_bready  : signal is G_ILA;
    attribute mark_debug of m_axi_araddr  : signal is G_ILA;
    attribute mark_debug of m_axi_arvalid : signal is G_ILA;
    attribute mark_debug of m_axi_arready : signal is G_ILA;
    attribute mark_debug of m_axi_rdata   : signal is G_ILA;
    attribute mark_debug of m_axi_rresp   : signal is G_ILA;
    attribute mark_debug of m_axi_rvalid  : signal is G_ILA;
    attribute mark_debug of m_axi_rready  : signal is G_ILA;
begin
    -- AXI handshaking: Master can assert VALID at any time, we can deassert READY whenever we want (possible to depend on VALID)
    resetn <= not reset;
    -- assume the AXI JTAG/TCL script only sends one command at a time (and never simultaneous read/write!)
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state         <= IDLE;
                m_axi_arready <= '0';
                m_axi_awready <= '0';
                m_axi_wready  <= '0';
                m_axi_rvalid  <= '0';
                m_axi_bvalid  <= '0';
            else
                case(state) is

                    when IDLE => -- prioritise READ
--                    m_axi_arready <= '1';
--                    m_axi_awready <= '1';
--                    if m_axi_arvalid = '1' and m_axi_arready = '1' then
                    if m_axi_arvalid = '1' then
                        state           <= AXI_READ;
                        m_axi_arready   <= '1'; --ACK read address
                        wb_mosi_out.adr <= m_axi_araddr;
                        wb_mosi_out.cyc <= '1'; -- issue WB transaction
                        wb_mosi_out.stb <= '1';
                        wb_mosi_out.we  <= '0';
--                    elsif m_axi_awvalid = '1' and m_axi_awready = '1' then
                    elsif m_axi_awvalid = '1' then
                        state           <= AXI_GET_WDATA;
                        m_axi_awready   <= '1'; --ACK write address
                        wb_mosi_out.adr <= m_axi_awaddr;
                    end if;

                    when AXI_READ =>               -- wait for WB to be accepted
                    m_axi_arready   <= '0';
                    if wb_miso_in.stall = '0' then -- WB accept transaction
                        wb_mosi_out.stb <= '0';
                    end if;
                    if wb_miso_in.ack = '1' then
                        wb_mosi_out.cyc <= '0'; -- end WB transaction
                        m_axi_rvalid    <= '1'; -- start read response handshake
                        m_axi_rdata     <= wb_miso_in.rdat;
                        m_axi_rresp     <= b"00"; --AXI_OKAY
                        state           <= AXI_READ_RESPONSE;
                    end if;
                    if wb_miso_in.err = '1' then
                        wb_mosi_out.cyc <= '0'; -- end WB transaction
                        m_axi_rvalid    <= '1'; -- start read response handshake
                        m_axi_rdata     <= wb_miso_in.rdat;
                        m_axi_rresp     <= b"10"; --AXI_SLVERR
                        state           <= AXI_READ_RESPONSE;
                    end if;
                    when AXI_READ_RESPONSE => -- wait for AXI read response to be accepted
                    if m_axi_rready = '1' then
                        m_axi_rvalid <= '0';
                        state        <= IDLE;
                    end if;

                    when AXI_GET_WDATA =>
                    m_axi_awready   <= '0'; 
                    if m_axi_wvalid = '1' then
                        state            <= AXI_WRITE;
                        m_axi_wready     <= '1'; --ACK wdata
                        wb_mosi_out.wdat <= m_axi_wdata;
                        wb_mosi_out.sel  <= m_axi_wstrb;
                        wb_mosi_out.cyc  <= '1'; -- issue WB transaction
                        wb_mosi_out.stb  <= '1';
                        wb_mosi_out.we   <= '1';
                    end if;

                    when AXI_WRITE =>
                    m_axi_wready     <= '0';
                    if wb_miso_in.stall = '0' then -- wait for WB to be accepted
                        wb_mosi_out.stb <= '0';
                    end if;
                    if wb_miso_in.ack = '1' then
                        wb_mosi_out.cyc <= '0';   -- end WB transaction
                        m_axi_bvalid    <= '1';   -- start write response handshake
                        m_axi_bresp     <= b"00"; --AXI_OKAY
                        state           <= AXI_WRITE_RESPONSE;
                    end if;
                    if wb_miso_in.err = '1' then
                        wb_mosi_out.cyc <= '0';   -- end WB transaction
                        m_axi_bvalid    <= '1';   -- start write response handshake
                        m_axi_bresp     <= b"10"; --AXI_SLVERR
                        state           <= AXI_WRITE_RESPONSE;
                    end if;

                    when AXI_WRITE_RESPONSE => -- wait for AXI read response to be accepted
                    if m_axi_bready = '1' then
                        m_axi_bvalid <= '0';
                        state        <= IDLE;
                    end if;
                end case;
            end if;
        end if;
    end process;
    -- read and write queue is 1 transaction (each)

    
--    jtag_axi_0_inst : jtag_axi_0
--    port map(
--        aclk          => clk,
--        aresetn       => resetn,
--        m_axi_awaddr  => m_axi_awaddr,
--        m_axi_awprot  => open,
--        m_axi_awvalid => m_axi_awvalid,
--        m_axi_awready => m_axi_awready,
--        m_axi_wdata   => m_axi_wdata,
--        m_axi_wstrb   => m_axi_wstrb,
--        m_axi_wvalid  => m_axi_wvalid,
--        m_axi_wready  => m_axi_wready,
--        m_axi_bresp   => m_axi_bresp,
--        m_axi_bvalid  => m_axi_bvalid,
--        m_axi_bready  => m_axi_bready,
--        m_axi_araddr  => m_axi_araddr,
--        m_axi_arprot  => open,
--        m_axi_arvalid => m_axi_arvalid,
--        m_axi_arready => m_axi_arready,
--        m_axi_rdata   => m_axi_rdata,
--        m_axi_rresp   => m_axi_rresp,
--        m_axi_rvalid  => m_axi_rvalid,
--        m_axi_rready  => m_axi_rready
--    );    
    debug_jtag_bd_inst : entity work.debug_jtag_wrapper
    port map(
        aclk          => clk,
        aresetn       => resetn,
        M_AXI_awaddr  => m_axi_awaddr,
        M_AXI_awprot  => open,
        M_AXI_awvalid => m_axi_awvalid,
        M_AXI_awready => m_axi_awready,
        M_AXI_wdata   => m_axi_wdata,
        M_AXI_wstrb   => m_axi_wstrb,
        M_AXI_wvalid  => m_axi_wvalid,
        M_AXI_wready  => m_axi_wready,
        M_AXI_bresp   => m_axi_bresp,
        M_AXI_bvalid  => m_axi_bvalid,
        M_AXI_bready  => m_axi_bready,
        M_AXI_araddr  => m_axi_araddr,
        M_AXI_arprot  => open,
        M_AXI_arvalid => m_axi_arvalid,
        M_AXI_arready => m_axi_arready,
        M_AXI_rdata   => m_axi_rdata,
        M_AXI_rresp   => m_axi_rresp,
        M_AXI_rvalid  => m_axi_rvalid,
        M_AXI_rready  => m_axi_rready
    );
end architecture;