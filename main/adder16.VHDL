library ieee;
use ieee.std_logic_1164.all;

package adder16 is
    component add16 is
        port(A, B : in std_logic_vector(15 downto 0) ; Sum : out std_logic_vector(15 downto 0));
    end component add16;
end package adder16;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add16 is
    port(A, B : in std_logic_vector(15 downto 0) ; Sum : out std_logic_vector(15 downto 0));
end entity add16;

architecture arc of add16 is
begin
    Sum <= std_logic_vector(to_unsigned(to_integer(unsigned(A) + to_integer(unsigned(B))), 16));
end arc;