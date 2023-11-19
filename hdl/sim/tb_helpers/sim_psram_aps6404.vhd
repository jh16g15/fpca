library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

use vunit_lib.memory_pkg.all;

--! Very basic simulation model of APS6404 PSRAM
--! Only supports a handful of commands
entity sim_psram_aps6404 is
    port
    (
        psram_clk  : in std_logic;
        psram_cs_n : in std_logic;
        psram_sio  : inout std_logic_vector(3 downto 0)
    );
end entity sim_psram_aps6404;

architecture rtl of sim_psram_aps6404 is
    constant logger : logger_t := get_logger("psram");
    -- start in SPI mode
    signal mode_qpi     : std_logic := '0';
    signal bits_per_clk : integer   := 1;

    --command buffer - 1 byte opcode, 3 bytes address
    type t_byte_arr is array (natural range <>) of std_logic_vector(7 downto 0);
    signal psram_qpi_direction_input : std_logic := '1';
begin

    process is

        -- Simulated PSRAM memory buffer, using VUnit memory model
        variable memory : memory_t := new_memory;
        variable buf : buffer_t := allocate(memory, 64 * 1024); -- allocate 64KB

        -- byte shift buffers
        variable shift_in_buf  : std_logic_vector(8 - 1 downto 0);
        variable shift_out_buf : std_logic_vector(8 - 1 downto 0);
        variable bit_counter   : integer := 0;
        variable byte_counter  : integer := 0;
        variable psram_address : integer;
        variable cmd_buffer    : t_byte_arr(0 to 3);

        -- Procedure to shift a byte IN
        procedure psram_shift_byte_in is
        begin
            bit_counter := 0;
            while (bit_counter /= 8) loop
                wait until rising_edge(psram_clk) or rising_edge(psram_cs_n);
                if psram_cs_n = '1' then
                    return;
                end if;
                if mode_qpi then -- QPI
                    shift_in_buf := shift_in_buf(7 - 4 downto 0) & psram_sio;
                else -- SPI
                    shift_in_buf := shift_in_buf(7 - 1 downto 0) & psram_sio(0); -- PSRAM SERIAL IN
                end if;
                bit_counter := bit_counter + bits_per_clk;
            end loop;
            -- info(logger,  "shift in loop ended CS=" & to_string(psram_cs_n) & " bit counter=" & to_string(bit_counter) & " byte=" & to_hstring(shift_in_buf);
            -- wait for 0 ns;
            cmd_buffer(byte_counter) := shift_in_buf;
            byte_counter             := byte_counter + 1;
        end procedure;

        -- Procedure to shift a byte OUT
        procedure psram_shift_byte_out is
        begin
            info(logger,  "start shifting out " & to_hstring(shift_out_buf));
            bit_counter := 0;
            while (bit_counter /= 8) loop
                wait until falling_edge(psram_clk) or rising_edge(psram_cs_n); -- this applies all signal assignments
                if psram_cs_n = '1' then
                    return;
                end if;
                if mode_qpi then -- QPI
                    psram_sio <= shift_out_buf(7 downto 4);
                    shift_out_buf := shift_out_buf(3 downto 0) & b"0000";
                else -- SPI
                    psram_sio(3 downto 2) <= "ZZ";
                    psram_sio(1)          <= shift_out_buf(7); -- PSRAM SERIAL OUT
                    psram_sio(0)          <= 'Z';
                    shift_out_buf := shift_out_buf(6 downto 0) & b"0";
                end if;
                bit_counter := bit_counter + bits_per_clk;
            end loop;
            -- info(logger,  "shift out loop ended CS=" & to_string(psram_cs_n) & " bit counter=" & to_string(bit_counter) & " byte=";
        end procedure;
        procedure psram_get_address is
        begin
            psram_shift_byte_in; -- 1 (MSB)
            if psram_cs_n = '1' then
                info(logger,  "PSRAM Terminated!");
                return;
            end if;
            psram_shift_byte_in; -- 2
            if psram_cs_n = '1' then
                info(logger,  "PSRAM Terminated!");
                return;
            end if;
            psram_shift_byte_in; -- 3 (LSB)
            if psram_cs_n = '1' then
                info(logger,  "PSRAM Terminated!");
                return;
            end if;

            psram_address := to_integer(unsigned(cmd_buffer(1)) & unsigned(cmd_buffer(2)) & unsigned(cmd_buffer(3)));
            info(logger,  "Start Address: " & integer'image(psram_address));
        end procedure;

        procedure psram_quad_write is
        begin
            psram_get_address;
            if psram_cs_n = '1' then
                info(logger,  "PSRAM Terminated!");
                return;
            end if;
            -- data
            while psram_cs_n = '0' loop
                debug(logger,  "START QUAD WRITE LOOP");
                byte_counter := 0; -- reuse
                psram_shift_byte_in;
                if psram_cs_n = '1' then
                    info(logger,  "PSRAM Terminated!");
                    return;
                end if;
                info(logger,  "Writing 0x" & to_hstring(cmd_buffer(0)) & " to " & integer'image(psram_address));
                -- MEM_BUFFER(psram_address) <= cmd_buffer(0);
                write_byte(memory, psram_address, to_integer(unsigned(cmd_buffer(0)))); -- use VUnit Memory Model
                psram_address := psram_address + 1;
                debug(logger,  "END QUAD WRITE LOOP");
            end loop;
        end procedure;

        procedure psram_fast_quad_read is
        begin
            psram_get_address;
            if psram_cs_n = '1' then
                info(logger,  "PSRAM Terminated!");
                return;
            end if;
            -- wait states
            psram_qpi_direction_input <= '1'; -- bus should be Hi-Z for wait states

            -- 6 wait cycles = 3 bytes
            info(logger,  "Read Wait Cycles Start");
            psram_shift_byte_out;
            psram_shift_byte_out;
            psram_shift_byte_out;
            info(logger,  "Read Wait Cycles Done");

            psram_qpi_direction_input <= '0'; -- switch to OUTPUT mode

            -- clock out data
            while psram_cs_n = '0' loop
                byte_counter := 0; -- reuse

                -- shift_out_buf := MEM_BUFFER(psram_address);
                shift_out_buf := std_logic_vector(to_unsigned(read_byte(memory, psram_address), 8)); -- use VUnit memory model
                info(logger,  "Fetched 0x" & to_hstring(shift_out_buf) & " from " & integer'image(psram_address));
                psram_shift_byte_out;
                if psram_cs_n = '1' then
                    info(logger,  "PSRAM Terminated!");
                    return;
                end if;
                psram_address := psram_address + 1;

            end loop;
        end procedure;

        -- Get and Parse PSRAM command
        procedure psram_process_cmd is
            constant CMD_FAST_QUAD_READ : std_logic_vector(7 downto 0) := x"EB";
            constant CMD_QUAD_WRITE     : std_logic_vector(7 downto 0) := x"38";
            constant CMD_ENTER_QUAD     : std_logic_vector(7 downto 0) := x"35";
            constant CMD_EXIT_QUAD      : std_logic_vector(7 downto 0) := x"F5";
        begin
            info(logger,  "PSRAM Start");

            psram_shift_byte_in;
            case cmd_buffer(0) is
                when CMD_FAST_QUAD_READ => info(logger,  "CMD_FAST_QUAD READ (0xEB)");
                    psram_fast_quad_read;
                when CMD_QUAD_WRITE => info(logger,  "CMD_QUAD WRITE (0x38)");
                    psram_quad_write;
                when CMD_ENTER_QUAD => info(logger,  "CMD_ENTER_QUAD (0x35)");-- should be SPI only
                    mode_qpi     <= '1';
                    bits_per_clk <= 4;
                when CMD_EXIT_QUAD => info(logger,  "CMD_EXIT_QUAD (0xF5)");-- should be QPI only
                    mode_qpi     <= '0';
                    bits_per_clk <= 1;
                when others => warning(logger,  "ERROR Unrecognised command 0x" & to_hstring(cmd_buffer(0)));
            end case;
            info(logger,  "PSRAM done, ready for next command");
        end procedure;

    begin ------------------- Actual Start of Process -------------------------
        psram_sio <= "ZZZZ";
        psram_loop : loop
            wait until falling_edge(psram_cs_n);
            psram_qpi_direction_input <= '1';
            cmd_buffer   := (others => (others => '0')); -- clear CMD buffer
            byte_counter := 0; -- reset byte counter

            psram_process_cmd;
            psram_sio <= "ZZZZ"; -- ready for next input command
        end loop psram_loop;

    end process;
end architecture;