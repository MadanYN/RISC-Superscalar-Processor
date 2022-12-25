library ieee;
use ieee.std_logic_1164.all;

package Notify is
	component noti is
		port(wrongPredn0, wrongPredn1 : in std_logic; tag0, tag1 : in std_logic_vector(6 downto 0);
		wrongPredn : out std_logic; wrongPrednPC : out std_logic_vector(13 downto 0));
	end component noti;
end package Notify;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity noti is
	port(wrongPredn0, wrongPredn1 : in std_logic; tag0, tag1 : in std_logic_vector(6 downto 0);
	wrongPredn : out std_logic; wrongPrednPC : out std_logic_vector(13 downto 0));
end entity noti;

architecture arc of noti is
begin
	notify0 : process(wrongPredn0, wrongPredn1, tag0, tag1) is
	begin
		if(wrongPredn0 = '1' and wrongPredn1 = '1') then
			wrongPredn <= '1';
			wrongPrednPC <= tag0 & tag1;
		elsif(wrongPredn0 = '1')then
			wrongPredn <= '1';
			wrongPrednPC <= tag0 & "1111111";
		elsif(wrongPredn1 = '1')then
			wrongPredn <= '1';
			wrongPrednPC <= "1111111" & tag1;
		else
			wrongPredn <= '0';
			wrongPrednPC <= "11111111111111";
		end if;
	end process notify0;
end arc;
