library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;

-- 32b counter @ 50 MHz is up to about 85 seconds of counting

-- STANDARD MODE:
-- 1. Set up increment/decrement mode
-- 2. Set the initial value
-- 3. Enable the counter

-- INTERRUPT/OVERFLOW MODE: (not currently supported)
-- 1. Set a "top threshold"
-- 2. Set to "increment mode"
-- 3. Set the initial value (0)
-- 4. Enable the counter
-- 5. When the counter reaches "top threshold", oflow_out = '1' and counter returns to 0
-- 6. oflow_out flag remains '1' until cleared

-- PWM MODE: (not currently supported)
-- 1. Set a "pwm threshold" and a "top threshold"
-- 2. Set counter to 0
-- 3. Counter increments to "pwm threshold"
-- 4. PWM_OUT = '1'
-- 5. Counter reaches "counter top threshold"
-- 6. Counter decrements to "pwm threshold"
-- 7. PWM_OUT = '0' etc...

entity timer is
    generic (
        G_TIMER_W           : integer := 32;
        G_PWM_SUPPORT       : boolean := false;
        G_INTERRUPT_SUPPORT : boolean := false
    );
    port (
        clk   : in std_logic;
        reset : in std_logic;

        new_count_value_in       : in std_logic_vector(G_TIMER_W - 1 downto 0);
        new_count_value_valid_in : in std_logic;

        count_enable_in : in std_logic;
        count_value_out : out std_logic_vector(G_TIMER_W - 1 downto 0);

        -- PWM and Interrupts (optional features)
        pwm_threshold_in       : in std_logic_vector(G_TIMER_W - 1 downto 0);
        pwm_thresh_valid_in    : in std_logic;
        count_top_threshold_in : in std_logic_vector(G_TIMER_W - 1 downto 0);
        top_thresh_valid_in    : in std_logic;

        pwm_mode_enable_in : in std_logic;
        pwm_out            : out std_logic;

        clr_oflow_flag_in : in std_logic;
        oflow_flag_out    : out std_logic
    );
end entity timer;

architecture rtl of timer is
    signal count_value : unsigned (G_TIMER_W - 1 downto 0) := (others => '0'); -- counter
    signal pwm_value   : unsigned (G_TIMER_W - 1 downto 0) := (others => '1'); -- threshold for PWM
    signal top_value   : unsigned (G_TIMER_W - 1 downto 0) := (others => '1'); -- threshold for return-to-0
    -- UP = 1, DOWN = 0

    type t_count_dir is (UP, DOWN);

    signal count_direction : t_count_dir;
    signal pwm_direction   : t_count_dir;
    signal pwm_i           : std_logic := '0';
begin

    count_value_out <= std_logic_vector(count_value);

    dir_proc : process (all) is
    begin
        if G_PWM_SUPPORT = true then
            -- handle PWM output
            if (count_value >= pwm_value) and pwm_mode_enable_in = '1' then
                pwm_i <= '1';
            else
                pwm_i <= '0';
            end if;
            -- handle counting direction
            count_direction <= pwm_direction when pwm_mode_enable_in = '1' else UP;

        else
            count_direction <= UP;
            pwm_i         <= '0';
        end if;
    end process;

    count_proc : process (clk) is
    begin
        if rising_edge(clk) then
            -- for interrupts and PWM
            if pwm_thresh_valid_in = '1' then
                pwm_value <= pwm_threshold_in;
            end if;
            if top_thresh_valid_in = '1' then
                top_value <= count_top_threshold_in;
            end if;
            if clr_oflow_flag_in = '1' then
                oflow_flag_out <= '0';
            end if;

            pwm_out <= pwm_i; -- register our PWM output

            -- Main counting loop
            if new_count_value_valid_in = '1' then
                count_value <= new_count_value_in;
            else
                if count_enable_in = '1' then
                    -- count_direction controlled by pwm_mode
                    if count_direction = UP then
                        count_value <= count_value + 1;
                    else
                        count_value <= count_value - 1;
                    end if;

                    -- overflow - reset counter (unless PWM)
                    if count_value >= top_value then
                        if pwm_mode_enable_in = '0' then
                            count_value    <= 0;
                            oflow_flag_out <= '1'; -- reset with clr_oflow_flag_in
                        else
                            pwm_direction <= DOWN; -- count down
                        end if;

                    end if;

                    if count_value = 0 then
                        pwm_direction <= UP; -- count up
                    end if;
                end if;
            end if;

            if reset = '1' then
                count_value <= (others => '0');
                pwm_value <= (others => '1');
                top_value <= (others => '1');
                oflow_flag_out <= '0';
                pwm_out <= '0';
            end if;
        end if;
    end process;
end architecture;