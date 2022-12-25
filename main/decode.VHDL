library ieee;
use ieee.std_logic_1164.all;

package InstructionDecode is
	component decode is
		port(A: in std_logic_vector(63 downto 0); clk,rst,branches: in std_logic; tags: in std_logic_vector(13 downto 0); Y1,Y2: out std_logic_vector(52 downto 0));	--Y to RS
	end component decode;
end package InstructionDecode;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode is
	port(A: in std_logic_vector(63 downto 0); clk,rst,branches: in std_logic; tags: in std_logic_vector(13 downto 0); Y1,Y2: out std_logic_vector(52 downto 0));	--Y to RS
end entity decode;

architecture arc of	decode is
	type decode_buffer is array(0 to 1) of type std_logic_vector(31 downto 0);					-- <i(16 bits) pc(16 bits)>
	--type previous_write_registers is array(0 to 7) of type natural range 0 to 32;				-- <count> [max. count = max. no. of entries possible in RS]
	--type previous_read_registers is array(0 to 7) of type natural range 0 to 64;
	signal db: decode_buffer;
	--signal pwr: previous_write_registers;
	--signal prr: previous_read_registers;
	signal pc1, pc2, i1, i2: std_logic_vector(15 downto 0);
	signal main_type1, main_type2: std_logic_vector(1 downto 0);								-- Branch ALU Load Store
	signal sub_type1, sub_type2: std_logic_vector(2 downto 0);
	signal i_type1, i_type2: std_logic_vector(1 downto 0);										-- R/I/J
	signal dependency1, dependency2: std_logic_vector(3 downto 0);								-- <no/WAR/WAW(2 bits) no/RAW(1 bit) no/RAW(1 bit)>
	signal opr1, opr2: std_logic_vector(2 downto 0);
	signal opr3: std_logic_vector(15 downto 0);
	variable prev_branches: natural;
	signal spec: std_logic;

	--function dependency_check(R: in std_logic_vector(2 downto 0); w: in std_logic) return std_logic_vector(1 downto 0) is
	---- w='0' means read field register, w='1' means write field register
	--begin
	--	if(w='0') then
	--		if(pwr(to_integer(unsigned(R)))/=0) then
	--			return "01";								-- RAW
	--		else
	--			return "00";								-- no dependency
	--		end if;
	--	else
	--		if(pwr(to_integer(unsigned(R)))/=0) then
	--			return "11";								-- WAW
	--		elsif(prr(to_integer(unsigned(R)))/=0) then
	--			return "10";								-- WAR
	--		else
	--			return "00";								-- no dependency
	--		end if;
	--	end if;
	--end dependency_check;

begin
	process(clk)
	begin
		if(rst='1') then
			--resetting buffers
			db <= (others => (others => '0'));
			--pwr <= (others => (others => '0'));
			--prr <= (others => (others => '0'));
			prev_branches := 0;
			spec <= '0';
		else
			prev_branches := to_integer(unsigned(branches));

			--storing input in decode buffer
			db(0) <= A(63 downto 32);
			db(1) <= A(31 downto 0);
			
			--unpacking contents of decode buffer for decoding
			pc1 <= db(0)(31 downto 16);				--15 downto 0
			pc2 <= db(1)(15 downto 0);				--15 downto 0
			i1 <= db(0)(31 downto 16);				--15 downto 0
			i2 <= db(1)(15 downto 0);				--15 downto 0

			--decoding 1st instruction
			if(i1(15 downto 12)="0001") then
				main_type1 <= "01";					--ALU
				i_type1 <= "00";					--R
				if(i1(1 downto 0)="00") then
					sub_type1 <= "000";				--ADD
				elsif(i1(1 downto 0)="10") then
					sub_type1 <= "001";				--ADC
				elsif(i1(1 downto 0)="01") then
					sub_type1 <= "010";				--ADZ
				elsif(i1(1 downto 0)="11") then
					sub_type1 <= "011";				--ADL
				end if;
			elsif(i1(15 downto 12)="0000") then
				main_type1 <= "01";					--ALU
				sub_type1 <= "111";					--ADI
				i_type1 <= "01";					--I
			elsif(i1(15 downto 12)="0010") then
				main_type1 <= "01";					--ALU
				i_type1 <= "00";					--R
				if(i1(1 downto 0)="00") then
					sub_type1 <= "100";				--NDU
				elsif(i1(1 downto 0)="10") then
					sub_type1 <= "101";				--NDC
				elsif(i1(1 downto 0)="01") then
					sub_type1 <= "110";				--NDZ
				end if;
			elsif(i1(15 downto 12)="0011") then
				main_type1 <= "10";					--Load
				sub_type1 <= "000";					--LHI
				i_type1 <= "10";					--J
			elsif(i1(15 downto 12)="0111") then
				main_type1 <= "10";					--Load
				sub_type1 <= "001";					--LW
				i_type1 <= "01";					--I
			elsif(i1(15 downto 12)="1100") then
				main_type1 <= "10";					--Load
				sub_type1 <= "010";					--LM
				i_type1 <= "10";					--J
			elsif(i1(15 downto 12)="0101") then
				main_type1 <= "11";					--Store
				sub_type1 <= "000";					--SW
				i_type1 <= "01";					--I
			elsif(i1(15 downto 12)="1101") then
				main_type1 <= "11";					--Store
				sub_type1 <= "001";					--SM
				i_type1 <= "10";					--J
			elsif(i1(15 downto 12)="1000") then
				main_type1 <= "00";					--Branch
				sub_type1 <= "000";					--BEQ
				i_type1 <= "01";					--I
			elsif(i1(15 downto 12)="1001") then
				main_type1 <= "00";					--Branch
				sub_type1 <= "001";					--JAL
				i_type1 <= "01";					--I
			elsif(i1(15 downto 12)="1010") then
				main_type1 <= "00";					--Branch
				sub_type1 <= "010";					--JLR
				i_type1 <= "01";					--I
			elsif(i1(15 downto 12)="1011") then
				main_type1 <= "00";					--Branch
				sub_type1 <= "011";					--JRI
				i_type1 <= "10";					--J
			end if;

			--decoding 2nd instruction
			if(i2(15 downto 12)="0001") then
				main_type2 <= "01";					--ALU
				i_type2 <= "00";					--R
				if(i2(1 downto 0)="00") then
					sub_type2 <= "000";				--ADD
				elsif(i2(1 downto 0)="10") then
					sub_type2 <= "001";				--ADC
				elsif(i2(1 downto 0)="01") then
					sub_type2 <= "010";				--ADZ
				elsif(i2(1 downto 0)="11") then
					sub_type2 <= "011";				--ADL
				end if;
			elsif(i2(15 downto 12)="0000") then
				main_type2 <= "01";					--ALU
				sub_type2 <= "111";					--ADI
				i_type2 <= "01";					--I
			elsif(i2(15 downto 12)="0010") then
				main_type2 <= "01";					--ALU
				i_type2 <= "00";					--R
				if(i2(1 downto 0)="00") then
					sub_type2 <= "100";				--NDU
				elsif(i2(1 downto 0)="10") then
					sub_type2 <= "101";				--NDC
				elsif(i2(1 downto 0)="01") then
					sub_type2 <= "110";				--NDZ
				end if;
			elsif(i2(15 downto 12)="0011") then
				main_type2 <= "10";					--Load
				sub_type2 <= "000";					--LHI
				i_type2 <= "10";					--J
			elsif(i2(15 downto 12)="0111") then
				main_type2 <= "10";					--Load
				sub_type2 <= "001";					--LW
				i_type2 <= "01";					--I
			elsif(i2(15 downto 12)="1100") then
				main_type2 <= "10";					--Load
				sub_type2 <= "010";					--LM
				i_type2 <= "10";					--J
			elsif(i2(15 downto 12)="0101") then
				main_type2 <= "11";					--Store
				sub_type2 <= "000";					--SW
				i_type2 <= "01";					--I
			elsif(i2(15 downto 12)="1101") then
				main_type2 <= "11";					--Store
				sub_type2 <= "001";					--SM
				i_type2 <= "10";					--J
			elsif(i2(15 downto 12)="1000") then
				main_type2 <= "00";					--Branch
				sub_type2 <= "000";					--BEQ
				i_type2 <= "01";					--I
			elsif(i2(15 downto 12)="1001") then
				main_type2 <= "00";					--Branch
				sub_type2 <= "001";					--JAL
				i_type2 <= "01";					--I
			elsif(i2(15 downto 12)="1010") then
				main_type2 <= "00";					--Branch
				sub_type2 <= "010";					--JLR
				i_type2 <= "01";					--I
			elsif(i2(15 downto 12)="1011") then
				main_type2 <= "00";					--Branch
				sub_type2 <= "011";					--JRI
				i_type2 <= "10";					--J
			end if;

			----if a branch was resolved/flushed, reducing number of branches 
			--prev_branches := prev_branches - to_integer(unsigned());

			if(main_type1="00") then
				prev_branches := 1;
			end if;

			if(prev_branches/=0) then
				spec <= '1';
			else
				spec <= '0';
			end if;
			
			opr1 <= i1(11 downto 9);
			if(i_type1="00") then							--R
				opr2 <= i1(8 downto 6);
				opr3 <= "0000000000000"&i1(5 downto 3);
			elsif(i_type1="01") then						--I
				opr2 <= i1(8 downto 6);
				if(i1(5)='0') then
					opr3 <= "0000000000"&i1(5 downto 0);	--sign extended
				else
					opr3 <= "1111111111"&i1(5 downto 0);	--sign extended
				end if;
			elsif(i_type1="10") then						--J
				opr2 <= "000";
				if(i1(8)='0') then
					opr3 <= "0000000"&i1(8 downto 0);		--sign extended
				else
					opr3 <= "1111111"&i1(8 downto 0);		--sign extended
				end if;
			end if;

			Y1(52 downto 46) <= tags(13 downto 7);
			Y1(45 downto 44) <= main_type1;
			Y1(43 downto 41) <= sub_type1;
			Y1(40 downto 39) <= i_type1;
			Y1(38) <= spec;
			Y1(37 downto 35) <= opr1;
			Y1(34 downto 32) <= opr2;
			Y1(31 downto 16) <= opr3;
			Y1(15 downto 0) <= pc1;

			if(main_type2="00") then
				prev_branches := 1;
			end if;

			if(prev_branches/=0) then
				spec <= '1';
			else
				spec <= '0';
			end if;

			opr1 <= i2(11 downto 9);
			if(i_type2="00") then							--R
				opr2 <= i2(8 downto 6);
				opr3 <= "0000000000000"&i2(5 downto 3);
			elsif(i_type2="01") then						--I
				opr2 <= i2(8 downto 6);
				if(i2(5)='0') then
					opr3 <= "0000000000"&i2(5 downto 0);	--sign extended
				else
					opr3 <= "1111111111"&i2(5 downto 0);	--sign extended
				end if;
			elsif(i_type2="10") then						--J
				opr2 <= "000";
				if(i2(8)='0') then
					opr3 <= "0000000"&i2(8 downto 0);		--sign extended
				else
					opr3 <= "1111111"&i2(8 downto 0);		--sign extended
				end if;
			end if;

			Y2(52 downto 46) <= tags(6 downto 0);
			Y2(45 downto 44) <= main_type2;
			Y2(43 downto 41) <= sub_type2;
			Y2(40 downto 39) <= i_type2;
			Y2(38) <= spec;
			Y2(37 downto 35) <= opr1;
			Y2(34 downto 32) <= opr2;
			Y2(31 downto 16) <= opr3;
			Y2(15 downto 0) <= pc2;
		end if;
	end process;
end arc;