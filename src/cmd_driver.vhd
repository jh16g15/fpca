library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;
entity cmd_driver is
    generic (G_SEVERITY : severity_level := error);
    port (
        clk   : in std_logic;
        reset : in std_logic;
        done  : out std_logic;

        -- command bus
        cmd_addr_out  : out std_logic_vector(C_WB_ADDR_W - 1 downto 0);
        cmd_wdata_out : out std_logic_vector(C_WB_DATA_W - 1 downto 0);
        cmd_sel_out   : out std_logic_vector(C_WB_SEL_W - 1 downto 0); --! positions of read/write data
        cmd_we_out    : out std_logic;
        cmd_req_out   : out std_logic;
        cmd_stall_in  : in std_logic;

        -- response bus
        rsp_rdata_in : in std_logic_vector(C_WB_DATA_W - 1 downto 0);
        rsp_valid_in : in std_logic;
        -- rsp_stall     : out std_logic;    -- RDATA backpressure not implemented
        rsp_err : in std_logic

    );
end entity cmd_driver;

architecture rtl of cmd_driver is
    constant C_NUM_CMDS : integer := 20;

    constant CMD_H : integer := 71; constant CMD_L : integer := 68;
    constant SIZ_H : integer := 67; constant SIZ_L : integer := 64;
    constant ADR_H : integer := 63; constant ADR_L : integer := 32;
    constant DAT_H : integer := 31; constant DAT_L : integer := 0;

    -- R/W, ADDR, DATA
    type t_cmd_mem is array(0 to C_NUM_CMDS - 1) of std_logic_vector(71 downto 0);

    function init_cmd_mem return t_cmd_mem is
        variable mem : t_cmd_mem                    := (others => (others => '0'));
        constant R   : std_logic_vector(3 downto 0) := x"0"; -- READ
        constant W   : std_logic_vector(3 downto 0) := x"1"; -- WRITE
        constant RL  : std_logic_vector(3 downto 0) := x"8"; -- LASTREAD
        constant WL  : std_logic_vector(3 downto 0) := x"9"; -- LASTWRITE

        constant SBYTE : std_logic_vector(3 downto 0) := b"0000";
        constant UBYTE : std_logic_vector(3 downto 0) := b"0100";
        constant SHALF : std_logic_vector(3 downto 0) := b"0001";
        constant UHALF : std_logic_vector(3 downto 0) := b"0101";
        constant WORD  : std_logic_vector(3 downto 0) := b"0010";
    begin
        -- write
        mem(0) := W & WORD & x"0000_0000" & x"C001_C0DE";
        mem(1) := W & WORD & x"0000_0004" & x"1111_1111";
        mem(2) := W & WORD & x"0000_0008" & x"2222_2222";
        mem(3) := W & WORD & x"0000_000C" & x"3333_3333";
        mem(4) := W & WORD & x"0000_0010" & x"4444_4444";
        -- then read and verify
        mem(5) := R & WORD & x"0000_0000" & x"C001_C0DE";
        mem(6) := R & WORD & x"0000_0004" & x"1111_1111";
        mem(7) := R & WORD & x"0000_0008" & x"2222_2222";
        mem(8) := R & WORD & x"0000_000C" & x"3333_3333";
        mem(9) := RL & WORD & x"0000_0010" & x"4444_4444";
        return mem;
    end function;

    signal cmd_mem  : t_cmd_mem := init_cmd_mem;
    signal index    : integer   := 0;
    signal cmd_done : std_logic;
    signal rsp_done : std_logic;
begin

    done <= rsp_done;

    process (clk)
        variable wen  : std_logic;
        variable last : std_logic;
        variable addr : std_logic_vector(31 downto 0);
        variable data : std_logic_vector(31 downto 0);
        variable size : std_logic_vector(3 downto 0);

        variable exp_rdat : std_logic_vector(31 downto 0);

        variable byte_sel  : std_logic_vector(3 downto 0);
        variable word_addr : std_logic_vector(31 downto 0);

        variable cmd_count : integer := 0;
        variable rsp_count : integer := 0;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                index       <= 0;
                cmd_req_out <= '0';
                cmd_done    <= '0';
                rsp_done    <= '0';
            else
                -- command writing
                if cmd_stall_in = '0' and cmd_done = '0' then -- start next command
                    last := cmd_mem(index)(CMD_H);
                    wen  := cmd_mem(index)(CMD_L);
                    size := cmd_mem(index)(SIZ_H downto SIZ_L);
                    addr := cmd_mem(index)(ADR_H downto ADR_L);
                    data := cmd_mem(index)(DAT_H downto DAT_L);

                    cmd_req_out  <= '1';
                    cmd_addr_out <= addr;

                    cmd_count := cmd_count + 1;

                    if wen = '1' then
                        cmd_wdata_out <= data;
                        cmd_we_out    <= '1';
                    else
                        cmd_wdata_out <= x"FFFF_FFFF";
                        cmd_we_out    <= '0';
                    end if;

                    wb_byte_addr_to_word(addr, b32, word_addr, byte_sel);
                    cmd_sel_out <= byte_sel;
                    if index = C_NUM_CMDS - 1 then
                        cmd_done <= '1'; -- stop sending commands
                    else
                        index <= index + 1;
                    end if;

                    if last = '1' then
                        cmd_done <= '1'; -- stop sending commands
                    end if;

                end if;

                -- response handling
                if rsp_valid_in = '1' then
                    report("Received Response num= " & to_string(rsp_count));
                    report("Original CMD         = " & to_hstring(cmd_mem(rsp_count)));
                    exp_rdat := cmd_mem(rsp_count)(DAT_H downto DAT_L);

                    assert rsp_err = '0' report "RESPONSE ERROR!" severity G_SEVERITY;
                    if cmd_mem(rsp_count)(CMD_L) = '0' then -- if was a read
                        assert rsp_rdata_in = exp_rdat report "RDATA MISMATCH ERROR! Received: " & to_hstring(rsp_rdata_in) & " Expected: " & to_hstring(exp_rdat) severity G_SEVERITY;
                    end if;

                    rsp_count := rsp_count + 1;

                    if (cmd_count = rsp_count) and cmd_done = '1' then
                        rsp_done <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;