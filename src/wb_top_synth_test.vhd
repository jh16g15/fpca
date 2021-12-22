library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

entity wb_top_synth_test is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        done  : out std_logic;

        shift_adr_in : in std_logic;
        shift_wdat_in : in std_logic;
        shift_sel_in : in std_logic;

        cmd_we : in std_logic;
        cmd_req : in std_logic;
        
        cmd_stall : out std_logic;
        cmd_unsigned_flag : std_logic;

        load     : in std_logic;
        rdata_out    : out std_logic

    );
end entity wb_top_synth_test;

architecture rtl of wb_top_synth_test is
    -- shift regs to reduce port numbers so we can synth
    signal adr_shift : std_logic_vector(31 downto 0);

    -- Ports
    signal wb_clk            : std_logic;
    signal wb_reset          : std_logic := '0';
    signal wb_mosi           : t_wb_mosi;
    signal wb_miso           : t_wb_miso;
    signal cmd_addr          : std_logic_vector(C_WB_ADDR_W - 1 downto 0);
    signal cmd_wdata         : std_logic_vector(C_WB_DATA_W - 1 downto 0);
    signal cmd_sel           : std_logic_vector(C_WB_SEL_W - 1 downto 0);
    -- signal cmd_we            : std_logic;
    -- signal cmd_req           : std_logic;
    -- signal cmd_unsigned_flag : std_logic;
    -- signal cmd_stall         : std_logic;
    signal cmd_sign_ext      : std_logic;
    signal rsp_rdata         : std_logic_vector(C_WB_DATA_W - 1 downto 0);
    signal rsp_valid         : std_logic;
    signal rsp_err           : std_logic;

begin

    wb_clk   <= clk;
    wb_reset <= reset;

    rdata_out <= and rsp_rdata;

    addr_inst : entity work.input_shift_synth_helper
    generic map (
      WIDTH => 32
    )
    port map (
      clk => clk,
      shift_in => shift_adr_in,
      load => load,
      dout => cmd_addr
    );
    wdat_inst : entity work.input_shift_synth_helper
    generic map (
      WIDTH => 32
    )
    port map (
      clk => clk,
      shift_in => shift_wdat_in,
      load => load,
      dout => cmd_wdata
    );
    sel_inst : entity work.input_shift_synth_helper
    generic map (
      WIDTH => 4
    )
    port map (
      clk => clk,
      shift_in => shift_sel_in,
      load => load,
      dout => cmd_sel
    );

    -- GOWIN Utilisation
    -- Reg  LUT ALU Desc
    -- 46   68  0   (BRAM=32) cmd_sel is a choice
    -- 41   5   0   (BRAM=32) fixed CMD_SEL_IN=x"F"
    -- 48   74  0   (BRAM=128) cmd_sel is a choice
    --              (BRAM=128) fixed CMD_SEL_IN=x"F" (messes up the BRAM synth somehow?)
    -- 50   74  0   (BRAM=512) cmd_sel is a choice


    -- Xilinx 
    -- (512, var) LUTs: 50, FFs: 58
    -- (512, 0xF) LUTs: 6, FFs: 45
    wb_master_inst : entity work.wb_master
    port map(
        wb_clk               => wb_clk,
        wb_reset             => wb_reset,
        wb_mosi_out          => wb_mosi,
        wb_miso_in           => wb_miso,
        cmd_addr_in          => cmd_addr,
        cmd_wdata_in         => cmd_wdata,
        -- cmd_sel_in           => x"F",
        cmd_sel_in           => cmd_sel,
        cmd_we_in            => cmd_we,
        cmd_req_in           => cmd_req,
        cmd_stall_out        => cmd_stall,
        cmd_unsigned_flag_in => cmd_unsigned_flag,
        rsp_rdata_out        => rsp_rdata,
        rsp_valid_out        => rsp_valid,
        rsp_err_out          => rsp_err
        );
        
        -- BRAM utilization (GOWIN)
        -- Depth    Utils
        -- 8192     16 (Only 10 available, so implementation fails)
        -- 4096     8   (also 1 register and 8 LUTs)
        -- 2048     4   (also 1 register and 8 LUTs)
        -- 1024     4   (also 1 register and 8 LUTs)
        --  512     4   (also 1 register and 8 LUTs)
        --  256     4
        --  128     4
        --   64     4   (alt/default: syn_ramstyle=registers 2081 FF)
        --   32     0   (alt/default: syn_ramstyle=registers 1057 FF)
        -- Xilinx
        -- (512, var) LUTs: 32 LUTRAMs: 256, FFs: 33
        -- (512, 0xF) LUTs: 23 LUTRAMs: 256, FFs: 33
    wb_sp_bram_inst : entity work.wb_sp_bram
        generic map(
            G_MEM_DEPTH_WORDS => 2048,
            G_INIT_FILE       => ""
        )
        port map(
            wb_clk      => wb_clk,
            wb_reset    => wb_reset,
            wb_mosi_in  => wb_mosi,
            wb_miso_out => wb_miso
        );
end architecture;