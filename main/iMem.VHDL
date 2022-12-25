library ieee;
use ieee.std_logic_1164.all;

package iMemory is
    component imem is
        port(Addr : in std_logic_vector(15 downto 0) ; clk : in std_logic ; iOut : out std_logic_vector(31 downto 0));
    end component imem;
end package iMemory;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity imem is
    port(Addr : in std_logic_vector(15 downto 0) ; clk : in std_logic ; iOut : out std_logic_vector(31 downto 0));
end entity imem;

architecture arc of imem is
    type mem_array is array (0 to 65535) of std_logic_vector(15 downto 0);
    signal m : mem_array;
begin
    process(clk)
	 begin
        iOut(31 downto 16) <= m(to_integer(unsigned(Addr)));
        iOut(15 downto 0) <= m(to_integer(unsigned(Addr)+1));
    end process;
end arc;