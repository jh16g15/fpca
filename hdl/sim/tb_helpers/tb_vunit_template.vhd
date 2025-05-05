library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.joe_common_pkg.all;
use work.wb_pkg.all;
library vunit_lib;
context vunit_lib.vunit_context;

entity tb_vunit_template is
    generic (runner_cfg : string);
end entity tb_vunit_template;

architecture tb of tb_vunit_template is
    
begin

    stim : process is
    begin
        test_runner_setup(runner, runner_cfg);
        info("Vunit is alive!");
        show(get_logger(default_checker), display_handler, pass);
        check_equal(true, true, "True is True");

        test_runner_cleanup(runner);
        wait;
    end process stim;
    
end architecture tb;