library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! A (hopefully!) simple simulation model of a single channel of the
--! GOWIN PSRAM controller IP.
--! NOTE: This is _not_ a cycle-accurate simulation, and is just intended for basic functional
--! simulation of code intended to be connected up to the PSRAM controller IP
entity sim_psram is
    generic (
        G_BURST_LEN : integer := 16;
        G_MEMCLK_PERIOD : time := 10 ns;
        G_DATA_W : integer := 32;
        G_PSRAM_ADDR_W : integer := 21;   -- PSRAM is 2^21 16-bit words
        G_PSRAM_DATA_W : integer := 16; -- fixed
        G_MEM_DEPTH : integer := 1024;   -- for simulating with a smaller memory to reduce sim time
        C_INIT_DELAY : integer := 15;
        C_READ_DELAY : integer := 10
    );
    port (
		-- clk: in std_logic;
		-- memory_clk: in std_logic;
		-- pll_lock: in std_logic;
		rst_n: in std_logic;

		wr_data: in std_logic_vector(G_DATA_W-1 downto 0);
		rd_data: out std_logic_vector(G_DATA_W-1 downto 0);
		rd_data_valid: out std_logic;
		addr: in std_logic_vector(G_PSRAM_ADDR_W-1 downto 0);
		cmd: in std_logic;
		cmd_en: in std_logic;
		init_calib: out std_logic;
		clk_out: out std_logic;     --! output clock 1/2 memclk
		data_mask: in std_logic_vector(G_DATA_W/8-1 downto 0)
	);
end entity sim_psram;

architecture rtl of sim_psram is
    constant C_MIN_COMMAND_INTERVAL : integer := G_BURST_LEN/4 + 11;
    constant C_DATA_CYCLES : integer := G_BURST_LEN/4;
    constant C_PSRAM_WORDS_PER_USER_WORD : integer := G_DATA_W / G_PSRAM_DATA_W;
    signal clk : std_logic := '0';

    type t_state is (INIT, IDLE, WRITING, WAIT_FOR_RVALID, READING);
    signal state : t_state := INIT;

    signal cycle_counter : integer := 0;

    signal reg_wdata : std_logic_vector(G_DATA_W-1 downto 0);
    signal reg_mask : std_logic_vector(G_DATA_W/8-1 downto 0);

    type t_mem is array (0 to G_MEM_DEPTH-1) of std_logic_vector(G_PSRAM_DATA_W-1 downto 0);
    signal mem : t_mem;
    signal base_addr : integer := 0;
    signal addr_offset : integer := 0;

begin

    clk <= not clk after G_MEMCLK_PERIOD; -- memclk / 2
    clk_out <= clk;

    process (clk) is
        variable psram_word_offset : integer := 0;
        variable i2 : integer := 0;
    begin
        if rising_edge(clk) then
            if rst_n = '0' then
                state <= INIT;
                cycle_counter <= 0;
                init_calib <= '0';
                rd_data_valid <= '0';
            else
                cycle_counter <= cycle_counter + 1;
                reg_wdata <= wr_data;
                reg_mask <= data_mask;
                case state is
                    when INIT =>

                        if cycle_counter = C_INIT_DELAY then
                            state <= IDLE;
                            init_calib <= '1';
                        end if;

                    when IDLE =>

                        if cmd_en = '1' then
                            cycle_counter <= 0;
                            base_addr <= to_integer(unsigned(addr));
                            addr_offset <= 0;
                            if cmd = '1' then   -- we are registering wdata and the mask here
                                state <= WRITING;
                            else
                                state <= WAIT_FOR_RVALID;
                            end if;

                        end if;

                    when WRITING =>

                        report("Write Cycle " & to_string(cycle_counter));
                        if cycle_counter = C_DATA_CYCLES-1 then
                            report("Write complete, moving back to IDLE");
                            state <= IDLE;
                        end if;
                        addr_offset <= addr_offset + C_PSRAM_WORDS_PER_USER_WORD;    -- add number of 16-bit words written to address
                        -- behavioural loop to write all the data from the input wdata port
                        -- into 16 bit words
                        for i in 0 to G_DATA_W/8 - 1 loop   -- masked bytewise writes for the whole user write port width

                            -- address calculation while writing one "user word"
                            --eg 32bit user word, 16bit PSRAM width

                            -- LSByte 0 written to address 0 (7:0)
                            -- Byte 1 written to address 0 (15:8)
                            -- Byte 2 written to address 1 (7:0)
                            -- MSByte 3 written to address 1 (15:8)

                            -- eg 64bit user word, 16bit PSRAM width
                            -- LSByte 0 written to address 0 (7:0)
                            -- Byte 1 written to address 0 (15:8)
                            -- Byte 2 written to address 1 (7:0)
                            -- Byte 3 written to address 1 (15:8)
                            -- Byte 4 written to address 2 (7:0)
                            -- Byte 5 written to address 2 (15:8)
                            -- Byte 6 written to address 3 (7:0)
                            -- MSByte 7 written to address 3 (15:8)
                            psram_word_offset := i / C_PSRAM_WORDS_PER_USER_WORD;

                            -- byte index into PSRAM word
                            i2 := i mod C_PSRAM_WORDS_PER_USER_WORD;

                            if reg_mask(i) = '0' then   -- if MASK = 0, we write
                                mem(base_addr + addr_offset + psram_word_offset)(8 * (i2 + 1) - 1 downto 8 * i2) <= reg_wdata(8 * (i + 1) - 1 downto 8 * i);
                            end if;
                        end loop;


                    when WAIT_FOR_RVALID =>

                        if cycle_counter = C_READ_DELAY then
                            state <= READING;
                            cycle_counter <= 0;
                        end if;

                        when READING =>

                        rd_data_valid <= '1';
                        addr_offset <= addr_offset + C_PSRAM_WORDS_PER_USER_WORD; -- add number of 16-bit words read
                        -- loop through the PSRAM words until we have assembled a "user word"
                        for j in 0 to C_PSRAM_WORDS_PER_USER_WORD -1 loop
                            rd_data(G_PSRAM_DATA_W * (j + 1) - 1 downto G_PSRAM_DATA_W * j) <= mem(base_addr + addr_offset + j);
                        end loop;

                        if cycle_counter = C_DATA_CYCLES then
                            state <= IDLE;
                            rd_data_valid <= '0';
                        end if;

                    when others =>
                        null;
                end case;

            end if;
        end if;
    end process;


end architecture;
