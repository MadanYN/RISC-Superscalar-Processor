library ieee;
use ieee.std_logic_1164.all;

package executestage is
    component execute is
        port(clk, res : in std_logic ;  Ooinp : in std_logic_vector(224 downto 0) ; robres : out std_logic_vector(24 downto 0); 
             brres : out std_logic_vector(40 downto 0); dfalu : out std_logic_vector(26 downto 0));
    end component execute;
end package executestage; 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute is
    port(clk, res : in std_logic ; Ooinp : in std_logic_vector(224 downto 0) ; robres : out std_logic_vector(24 downto 0); 
         brres : out std_logic_vector(40 downto 0); dfalu : out std_logic_vector(26 downto 0));
end entity execute;

architecture arch of execute is	 
	 function add(A: in std_logic_vector(15 downto 0); B: in std_logic_vector(15 downto 0)) return std_logic_vector is
		variable i : integer;
		variable sum : std_logic_vector(16 downto 0) := (others => '0');
		variable carry : std_logic_vector(16 downto 0) := (others => '0');
	 begin
		carry(0) := '0';
		for i in 0 to 15 loop
			carry(i+1) := (A(i) AND B(i)) OR (A(i) AND carry(i)) OR (carry(i) AND B(i));
         	sum(i) := carry(i) XOR A(i) XOR B(i);
        end loop;
			sum(16) := carry(16);
        return sum;
    end add;

begin
    process(clk, Ooinp)
    begin	      
	      if(res = '0') then
			       dfalu(10 downto 1) <= Ooinp(224 downto 215);
                robres(24 downto 18) <= Ooinp(214 downto 208);
                brres(40 downto 34) <= Ooinp(172 downto 166);
                brres(33 downto 18) <= Ooinp(115 downto 100);
                case (Ooinp(207 downto 205)) is
                    when "000" =>
								robres(17 downto 2) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
		    	            robres(1) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(16);
								dfalu(26 downto 11) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
								if (to_integer(unsigned(add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0)))= 0) then
								    robres(0) <= '1';
								else
								    robres(0) <= '0';
								end if;
                        if (to_integer(unsigned(Ooinp(214 downto 208)))= 127) then
                            dfalu(0) <= '0';
                        else
                            dfalu(0) <= '1';
								end if;
                    when "001" =>
                        robres(17 downto 2) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
		    	            robres(1) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(16);
								dfalu(26 downto 11) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
								if (to_integer(unsigned(add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0)))= 0) then
								    robres(0) <= '1';
								else
								    robres(0) <= '0';
								end if;
                        if (to_integer(unsigned(Ooinp(214 downto 208)))= 127) then
                            dfalu(0) <= '0';
                        else
                            dfalu(0) <= '1';
								end if;
                    when "010" =>
						      robres(17 downto 2) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
		    	            robres(1) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(16);
                        dfalu(26 downto 11) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
								if (to_integer(unsigned(add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0)))= 0) then
								    robres(0) <= '1';
								else
								    robres(0) <= '0';
								end if;
                        if (to_integer(unsigned(Ooinp(214 downto 208)))= 127) then
                            dfalu(0) <= '0';
                        else
                            dfalu(0) <= '1';
								end if;
                    when "011" =>
			               robres(17 downto 2) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
		    	            robres(1) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(16);
                        dfalu(26 downto 11)<= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
								if (to_integer(unsigned(add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0)))= 0) then
								    robres(0) <= '1';
								else
								    robres(0) <= '0';
								end if;
                        if (to_integer(unsigned(Ooinp(214 downto 208)))= 127) then
                            dfalu(0) <= '0';
                        else
                            dfalu(0) <= '1';
								end if;
			           when "100" =>
                        robres(17 downto 2) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
		    	            robres(1) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(16);
                        dfalu(26 downto 11) <= add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0);
								if (to_integer(unsigned(add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0)))= 0) then
								    robres(0) <= '1';
								else
								    robres(0) <= '0';
								end if;
                        if (to_integer(unsigned(Ooinp(214 downto 208)))= 127) then
                            dfalu(0) <= '0';
                        else
                            dfalu(0) <= '1';
								end if;
                    when "101" =>
                        robres(17 downto 2) <= Ooinp(204 downto 189) nand Ooinp(188 downto 173);
								robres(1) <= '0';
								dfalu(26 downto 11) <= Ooinp(204 downto 189) nand Ooinp(188 downto 173);
								if (to_integer(unsigned(add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0)))= 0) then
								    robres(0) <= '1';
								else
								    robres(0) <= '0';
								end if;
                        if (to_integer(unsigned(Ooinp(214 downto 208)))= 127) then
                            dfalu(0) <= '0';
                        else
                            dfalu(0) <= '1';
								end if;
                    when "110" =>
                        robres(17 downto 2) <= Ooinp(204 downto 189) nand Ooinp(188 downto 173);
								robres(1) <= '0';
								dfalu(26 downto 11) <= Ooinp(204 downto 189) nand Ooinp(188 downto 173);
								if (to_integer(unsigned(add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0)))= 0) then
								    robres(0) <= '1';
								else
								    robres(0) <= '0';
								end if;
                        if (to_integer(unsigned(Ooinp(214 downto 208)))= 127) then
                            dfalu(0) <= '0';
                        else
                            dfalu(0) <= '1';
								end if;
                    when "111" =>
                        robres(17 downto 2) <= Ooinp(204 downto 189) nand Ooinp(188 downto 173);
								robres(1) <= '0';
								dfalu(26 downto 11) <= Ooinp(204 downto 189) nand Ooinp(188 downto 173);
								if (to_integer(unsigned(add(Ooinp(204 downto 189), Ooinp(188 downto 173))(15 downto 0)))= 0) then
								    robres(0) <= '1';
								else
								    robres(0) <= '0';
								end if;
                        if (to_integer(unsigned(Ooinp(214 downto 208)))= 127) then
                            dfalu(0) <= '0';
                        else
                            dfalu(0) <= '1';
								end if;
                end case;
		    case (Ooinp(165 downto 164)) is
                    when "00" =>
				            if (Ooinp(163 downto 148) = Ooinp(147 downto 132)) then
                            brres(17 downto 2) <= add(Ooinp(115 downto 100), Ooinp(131 downto 116))(15 downto 0);
									 brres(1 downto 0) <= "11";
                        else
                            brres(17 downto 2) <= add(Ooinp(115 downto 100),"0000000000000001")(15 downto 0);
                            brres(1 downto 0) <= "01";
                        end if;
                    when "01" =>
                        brres(17 downto 2) <= add(Ooinp(115 downto 100), Ooinp(131 downto 116))(15 downto 0);
                        brres(1 downto 0) <= "11";
                    when "11" =>
				            brres(17 downto 2) <= add(Ooinp(163 downto 148), Ooinp(131 downto 116))(15 downto 0);
                        brres(1 downto 0) <= "11";
						  when "10" =>
						      brres(17 downto 2) <= add(Ooinp(115 downto 100),"0000000000000001")(15 downto 0);
                        brres(1 downto 0) <= "00";	      
                end case;
          else
              brres <= (others =>'0');
              robres <= (others =>'0');
          end if;
    end process;
end arch;