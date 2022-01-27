library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wb_pkg.all;
use work.joe_common_pkg.all;

-- TODO: make all registers byte-accessible
entity wb_timer is
    generic (
        G_NUM_TIMERS : integer := 1 -- only one supported for now
    );
    port (
        wb_clk   : in std_logic;
        wb_reset : in std_logic;

        wb_mosi_in  : in t_wb_mosi;
        wb_miso_out : out t_wb_miso;

        pwm_out             : out std_logic;
        timer_interrupt_out : out std_logic_vector(G_NUM_TIMERS - 1 downto 0)
    );
end entity wb_timer;

architecture rtl of wb_timer is
    -- Register Map per timer
    -- x0: Current Value of time_reg (32b)
    -- R/W
    -- x4: Timer Control and Status register
    -- [0]      Timer Start/Stop
    -- [1]      Enable Overflow Interrupt
    -- [2]      Enable PWM mode
    -- [8]     Clear timer overflow
    -- [16]     Timer Overflow
    -- x8: Timer Threshold Register (32b)
    -- xC: PWM Threshold Register (32b)
    constant G_TIMER_W : integer := 32;

    signal new_count_value_in       : std_logic_vector(G_TIMER_W - 1 downto 0); -- Reg x0 (On Write)
    signal new_count_value_valid_in : std_logic;
    signal count_value_out          : std_logic_vector(G_TIMER_W - 1 downto 0); -- Reg x0 (On Read)
    signal count_top_threshold_in   : std_logic_vector(G_TIMER_W - 1 downto 0); -- Reg x8 (On Read/Write)
    signal top_thresh_valid_in      : std_logic;
    signal pwm_threshold_in         : std_logic_vector(G_TIMER_W - 1 downto 0); -- Reg xC (On Read/Write)
    signal pwm_thresh_valid_in      : std_logic;

    signal count_enable     : std_logic; -- Reg x4 bit 0  RW
    signal interrupt_enable : std_logic; -- Reg x4 bit 1  RW
    signal pwm_mode_enable  : std_logic; -- Reg x4 bit 2  RW
    signal clr_oflow_flag   : std_logic; -- Reg x4 bit 8  WO
    signal oflow_flag       : std_logic; -- Reg x4 bit 16 RO

begin

    timer_interrupt_out(0) <= oflow_flag and interrupt_enable;

    -- this slave can always respond to requests, so no stalling is required
    wb_miso_out.stall <= '0';
    -- wishbone slave logic
    wb_proc : process (wb_clk) is
    begin
        if rising_edge(wb_clk) then
            if wb_reset = '1' then
                wb_miso_out.ack <= '0';
                wb_miso_out.err <= '0';
                wb_miso_out.rty <= '0';

                -- reset writeable registers
                count_enable     <= '0';
                interrupt_enable <= '0';
                pwm_mode_enable  <= '0';
                count_enable     <= '0';
            else
                -- defaults
                wb_miso_out.ack  <= '0';
                wb_miso_out.err  <= '0'; -- this slave does not generate ERR or RTY responses
                wb_miso_out.rty  <= '0';
                wb_miso_out.rdat <= x"DEADC0DE";

                -- default valids
                new_count_value_valid_in <= '0';
                top_thresh_valid_in      <= '0';
                pwm_thresh_valid_in      <= '0';
                clr_oflow_flag           <= '0';

                if wb_mosi_in.stb = '1' and wb_miso_out.stall = '0' then -- assume CYC asserted by master for STB to be high
                    -- always ACK this cycle (sync operation with 1 wait state)
                    wb_miso_out.ack <= '1';
                    if wb_mosi_in.we = '1' then
                        -- write logic
                        case(wb_mosi_in.adr(3 downto 0)) is
                            when x"0" => -- Count Register
                            new_count_value_in       <= wb_mosi_in.wdat(G_TIMER_W - 1 downto 0);
                            new_count_value_valid_in <= '1';
                            when x"4" => -- Control and Status register
                            count_enable     <= wb_mosi_in.wdat(0);
                            interrupt_enable <= wb_mosi_in.wdat(1);
                            pwm_mode_enable  <= wb_mosi_in.wdat(2);
                            clr_oflow_flag   <= wb_mosi_in.wdat(8);

                            when x"8" => -- Top Threshold
                            count_top_threshold_in <= wb_mosi_in.wdat(G_TIMER_W - 1 downto 0);
                            top_thresh_valid_in    <= '1';
                            when x"C" => -- PWM Threshold
                            pwm_threshold_in    <= wb_mosi_in.wdat(G_TIMER_W - 1 downto 0);
                            pwm_thresh_valid_in <= '1';
                            when others => null;
                        end case;
                    else
                        -- read logic
                        case(wb_mosi_in.adr(3 downto 0)) is
                            when x"0" => wb_miso_out.rdat <= count_value_out;
                            when x"4" =>

                            wb_miso_out.rdat     <= (others => '0'); -- default, overwrite with below ctl/status bits
                            wb_miso_out.rdat(0)  <= count_enable;
                            wb_miso_out.rdat(1)  <= interrupt_enable;
                            wb_miso_out.rdat(2)  <= pwm_mode_enable;
                            wb_miso_out.rdat(16) <= oflow_flag;

                            when x"8"   => wb_miso_out.rdat <= count_top_threshold_in;
                            when x"C"   => wb_miso_out.rdat <= pwm_threshold_in;
                            when others => null;
                        end case;

                    end if;
                end if;

            end if; -- end clk'd
        end if;
    end process;
    timer_inst : entity work.timer
        generic map(
            G_TIMER_W     => 32,
            G_PWM_SUPPORT => true
        )
        port map(
            clk                      => wb_clk,
            reset                    => wb_reset,
            new_count_value_in       => new_count_value_in,
            new_count_value_valid_in => new_count_value_valid_in,
            count_enable_in          => count_enable,
            count_value_out          => count_value_out,
            pwm_threshold_in         => pwm_threshold_in,
            pwm_thresh_valid_in      => pwm_thresh_valid_in,
            count_top_threshold_in   => count_top_threshold_in,
            top_thresh_valid_in      => top_thresh_valid_in,
            pwm_mode_enable_in       => pwm_mode_enable,
            pwm_out                  => pwm_out,
            clr_oflow_flag_in        => clr_oflow_flag,
            oflow_flag_out           => oflow_flag
        );
end architecture;