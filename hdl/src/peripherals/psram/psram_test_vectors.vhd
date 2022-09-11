library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity psram_test_vectors is
generic(
	G_BURST_LEN : integer := 16
);
port(
	usrclk_in : in std_logic;
	rstn_in : in std_logic;

	start_in : in std_logic;	-- drive from "init_calib" output from IP
	-- PSRAM User channel
	wr_data_out : out std_logic_vector(31 downto 0);
	data_mask_out : out std_logic_vector(3 downto 0);
	rd_data_in	: in  std_logic_vector(31 downto 0);
	rd_data_valid_in : in std_logic;
	addr_out : out std_logic_vector(20 downto 0);	-- 21 bit address width (16-bit locations)
	cmd_out : out std_logic;
	cmd_en_out : out std_logic;
	-- status signals
	done_out : out std_logic;
	err_out : out std_logic_vector(3 downto 0)
);
end entity psram_test_vectors;

architecture rtl of psram_test_vectors is
	constant C_DATA_WORDS : integer := G_BURST_LEN / 4;
	constant C_MIN_COMMAND_INTERVAL : integer := G_BURST_LEN/4 + 11;
	type t_state is (RESET, WRITING, WAITING, READING, DONE);
	signal state : t_state := RESET;
	signal count : natural range 0 to 255 := 0;

	signal reg_rdata : std_logic_vector(31 downto 0);

	type t_mem is array (0 to C_DATA_WORDS-1) of std_logic_vector(31 downto 0);
	signal test_mem : t_mem := (
		x"0000_0000",
		x"1111_1111",
		x"2222_2222",
		x"3333_3333"
	);

begin

	data_mask_out <= (others => '0');	-- write all bytes
	addr_out <= std_logic_vector(to_unsigned(0, addr_out'length));	-- start burst at address 0

	process (usrclk_in) is
	begin
		if rising_edge(usrclk_in) then
			if rstn_in = '0' then
				state <= RESET;
				err_out <= (others => '0');
                done_out <= '0';
			else
				-- defaults
				cmd_en_out <= '0';
				count <= count + 1;

				case(state) is
                    when RESET =>
					err_out <= (others => '0');
                    done_out <= '0';
					count <= 0;
					if start_in = '1' then
						state <= WRITING;
						count <= 1;
						-- first write data
						cmd_en_out <= '1';
						cmd_out <= '1';	-- write enable
						wr_data_out <= test_mem(0);
					end if;
				when WRITING =>
					wr_data_out <= test_mem(count);
					if count = 3 then
						state <= WAITING;
					end if;
				when WAITING =>
					if count = C_MIN_COMMAND_INTERVAL then	-- send read command
						cmd_en_out <= '1';
						cmd_out <= '0';
					end if;
					if rd_data_valid_in = '1' then
						state <= READING;
						reg_rdata <= rd_data_in;	-- save for comparison
						count <= 0;
					end if;


				when READING =>
					reg_rdata <= rd_data_in;
					if reg_rdata /= test_mem(count) then
						err_out(count) <= '1';
					end if;
					if count = C_DATA_WORDS - 1 then
						done_out <= '1';
						state <= DONE;
					end if;

				when DONE => null;

				when others => state <= RESET;
				end case;


			end if;
		end if;
	end process;
end architecture rtl;


