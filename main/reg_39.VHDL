library ieee;
use ieee.std_logic_1164.all;

package reg_39 is
    component reg39 is
        port(I : in std_logic_vector(38 downto 0) ; clk : in std_logic ; O : out std_logic_vector(38 downto 0));
    end component reg39;
end package reg_39;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg39 is
    port(I : in std_logic_vector(38 downto 0) ; clk : in std_logic ; O : out std_logic_vector(38 downto 0));
end entity reg39;

architecture arc of reg39 is
begin
    process(clk)
    begin
        if(clk'event and clk = '1')then
            O <= I;
        end if;
    end process;
end arc;