library ieee;
use ieee.std_logic_1164.all;

package progCounter is
    component pc is
        port(A : in std_logic_vector(15 downto 0) ; clk, pcw, rst : in std_logic ; Y : out std_logic_vector(15 downto 0));
    end component pc;
end package progCounter;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc is
    port(A : in std_logic_vector(15 downto 0) ; clk, pcw, rst : in std_logic ; Y : out std_logic_vector(15 downto 0));
end entity pc;

architecture arc of pc is
    signal buff : std_logic_vector(15 downto 0) := (others => '0');
begin
    process(A, clk, pcw)
    begin
		  if(rst = '1') then
				buff <= "0000000000000000";
		  else
		      buff <= A;
		  end if;
        if(clk'event and clk = '1' and pcw = '1') then
            Y <= buff;
        end if;
    end process;
end arc;