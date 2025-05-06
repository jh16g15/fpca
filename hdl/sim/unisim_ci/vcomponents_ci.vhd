library ieee;
use ieee.std_logic_1164.all;

package vcomponents is
    component IOBUF
        generic (
           DRIVE : integer := 12;
           IBUF_LOW_PWR : boolean := TRUE;
           IOSTANDARD : string := "DEFAULT";
           SLEW : string := "SLOW"
        );
        port (
           O : out std_ulogic;
           IO : inout std_ulogic;
           I : in std_ulogic;
           T : in std_ulogic
        );
      end component;

      component ODDR
        generic (
           DDR_CLK_EDGE : string := "OPPOSITE_EDGE";
           INIT : bit := '0';
           IS_C_INVERTED : bit := '0';
           IS_D1_INVERTED : bit := '0';
           IS_D2_INVERTED : bit := '0';
           SRTYPE : string := "SYNC"
        );
        port (
           Q : out std_ulogic;
           C : in std_ulogic;
           CE : in std_ulogic;
           D1 : in std_ulogic;
           D2 : in std_ulogic;
           R : in std_ulogic := 'L';
           S : in std_ulogic := 'L'
        );
      end component;
end package vcomponents;
