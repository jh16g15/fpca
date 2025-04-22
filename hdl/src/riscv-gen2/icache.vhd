library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;
--
entity icache is
    generic(
        G_DBG_LOG    : boolean := false;
        -- G_RV32C_OPT  : boolean := true; -- optimisation: 
        G_NUM_BLOCKS : integer := 16;
        G_BLOCK_SIZE : integer := 32; -- bytes
        G_SET_SIZE : integer := 1   -- blocks per set: 1 for direct-mapped
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        in_addr : in std_logic_vector(31 downto 0); -- bottom bit must be 0, 2-byte aligned
        in_addr_valid : std_logic;

        out_instr : out std_logic_vector(31 downto 0); -- could be a 16-bit compressed instr
        out_instr_valid : out std_logic;

        -- force_fetch : in std_logic := '0';
        in_invalidate : in std_logic_vector(G_NUM_BLOCKS-1 downto 0) := (others => '0');
        -- flush : in std_logic := '0'; -- can't write to icache

        -- wishbone B4 pipelined for cache line fill/flush
        wb_mosi : out t_wb_mosi;
        wb_miso : in t_wb_miso

    );
end entity icache;

architecture RTL of icache is

    constant C_NUM_SETS : integer := G_NUM_BLOCKS / G_SET_SIZE; -- number of "ways" that our cache is associative
    constant C_SET_I_WIDTH : integer := clog2(G_SET_SIZE); -- number of bits needed to store an index into the set

    -- Tag  : Upper bits of address
    -- Index: which cache set we can go in
    -- Block Offset: which pair of 16-bit values are we requesting (each 32-byte cache line has 16 16-bit slots)
        -- NOTE: we will need to consider edge case of spilling over into a second cache line

    -- Address to iCache block decoding
    -- bit 0 will always be 0 (2 byte aligned)
    -- bits 4:1 (4 bits) tell us the offset to the lower 16-bits of our pair
    
    -- for 16 cache lines, 2 lines per set, 8 sets

    -- bits 7:5 (3 bits) tell us which set it can belong to (index)
    -- bits 31:8 (24 bits) is our tag

    constant C_WORD_OFFSET_W : integer := clog2(G_BLOCK_SIZE)-1; -- minus 1 as 2-byte aligned (eg 4 bits for 32-byte cache blocks)
    constant C_INDEX_W : integer := clog2(C_NUM_SETS);
    constant C_TAG_W : integer := 32 - C_INDEX_W - C_WORD_OFFSET_W - 1;
    
    constant C_WORD_OFFSET_L : integer := 1;
    constant C_WORD_OFFSET_H : integer := C_WORD_OFFSET_W-1 + C_WORD_OFFSET_L;
    constant C_WORD_OFFSET_MAX : std_logic_vector(C_WORD_OFFSET_W-1 downto 0) := (others => '1');
    
    
    constant C_INDEX_L : integer := C_WORD_OFFSET_H+1;
    constant C_INDEX_H : integer := C_INDEX_W-1 + C_INDEX_L;
    
    constant C_TAG_L : integer := C_INDEX_H+1;
    constant C_TAG_H : integer := C_TAG_W-1 + C_TAG_L;

    type t_cache_data is array (G_NUM_BLOCKS-1 downto 0) of std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);
    -- type t_cache_index is array (G_NUM_BLOCKS-1 downto 0) of std_logic_vector(C_INDEX_W-1 downto 0);
    type t_cache_tag is array (G_NUM_BLOCKS-1 downto 0) of std_logic_vector(C_TAG_W-1 downto 0);
    
    -- Valid/LRU is per cache line, compared across the set
    -- type t_cache_set_attr is array (G_NUM_BLOCKS-1 downto 0) of std_logic;

    signal cache_block_data : t_cache_data;
    -- signal cache_block_index : t_cache_index;
    signal cache_block_tag : t_cache_tag;
    signal cache_block_valid : std_logic_vector(G_NUM_BLOCKS-1 downto 0) := (others => '0');
    -- signal cache_block_lru : std_logic_vector(G_NUM_BLOCKS-1 downto 0) := (others => '0');

    signal hit_count : unsigned(63 downto 0) := (others => '0'); -- found in cache
    signal oflow_count : unsigned(63 downto 0) := (others => '0'); -- found over 2 cache lines
    signal miss_count : unsigned(63 downto 0) := (others => '0'); -- not found in cache


    

    signal data0 : std_logic_vector(15 downto 0); -- lower 16 bits of a 32-bit fetch
    signal data1 : std_logic_vector(15 downto 0); -- upper 16 bits of a 32-bit fetch

    signal may_cross_cache_line : std_logic;
    signal second_word_oflow_replace : std_logic := '0'; -- upper half of 32b instruction crosses cache line

    type t_state is (READY, OFLOW, MISS, REPLACE);
    signal state : t_state := READY;

    signal upper_addr : std_logic_vector(31 downto 0);

    constant C_WB_XFERS : integer := G_BLOCK_SIZE / 4;
    signal wb_cmds_to_go : integer range 0 to C_WB_XFERS;
    signal wb_rsps_to_go : integer range 0 to C_WB_XFERS;
    signal wb_next_addr   : std_logic_vector(31 downto 0);

    signal fetched_cache_block : std_logic_vector(G_BLOCK_SIZE*8-1 downto 0);

    -- for random replacement, XOR lfsr1 and lfsr2 for better random distribution
    signal lfsr : std_logic_vector(C_SET_I_WIDTH-1 downto 0) := (others => '0'); 
    signal lfsr1 : std_logic_vector(9 downto 0) := (others => '0'); -- 10 bit, XNOR taps at 10th and 7th bits
    signal lfsr2 : std_logic_vector(10 downto 0) := (others => '0'); -- 9 bit, XNOR taps at 7th and 5th bits


    procedure dbg_msg(str : string) is
    begin
        msg("Cache: " & str, G_DBG_LOG);
    end procedure;

begin
    
    p_lfsr : process(clk) is
    begin
        if rising_edge(clk) then
            -- lfsr <= lfsr(5 downto 0) & (lfsr(6) xnor lfsr(5));
            lfsr1 <= lfsr1(8 downto 0) & (lfsr1(9) xnor lfsr1(6));
            lfsr2 <= lfsr2(9 downto 0) & (lfsr2(10) xnor lfsr2(4));
        end if;
    end process;
    lfsr <= lfsr1(C_SET_I_WIDTH-1 downto 0) xor lfsr2(C_SET_I_WIDTH-1 downto 0);
 
    -- if our address starts at the final 16b word of cache line, upper 16b must be fetched from next cache line (if needed)
    may_cross_cache_line <= '1' when in_addr(C_WORD_OFFSET_H downto C_WORD_OFFSET_L) = C_WORD_OFFSET_MAX else '0';

    out_instr(31 downto 16) <= data1;
    out_instr(15 downto  0) <= data0;

    wb_mosi.sel <= x"f";
    wb_mosi.we <= '0';

    name : process (clk) is
        -- lower/full search
        variable v_tag : std_logic_vector(C_TAG_W-1 downto 0);
        variable v_index : integer;
        variable v_word_offset : integer;
        variable v_tag_match : boolean;
        variable v_matched_block : integer;
        -- upper search
        -- variable v_tag_u : std_logic_vector(C_TAG_W-1 downto 0);
        -- variable v_index_u : integer;
        -- variable v_word_offset_u : integer;
        -- variable v_tag_match_u : boolean;
        -- variable v_matched_block_u : integer;

        -- cache block replacement
        variable v_set_base : integer;  -- base block addr of the set our req addr is in
        variable v_replace_block_addr : integer;
        variable v_empty_block_found : boolean;
        variable v_random_block_in_set : integer;
        
        -- variable v_data0 : std_logic_vector(15 downto 0);

        procedure decode_addr(
            addr : in std_logic_vector(31 downto 0);
            tag : out std_logic_vector(C_TAG_W-1 downto 0);
            index : out integer;
            word_offset : out integer
        ) is
        begin
            tag := addr(C_TAG_H downto C_TAG_L);
            index := slv2uint(addr(C_INDEX_H downto C_INDEX_L));
            word_offset := slv2uint(addr(C_WORD_OFFSET_H downto C_WORD_OFFSET_L));
            dbg_msg("Decoded address " & to_hstring(addr) & " tag " & to_hstring(tag) & " index " & to_string(index) & " offset " & to_string(word_offset));
        end procedure decode_addr;
        

        procedure combinational_cache_lookup(
            addr : in std_logic_vector(31 downto 0);
            hit  : out boolean;
            hit_block_id : out integer
        ) is 
            variable lv_tag : std_logic_vector(C_TAG_W-1 downto 0);
            variable lv_index : integer;
            variable lv_set_base : integer;
            variable lv_word_offset : integer;
            variable lv_tag_match : boolean;
            variable lv_matched_block : integer;
        begin
            decode_addr(addr, lv_tag, lv_index, lv_word_offset);
            
            -- check each block in the set for a (valid) tag match, save which cache block has the match
            lv_tag_match := false;
            v_set_base := v_index * G_SET_SIZE; -- cache set of addr * size of each set
            for i in v_set_base to v_set_base+G_SET_SIZE-1 loop
                dbg_msg("check block " & to_string(i));
                if lv_tag = cache_block_tag(i) and cache_block_valid(i) = '1' then
                    lv_tag_match := true;
                    lv_matched_block := i;
                end if;
            end loop;
            hit := lv_tag_match;
            hit_block_id := lv_matched_block;
        end procedure;

        function get_cache_block_base_addr(addr : in std_logic_vector(31 downto 0)) return std_logic_vector is
            constant C_OFFSET_PAD : std_logic_vector(C_WORD_OFFSET_W-1+1 downto 0) := (others => '0');
        begin 
            return addr(C_TAG_H downto C_INDEX_L) & C_OFFSET_PAD;
        end function;
        
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= READY;
                cache_block_valid <= (others => '0');
                second_word_oflow_replace <= '0';
                hit_count <= (others => '0');
                miss_count <= (others => '0');
                wb_mosi.adr <= C_WB_MOSI_INIT.adr;
                wb_mosi.cyc <= C_WB_MOSI_INIT.cyc;
                wb_mosi.stb <= C_WB_MOSI_INIT.stb;
                wb_mosi.lock <= C_WB_MOSI_INIT.lock;
                out_instr_valid <= '0';
            else
                out_instr_valid <= '0'; -- default
                case(state) is
                when READY => 
                    if in_addr_valid then
                        
                        upper_addr <= uint2slv(slv2uint(in_addr) + 2); -- register corresponding address of upper 16 bits

                        decode_addr(in_addr, v_tag, v_index, v_word_offset);
                        combinational_cache_lookup(in_addr, v_tag_match, v_matched_block);

                        if v_tag_match then

                            -- lower 16b is always in this fetched cache block
                            dbg_msg("data0 is from block " & to_string(v_matched_block) & " bits " & to_string(v_word_offset*16+15) & " downto " & to_string(v_word_offset*16));
                            data0 <= cache_block_data(v_matched_block)(v_word_offset*16+15 downto v_word_offset*16);
                            if may_cross_cache_line = '1' then -- if may cross cache line
                                dbg_msg("Cache partial hit, overflow into next block");
                                state <= OFLOW;
                            else -- upper 16 bits is in the same cache block, CACHE HIT
                                dbg_msg("Cache hit in block " & to_string(v_matched_block));
                                hit_count <= hit_count + 1;
                                dbg_msg("data1 is from block " & to_string(v_matched_block) & " bits " & to_string((v_word_offset+1)*16+15) & " downto " & to_string((v_word_offset+1)*16));
                                data1 <= cache_block_data(v_matched_block)((v_word_offset+1)*16+15 downto (v_word_offset+1)*16);
                                out_instr_valid <= '1';
                            end if;
                            -- out_instr <= cache_block_data(v_matched_block);
                        else
                            dbg_msg("Cache miss");
                            state <= MISS;
                            miss_count <= miss_count + 1;
                            -- set up WB DMA to load cache line
                            wb_cmds_to_go <= C_WB_XFERS;
                            wb_rsps_to_go <= C_WB_XFERS;
                            wb_mosi.cyc <= '1';
                            wb_mosi.stb <= '1';
                            wb_mosi.adr <= get_cache_block_base_addr(in_addr);
                            wb_next_addr <= u_add(get_cache_block_base_addr(in_addr), x"0000_0004");
                        end if;
                    end if;
                when OFLOW =>
                    -- NOTE: RISC-V Compressed (16b) instructions start with "00", "01" or "10"
                    --       RISC-V 32b Instructions start with "11"
                    -- check if 32b RISC-V instruction (ie do we need the upper 16 bits at all?)
                    if false then 
                    -- if data0(1 downto 0) /= "11" then 
                        -- 16 bit instruction, can conclude here
                        dbg_msg("RISC-V 16b compressed instruction detected, no need for upper bits");
                        hit_count <= hit_count + 1;
                        out_instr_valid <= '1'; -- can this be done combinationally for reduced latency?
                        state <= READY;
                    else
                        -- check next cache line for upper 16 bits
                        decode_addr(upper_addr, v_tag, v_index, v_word_offset);
                        combinational_cache_lookup(upper_addr, v_tag_match, v_matched_block);
                        if v_tag_match then
                            dbg_msg("Cache hit for overflowed upper half in block " & to_string(v_matched_block) & " bits " & to_string(v_word_offset*16+15) & " downto " & to_string(v_word_offset*16));
                            oflow_count <= oflow_count + 1;
                            state <= READY;
                            data1 <= cache_block_data(v_matched_block)(v_word_offset*16+15 downto v_word_offset*16);
                            out_instr_valid <= '1';
                        else
                            dbg_msg("Cache miss for overflowed upper half");
                            second_word_oflow_replace <= '1'; -- set flag so we load data1 when cache block replaced 
                            state <= MISS;
                            miss_count <= miss_count + 1;
                            -- set up WB DMA to load cache line
                            wb_cmds_to_go <= C_WB_XFERS;
                            wb_rsps_to_go <= C_WB_XFERS;
                            wb_mosi.cyc <= '1';
                            wb_mosi.stb <= '1';
                            wb_mosi.adr <= get_cache_block_base_addr(upper_addr);
                            wb_next_addr <= u_add(get_cache_block_base_addr(upper_addr), x"0000_0004");
                        end if;
                    end if;
                when MISS =>
                    -- wishbone master, does burst of C_WB_XFERS to load cache line
                    if wb_miso.stall = '0' then
                        wb_cmds_to_go <= wb_cmds_to_go-1;
                        wb_mosi.adr <= wb_next_addr;
                        wb_next_addr <= u_add(wb_next_addr, x"0000_0004");
                        if wb_cmds_to_go = 1 then   -- this cycle is final command sending arriving
                            wb_mosi.stb <= '0';
                        end if;
                    end if;

                    if wb_miso.ack = '1' then
                        -- shift in 4-bytes from wishbone bus
                        wb_rsps_to_go <= wb_rsps_to_go-1;
                        -- shift in from the top [255:] each word, so the first word is [:0]
                        -- fetched_cache_block <= fetched_cache_block(G_BLOCK_SIZE*8-C_WB_DATA_W-1 downto 0) & wb_miso.rdat; -- shift from bottom to top
                        fetched_cache_block <= wb_miso.rdat & fetched_cache_block(G_BLOCK_SIZE*8-1 downto C_WB_DATA_W); -- shift from top to bottom
                        if wb_rsps_to_go = 1 then   -- this cycle is final response arriving
                            wb_mosi.cyc <= '0'; -- mark end of burst
                            state <= REPLACE; 
                        end if;
                    end if;
                when REPLACE => 
                    -- Replace Cache Line
                    -- HOW TO CHOOSE CACHE BLOCK FOR REPLACEMENT 
                    -- 1. Select which cache index our address is in
                    -- 2. If set is not full, Select a random block in that set to replace, mark as valid
                    v_empty_block_found := false;
                    v_set_base := v_index * G_SET_SIZE; -- cache set of addr * size of each set
                    --look for empty block
                    for i in v_set_base to v_set_base + G_SET_SIZE - 1 loop
                        if cache_block_valid(i) = '0' then -- empty
                            dbg_msg("found empty block");
                            v_empty_block_found := true;
                            v_replace_block_addr := i;
                            exit;
                        end if;
                    end loop;
                    if not v_empty_block_found then
                        if G_SET_SIZE = 1 then -- direct mapped
                            v_random_block_in_set := 0;    
                        else    -- set-associative
                            v_random_block_in_set := slv2uint(lfsr);
                        end if;
                        v_replace_block_addr := v_set_base + v_random_block_in_set;
                        dbg_msg("lfsr selected block " & to_string(v_random_block_in_set) & " for replacement");
                    end if;
                    dbg_msg("Replaced block " & to_string(v_replace_block_addr));
                    cache_block_data(v_replace_block_addr) <= fetched_cache_block;
                    cache_block_tag(v_replace_block_addr)  <= v_tag;
                    cache_block_valid(v_replace_block_addr) <= '1';


                    -- output data valid from block retrieved from memory
                    if second_word_oflow_replace = '0' then -- normal operation
                        -- lower 16b is always in this fetched cache block
                        data0 <= fetched_cache_block(v_word_offset*16+15 downto v_word_offset*16);
                        if may_cross_cache_line = '1' then -- if may cross cache line (if 32b), check next cache block
                            dbg_msg("Second half is in another cache block");
                            state <= OFLOW;
                        else -- upper 16 bits is in the same cache block
                            data1 <= fetched_cache_block((v_word_offset+1)*16+15 downto (v_word_offset+1)*16);
                            out_instr_valid <= '1';
                            state  <= READY;
                        end if;
                    else -- this cache block replace was triggered by overflow into the next (just replaced) cache block 
                        second_word_oflow_replace <= '0'; -- clear flag
                        data1 <= fetched_cache_block(v_word_offset*16+15 downto v_word_offset*16); -- data1 instead of data0
                        out_instr_valid <= '1';
                        state  <= READY;
                    end if;
                end case;
            end if;
            -- clear cache blocks if invalidate bits are set
            for i in G_NUM_BLOCKS-1 downto 0 loop
                if in_invalidate(i) = '1' then
                    cache_block_valid(i) <= '0';
                end if;
            end loop;
            
        end if;
    end process name;
    


end architecture RTL;
