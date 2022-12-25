library ieee;
use ieee.std_logic_1164.all;

package dataMemory is
    component dmem is
        port(addrRead, addrWrite, dataWrite : in std_logic_vector(15 downto 0) ; clk, writeEn : in std_logic ; dataRead : out std_logic_vector(15 downto 0));
    end component dmem;
end package dataMemory;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dmem is
    port(addrRead, addrWrite, dataWrite : in std_logic_vector(15 downto 0) ; clk, writeEn : in std_logic ; dataRead : out std_logic_vector(15 downto 0));
end entity dmem;

architecture arc of dmem is
    type memory is array(0 to 655) of std_logic_vector(15 downto 0);
    signal dm : memory;
begin
    process(clk, writeEn)
    begin
        dataRead <= dm(to_integer(unsigned(addrRead)));
        if(clk'event and clk = '1' and writeEn = '1')then
            dm(to_integer(unsigned(addrWrite))) <= dataWrite;
        end if;
    end process;
end arc;