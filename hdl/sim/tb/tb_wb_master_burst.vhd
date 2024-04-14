
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all; -- 32 bit port, 8 bit granularity
--
library vunit_lib;
context vunit_lib.vunit_context;

-- for non-blocking WB transactions (queue)
library osvvm;
use osvvm.ScoreBoardPkg_slv.all;

entity tb_wb_master_burst is
  generic
  (
    runner_cfg : string
  );
end;

architecture bench of tb_wb_master_burst is
  -- Clock period
  constant clk_period : time := 10 ns;
  -- Generics
  constant G_MAX_BURST_TRANSFERS : integer := 8;
  -- Ports
  signal wb_clk        : std_logic := '0';
  signal wb_reset      : std_logic := '0';
  signal wb_mosi       : t_wb_mosi;
  signal wb_miso       : t_wb_miso;
  signal cmd_addr_in   : std_logic_vector(31 downto 0);
  signal cmd_wdata_in  : std_logic_vector(31 downto 0);
  signal cmd_sel_in    : std_logic_vector(3 downto 0);
  signal cmd_we_in     : std_logic;
  signal cmd_valid_in  : std_logic;
  signal cmd_ready_out : std_logic;
  signal rsp_rdata_out : std_logic_vector(31 downto 0);
  signal rsp_valid_out : std_logic;
  signal rsp_err_out   : std_logic;

  signal SB_Req : ScoreBoardIDType;

  constant ascending_sulv  : std_ulogic_vector(22 to 23)   := "UX";
  constant descending_sulv : std_ulogic_vector(9 downto 1) := "000111UUU";

  constant joe_tmp : std_logic_vector(64 downto 0) := "1" & x"0123_4567" & x"89ab_cdef";

    signal SB_Rsp_Addr : ScoreBoardIDType;
    signal SB_Rsp_Rdata : ScoreBoardIDType;
    signal SB_Rsp_WE : ScoreBoardIDType;
begin

  rsp_proc : process is
  begin
    wait;
  end process;
  req_proc : process
    variable result : std_logic_vector(64 downto 0);

    procedure queue_write(addr, wdata : in std_logic_vector(31 downto 0)) is
    begin      
      info("add write to " & to_hstring(addr) & " " & to_hstring(wdata) & " to queue");
      push(SB_Req, "1" & wdata & addr);
      wait for 0 ns;
    end procedure;
    procedure queue_read(addr : in std_logic_vector(31 downto 0)) is
    begin
      info("add read from " & to_hstring(addr) & " to queue");
      push(SB_Req, "0" & x"0000_0000" & addr);      
      wait for 0 ns;
    end procedure;

    procedure execute_burst is
      variable transaction : std_logic_vector(64 downto 0);
      variable addr        : std_logic_vector(31 downto 0);
      variable data        : std_logic_vector(31 downto 0);
      variable we          : std_logic;
      variable tmp         : integer;
    begin
      while not osvvm.ScoreBoardPkg_slv.Empty(SB_Req) loop
        info("peeking");
        Peek(SB_Req, transaction);
        info("popping from queue");
        pop(SB_Req, transaction);
        -- transaction := pop_std_ulogic_vector(SB_Req);
        info("popped " & to_hstring(transaction));
        addr := transaction(31 downto 0);
        data := transaction(63 downto 32);
        we   := transaction(64);
        cmd_valid_in <= '1';
        cmd_addr_in  <= addr;
        cmd_wdata_in <= data;
        cmd_sel_in   <= x"F";
        cmd_we_in    <= we;
        info("begin wait");
        wait until cmd_ready_out = '1' and rising_edge(wb_clk);
        info("wait done");
        if we = '1' then
          info("writing " & to_hstring(data) & " to " & to_hstring(addr));
        else
          info("reading from " & to_hstring(addr));
        end if;
        cmd_valid_in <= '0';
      end loop;
    end procedure;

  begin
    test_runner_setup(runner, runner_cfg);
    show(get_logger("check"), display_handler, pass);
    SB_Req <= NewID("SB_Req_name");
    SB_Rsp_Addr <= NewID("Rsp_Address");
    SB_Rsp_Rdata <= NewID("Rsp_RData");
    SB_Rsp_WE <=  := NewID("Rsp_WE");

    while test_suite loop
      if run("test_alive") then
        info("Hello world test_alive");
        wait for 10 * clk_period;

        queue_write(x"0000_0000", x"ffff_ffff");
        queue_write(x"0000_0004", x"1122_3344");
        execute_burst;

        wait for 20 * clk_period;
      end if;
    end loop;
    test_runner_cleanup(runner);
  end process;

  wb_master_burst_inst : entity work.wb_master_burst
    generic
    map (
    G_MAX_BURST_TRANSFERS => G_MAX_BURST_TRANSFERS
    )
    port map
    (
      wb_clk        => wb_clk,
      wb_reset      => wb_reset,
      wb_mosi_out   => wb_mosi,
      wb_miso_in    => wb_miso,
      cmd_addr_in   => cmd_addr_in,
      cmd_wdata_in  => cmd_wdata_in,
      cmd_sel_in    => cmd_sel_in,
      cmd_we_in     => cmd_we_in,
      cmd_valid_in  => cmd_valid_in,
      cmd_ready_out => cmd_ready_out,
      rsp_rdata_out => rsp_rdata_out,
      rsp_valid_out => rsp_valid_out,
      rsp_err_out   => rsp_err_out
    );

  -- the BRAM supports bursts just fine
  wb_sp_bram_inst : entity work.wb_sp_bram
    generic
    map(
    G_MEM_DEPTH_WORDS => 256,
    G_INIT_FILE       => ""
    )
    port
    map(
    wb_clk      => wb_clk,
    wb_reset    => wb_reset,
    wb_mosi_in  => wb_mosi,
    wb_miso_out => wb_miso
    );

  wb_clk <= not wb_clk after clk_period/2;

end;