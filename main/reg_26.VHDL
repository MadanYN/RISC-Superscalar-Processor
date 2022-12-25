library ieee;
use ieee.std_logic_1164.all;

package reg_26 is
    component reg26 is
        port(I : in std_logic_vector(25 downto 0) ; clk : in std_logic ; O : out std_logic_vector(25 downto 0));
    end component reg26;
end package reg_26;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg26 is
    port(I : in std_logic_vector(25 downto 0) ; clk : in std_logic ; O : out std_logic_vector(25 downto 0));
end entity reg26;

architecture arc of reg26 is
begin
    process(clk)
    begin
        if(clk'event and clk = '1')then
            O <= I;
        end if;
    end process;
end arc;