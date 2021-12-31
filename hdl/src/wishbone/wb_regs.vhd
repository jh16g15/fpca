library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

--! A simple wishbone B4 slave implementing a register bank
--! Synchronous read, so adds 1 wait state.
--!
--! Supports a maximum of 64 RW and 64 RO registers (all 32-bit) - this is 128 registers or 512 bytes
--! 
--! Addressing:
--! RW registers are 0x000, 0x004 up to 0x0FC
--! RO registers are 0x100, 0x104 up to 0x1FC 
--! 
--! TODOs:
--! - Support 16 bit and 8 bit transactions
--! - 
entity wb_regs is
    generic (
        G_NUM_RW_REGS : integer := 4;
        G_NUM_RO_REGS : integer := 4
    );
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_in  : in t_wb_mosi;
        wb_miso_out : out t_wb_miso;

        rw_regs_out : out t_slv32_arr(G_NUM_RW_REGS - 1 downto 0);
        ro_regs_in  : in  t_slv32_arr(G_NUM_RO_REGS - 1 downto 0)
        );
end entity;

architecture rtl of wb_regs is
    -- Example calc:
    -- 64 regs RW, 64 regs RO
    -- This gives us 64 * 4 bytes per segment = 256 bytes
    -- This needs 8 bits of address space, so 9th bit (ie bit 8) is our bank select bit.
    -- this index can be found with a CLOG2 of the bytes used per segment
    constant C_MAX_RO_RW : integer := 64;
    constant C_BYTES_USED_PER_SEGMENT : integer := (C_MAX_RO_RW) * 4;
    constant C_BANK_SEL_BIT_INDEX : integer := clog2(C_BYTES_USED_PER_SEGMENT);   -- 8
    

    -- storage
    signal rw_regs : t_slv32_arr(G_NUM_RW_REGS - 1 downto 0);
    signal ro_regs : t_slv32_arr(G_NUM_RO_REGS - 1 downto 0);

    -- wb output internal 

begin

    -- this slave can always respond to requests, so no stalling is required
    wb_miso_out.stall <= '0'; 

    -- wishbone slave logic
    wb_proc : process(wb_clk) is
    begin 
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                wb_miso_out.ack <= '0'; 
                wb_miso_out.err <= '0';
                wb_miso_out.rty <= '0';
            else
                -- defaults
                wb_miso_out.ack <= '0';
                wb_miso_out.err <= '0'; -- this slave does not generate ERR or RTY responses
                wb_miso_out.rty <= '0';

                if wb_mosi_in.stb = '1' and wb_miso_out.stall = '0' then    -- assume CYC asserted by master for STB to be high
                    -- always ACK this cycle (sync operation with 1 wait state)
                    wb_miso_out.ack <= '1';

                    -- report("Received transaction with BANK_SEL bit (" & to_string(C_BANK_SEL_BIT_INDEX) & ") = " & to_string(wb_mosi_in.adr(C_BANK_SEL_BIT_INDEX)));
                    -- report("Address Index = " & to_hstring(wb_mosi_in.adr(C_BANK_SEL_BIT_INDEX-1 downto 2)));
                    if wb_mosi_in.we = '1' then
                        -- write logic
                        if (wb_mosi_in.adr(C_BANK_SEL_BIT_INDEX) = '0')  then -- if addressing a RW register
                            rw_regs(slv2uint(wb_mosi_in.adr(C_BANK_SEL_BIT_INDEX-1 downto 2))) <= wb_mosi_in.wdat;   -- write word
                        end if;
                    else 
                        -- read logic
                        if (wb_mosi_in.adr(C_BANK_SEL_BIT_INDEX) = '0')  then -- if addressing a RW register
                            wb_miso_out.rdat <= rw_regs(slv2uint(wb_mosi_in.adr(C_BANK_SEL_BIT_INDEX-1 downto 2)));
                        else
                            wb_miso_out.rdat <= ro_regs(slv2uint(wb_mosi_in.adr(C_BANK_SEL_BIT_INDEX-1 downto 2)));
                        end if;
                    end if;
                end if;

            end if;
        end if;
    end process;

    -- send all RW values out to user logic
    rw_regs_out <= rw_regs;

    -- register all incoming RO register data from user logic
    ro_proc : process (wb_clk) is 
    begin
        if rising_edge(wb_clk) then
            ro_regs <= ro_regs_in;
        end if;
    end process;

end architecture;