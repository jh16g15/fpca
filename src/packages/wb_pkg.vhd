library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package wb_pkg is

    constant C_WB_ADDR_W : integer := 32;
    constant C_WB_DATA_W : integer := 32;
    constant C_WB_SEL_W  : integer := C_WB_DATA_W/8; -- 8 bit granularity

    -- the Wishbone B4 spec defines a "word" as 16 bits, so to avoid confusion:
    type t_transfer_size is (b8, b16, b32);

    --! Core Wishbone signals - Master to Slave
    type t_wb_mosi is record
        adr  : std_logic_vector(C_WB_ADDR_W - 1 downto 0); --! Target Address of Wishbone transaction
        wdat : std_logic_vector(C_WB_DATA_W - 1 downto 0); --! Master -> Slave data transfer
        we   : std_logic;                                  --! Write Enable 
        sel  : std_logic_vector(C_WB_SEL_W - 1 downto 0);  --! Which wdat/rdat bytes are valid
        stb  : std_logic;                                  --! Strobe for adr/wdat valid
        cyc  : std_logic;                                  --! Bus Cycle in progress
        lock : std_logic;                                  --! Uninterruptible transfer - Do not transfer to another bus master until LOCK=0 or CYC=0 
    end record;

    --! Core Wishbone signals - Slave to Master 
    type t_wb_miso is record
        rdat  : std_logic_vector(C_WB_DATA_W - 1 downto 0); --! Slave -> Master data transfer
        stall : std_logic;                                  --! Slave not ready to accept transfer
        ack   : std_logic;                                  --! Slave OKAY response
        err   : std_logic;                                  --! Slave ERROR response (generate in interconnect)
        rty   : std_logic;                                  --! Slave RETRY response (not implemented)
    end record;

    constant C_WB_MOSI_INIT : t_wb_mosi := (
        adr => (others => '0'),
        wdat => (others => '0'),
        we   => '0',
        sel => (others => '0'),
        stb  => '0',
        cyc  => '0',
        lock => '0'
    );

    constant C_WB_MISO_INIT : t_wb_miso := (
        rdat => (others => '0'),
        stall => '1',
        ack   => '0',
        err   => '0',
        rty   => '0'
    );

    --! utility functions to pack a (partial) list of Wishbone MOSI signals into a t_wb_mosi record
    function wb_pack_mosi(adr, wdat, sel : std_logic_vector; we, stb, cyc, lock : std_logic) return t_wb_mosi;
    function wb_pack_mosi(adr, wdat, sel : std_logic_vector; we, stb, cyc : std_logic) return t_wb_mosi;

    --! utility function to pack a (partial) list of Wishbone MISO signals into a t_wb_miso record
    function wb_pack_miso(rdat : std_logic_vector; stall, ack, err, rty : std_logic) return t_wb_miso;
    function wb_pack_miso(rdat : std_logic_vector; stall, ack : std_logic) return t_wb_miso;

    --! Converts a Byte Address (with a transaction size in Bytes) to a 32-bit aligned Wishbone Address 
    --! and the appropriate SEL signals
    procedure wb_byte_addr_to_byte_sel(byte_addr : in std_logic_vector; transfer_size : in t_transfer_size := b32; wb_addr : out std_logic_vector; wb_sel : out std_logic_vector);

    --! Align the valid part of the 32 bit input data to the wishbone 32 bit data bus 
    function wb_align_store_data(wdata : std_logic_vector(31 downto 0); byte_sel : std_logic_vector(3 downto 0)) return std_logic_vector;
end package;

package body wb_pkg is

    --! utility function to pack a (partial) list of Wishbone MOSI signals into a t_wb_mosi record
    function wb_pack_mosi (adr, wdat, sel : std_logic_vector; we, stb, cyc, lock : std_logic) return t_wb_mosi is
    begin
        return (adr => adr, wdat => wdat, sel => sel, we => we, stb => stb, cyc => cyc, lock => lock);
    end function;
    function wb_pack_mosi (adr, wdat, sel : std_logic_vector; we, stb, cyc : std_logic) return t_wb_mosi is
    begin
        return (adr => adr, wdat => wdat, sel => sel, we => we, stb => stb, cyc => cyc, lock => C_WB_MOSI_INIT.lock);
    end function;

    --! utility function to pack a (partial) list of Wishbone MISO signals into a t_wb_miso record
    function wb_pack_miso (rdat : std_logic_vector; stall, ack, err, rty : std_logic) return t_wb_miso is
    begin
        return (rdat => rdat, stall => stall, ack => ack, err => err, rty => rty);
    end function;
    function wb_pack_miso (rdat : std_logic_vector; stall, ack : std_logic) return t_wb_miso is
    begin
        return (rdat => rdat, stall => stall, ack => ack, err => C_WB_MISO_INIT.err, rty => C_WB_MISO_INIT.rty);
    end function;

    --! Converts a Byte Address (with a transaction size in Bytes) to a 32-bit aligned Wishbone Address 
    --! and the appropriate SEL signals
    procedure wb_byte_addr_to_byte_sel(byte_addr : in std_logic_vector; transfer_size : in t_transfer_size := b32; wb_addr : out std_logic_vector; wb_sel : out std_logic_vector) is
        variable byte_portion : std_logic_vector (1 downto 0);
    begin
        -- make 32 bit aligned by setting bottom two bits to 0
        wb_addr(1 downto 0)              := b"00";
        wb_addr(byte_addr'left downto 2) := byte_addr(byte_addr'left downto 2);
        byte_portion                     := byte_addr(1 downto 0);
        -- report "Converting Addr " & to_hstring(byte_addr) & " with byte portion = " & to_hstring(byte_portion) & " and transfer_width " & to_string(transfer_size);
        -- bounds checking
        case byte_portion is
            when b"00" => -- 32 bit aligned, all permitted
                case(transfer_size) is
                when b8     => wb_sel     := b"0001";
                when b16    => wb_sel    := b"0011";
                when b32    => wb_sel    := b"1111";
                when others => wb_sel := b"0000";
                end case;
            when b"01" => -- only byte access permitted
                case(transfer_size) is
                when b8     => wb_sel     := b"0010";
                when others => wb_sel := b"0000";
                end case;
            when b"10" => -- 16 bit alighned, BYTE and 2BYTES permitted
                case(transfer_size) is
                when b8     => wb_sel     := b"0100";
                when b16    => wb_sel    := b"1100";
                when others => wb_sel := b"0000";
                end case;
            when b"11" => -- only byte access permitted
                case(transfer_size) is
                when b8     => wb_sel     := b"1000";
                when others => wb_sel := b"0000";
                end case;
            when others =>
                null;
        end case;
    end procedure;

    --! Align the valid part of the 32 bit input data to the wishbone 32 bit data bus
    function wb_align_store_data(wdata : std_logic_vector(31 downto 0); byte_sel : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case (byte_sel) is
            when b"1111" => return wdata;
            when b"0011" => return x"0000" & wdata(15 downto 0);
            when b"1100" => return wdata(15 downto 0) & x"0000";
            when b"0001" => return x"000000" & wdata(7 downto 0);
            when b"0010" => return x"0000" & wdata(7 downto 0) & x"00";
            when b"0100" => return x"00" & wdata(7 downto 0) & x"0000";
            when b"1000" => return wdata(7 downto 0) & x"000000";
            when others  => return wdata;
        end case;
    end function;
end package body;