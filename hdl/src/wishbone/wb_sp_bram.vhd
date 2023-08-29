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
--! This module uses a minimum of 4 BRAMS, with which we can go up to 2048 32-bit words
--! G_MEM_DEPTH_WORDS=8096 words requires 8 BRAMs
--!
entity wb_sp_bram is
    generic (
        G_MEM_DEPTH_WORDS : integer := 512; --! Must be a power of 2
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

    constant C_WORD_ADR_W : integer := clog2(G_MEM_DEPTH_WORDS);

    -- slice off the word address from the Wishbone BYTE address 
    -- (even though addresses should be 32-bit aligned and thus [1:0]=b"00" anyway)
    constant C_WORD_ADR_H : integer := C_WORD_ADR_W+2-1;
    constant C_WORD_ADR_L : integer := 2;

    signal mem32 : t_slv32_arr(0 to G_MEM_DEPTH_WORDS - 1) := init_mem32(G_INIT_FILE, G_MEM_DEPTH_WORDS);

    signal dbg_word_addr : std_logic_vector(C_WORD_ADR_W-1 downto 0);
    
begin
    -- this slave can always respond to requests, so no stalling is required
    wb_miso_out.stall <= '0';

    --! unsupported
    wb_miso_out.err <= '0';
    wb_miso_out.rty <= '0';

    dbg_word_addr <= wb_mosi_in.adr(C_WORD_ADR_H downto C_WORD_ADR_L);

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
                        if wb_mosi_in.sel(i) = '1' then -- if this byte is selected
                            if wb_mosi_in.we = '1' then
                                -- synchronous write logic
                                mem32(slv2uint(wb_mosi_in.adr(C_WORD_ADR_H downto C_WORD_ADR_L)))(8 * (i + 1) - 1 downto 8 * i) <= wb_mosi_in.wdat(8 * (i + 1) - 1 downto 8 * i); -- write byte
                            end if;
                        end if;
                        -- synchronous read logic
                        wb_miso_out.rdat(8 * (i + 1) - 1 downto 8 * i) <= mem32(slv2uint(wb_mosi_in.adr(C_WORD_ADR_H downto C_WORD_ADR_L)))(8 * (i + 1) - 1 downto 8 * i); -- read byte
                    end loop;
                end if;

            end if;
        end if;
    end process;

end architecture;