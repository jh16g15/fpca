library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

--! A simple wishbone B4 slave implementing a single port BRAM
--! Synchronous read, so adds 1 wait state.
--!
--! - 32 bit port width, 8 bit granularity 
--! 
--!  See http://cdn.gowinsemi.com.cn/SUG550E.pdf for GOWIN HDL coding guidelines
--!
--! Each GOWIN BRAM is 2Kbytes (512x32 (no true dual-port), 1024x16, 2048x8)
--!
entity wb_sp_bram is
    generic (
        G_MEM_ADR_W : integer := 9; -- 512 words, should use 1 BRAM
        G_INIT_FILE : string  := "" -- relative path?
    );
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_in  : in t_wb_mosi;
        wb_miso_out : out t_wb_miso

    );
end entity;

architecture rtl of wb_sp_bram is
    constant C_RAM_DEPTH_WORDS : integer := 2 ** G_MEM_ADR_W;
    signal dbg_mem                 : t_slv32_arr(0 to C_RAM_DEPTH_WORDS - 1);

    type t_mem_arr is array(3 downto 0) of t_slv8_arr(0 to C_RAM_DEPTH_WORDS - 1);

    signal mem_arr : t_mem_arr := (
        3 => init_mem32_bytes(G_INIT_FILE, C_RAM_DEPTH_WORDS, 3),
        2 => init_mem32_bytes(G_INIT_FILE, C_RAM_DEPTH_WORDS, 2),
        1 => init_mem32_bytes(G_INIT_FILE, C_RAM_DEPTH_WORDS, 1),
        0 => init_mem32_bytes(G_INIT_FILE, C_RAM_DEPTH_WORDS, 0)
    );
begin
    --! Assemble the individual byte memories into one for easier waveform viewing
    dbg_proc : process(all) is
    begin
        for i in 0 to C_RAM_DEPTH_WORDS-1 loop
            dbg_mem(i) <= (mem_arr(3)(i), mem_arr(2)(i), mem_arr(1)(i), mem_arr(0)(i));
        end loop;
    end process;


    -- this slave can always respond to requests, so no stalling is required
    wb_miso_out.stall <= '0';

    --! unsupported
    wb_miso_out.err <= '0';
    wb_miso_out.rty <= '0';

    --! Add our 1 cycle wait state for reads
    wb_ack_proc : process (wb_clk, wb_reset) is
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                wb_miso_out.ack <= '0';
            else
                wb_miso_out.ack <= wb_mosi_in.stb and (not wb_miso_out.stall);
            end if;
        end if;
    end process;
    -- wishbone slave logic
    wb_proc : process (wb_clk) is
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                null;
            else
                -- assume CYC asserted by master for STB to be high
                if wb_mosi_in.stb = '1' and wb_miso_out.stall = '0' then
                    for i in 0 to 3 loop
                        if wb_mosi_in.sel(i) then   -- if tgis byte is selected
                            if wb_mosi_in.we = '1' then
                                -- synchronous write logic
                                mem_arr(i)(slv2uint(wb_mosi_in.adr(G_MEM_ADR_W + 2 - 1 downto 2))) <= wb_mosi_in.wdat(8 * (i + 1) - 1 downto 8 * i); -- write byte
                            else
                                -- synchronous read logic
                                wb_miso_out.rdat(8 * (i + 1) - 1 downto 8 * i) <= mem_arr(i)(slv2uint(wb_mosi_in.adr(G_MEM_ADR_W + 2 - 1 downto 2)));   -- read byte
                            end if;
                        end if;
                    end loop;
                end if;

            end if;
        end if;
    end process;

end architecture;