library ieee;
use ieee.std_logic_1164.all;

package InstructionDispatch is
	component dispatch is
		port(crename,zrename,cdata,zdata,full: in std_logic; A1,A2: in std_logic_vector(52 downto 0); clk,rst: in std_logic; head: in std_logic_vector(6 downto 0); datarpv1,datarpv2: in std_logic_vector(26 downto 0); r_datav: in std_logic_vector(19 downto 0); p_datav1,p_datav2,p_datav3,p_datav4: in std_logic_vector(23 downto 0); Y: out std_logic_vector(232 downto 0); W1,W2: out std_logic_vector(39 downto 0); jlr: out std_logic_vector(39 downto 0); lhi_data1,lhi_data2: out std_logic_vector(15 downto 0));
	end component dispatch;
end package InstructionDispatch;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dispatch is
	port(crename,zrename,cdata,zdata,full: in std_logic; A1,A2: in std_logic_vector(52 downto 0); clk,rst: in std_logic; head: in std_logic_vector(6 downto 0); datarpv1,datarpv2: in std_logic_vector(26 downto 0); r_datav: in std_logic_vector(19 downto 0); p_datav1,p_datav2,p_datav3,p_datav4: in std_logic_vector(23 downto 0); Y: out std_logic_vector(232 downto 0); W1,W2: out std_logic_vector(39 downto 0); jlr: out std_logic_vector(39 downto 0); lhi_data1,lhi_data2: out std_logic_vector(15 downto 0));
end entity dispatch;

architecture arc of dispatch is
	type reservation_station is array(0 to 63) of std_logic_vector(92 downto 0);
	type architectural_register_file is array(0 to 7) of std_logic_vector(23 downto 0);
	type physical_register_file is array(0 to 126) of type std_logic_vector(17 downto 0);
	type forwarded is array(0 to 1) of type std_logic_vector(26 downto 0);
	signal rs: reservation_station;
	signal arf: architectural_register_file;
	signal prf: physical_register_file;
	variable rsi1, rsi2: natural range 0 to 63;
	variable pf1, pf2: natural range 0 to 126;
	signal p1, p2, p: std_logic_vector(6 downto 0);
	signal r1, r2, r: std_logic_vector(2 downto 0);
	signal lhi1, lhi1: std_logic;
	signal cz1, cz2: std_logic_vector(1 downto 0);
	signal tag1, tag2, tag: std_logic_vector(6 downto 0);
	signal pc1, pc2: std_logic_vector(15 downto 0);
	signal branch1, branch2: std_logic;
	signal type1, type2: std_logic_vector(1 downto 0);
	signal spec1, spec2: std_logic;
	signal jlr_ready: std_logic;
	signal xfor: forwarded;
	variable branch_sched, alu_sched, load_sched, store_sched: natural range 0 to 63;
	variable branch_init, alu_init, load_init, store_init: natural range 0 to 63;
	variable t, h, branc_diff_min, alu_diff_min, load_diff_min, store_diff_min: natural range 0 to 253;
begin
	process(clk)
	begin
		if(rst='1') then
			--resetting buffers
			rs <= (others => (others => '0'));
		else
			--RF will check all the entries with valid bit 1 (PRF) or busy bit 0 (ARF) and send those to dispatch stage in a cycle
			--ARF, PRF each have 4 output ports. Each port will send 16 bit data + 1 valid bit[If any port is not sending valid data then 0 thus ignore that data]
			--RB has all the busy bits of ARF, P has two free physical registers

			--allocating rs entry to newly arrived instructions
			for i in 0 to 63 loop
				if(rs(i)(63)='0') then
					rsi1 := i;
					for j in i+1 to 63 loop
						if(rs(j)(63)='0') then
							rsi2 := j;
							--exit;
						end if;
					end loop;
					exit;
				end if;
			end loop;

			--unpacking 1st instruction into rs
			rs(rsi1)(92 downto 90) <= A1(37 downto 35);		--r (write register)
			rs(rsi1)(89 downto 83) <= (others => '1');		--p (write renamed register)
			rs(rsi1)(82 downto 76) <= A1(52 downto 46);		--tag (7 bits)
			rs(rsi1)(75 downto 74) <= A1(45 downto 44);		--main_type (2 bits)
			rs(rsi1)(73 downto 71) <= A1(43 downto 41);		--sub_type (3 bits)
			rs(rsi1)(70 downto 69) <= A1(40 downto 39);		--i_type (2 bits)
			rs(rsi1)(68) <= A1(38);							--spec (1 bit)
			rs(rsi1)(67 downto 55) <= (others => '0');		--extended part of opr1 (13 bits)
			rs(rsi1)(54 downto 52) <= A1(37 downto 35);		--opr1 (3 bits)
			rs(rsi1)(51) <= '0';							--valid1 (1 bit)
			rs(rsi1)(50 downto 38) <= (others => '0');		--extended part of opr2 (13 bits)
			rs(rsi1)(37 downto 35) <= A1(34 downto 32);		--opr2 (3 bits)
			rs(rsi1)(34) <= '0';							--valid2 (1 bit)
			rs(rsi1)(33 downto 18) <= A1(31 downto 16);		--opr3 (16 bits)
			rs(rsi1)(17) <= '0';							--valid3 (1 bit)
			rs(rsi1)(16 downto 1) <= A1(15 downto 0);		--pc (16 bits)
			rs(rsi1)(0)	<= '0';								--ready (1 bit)

			--unpacking 2nd instruction into rs
			rs(rsi2)(92 downto 90) <= A2(37 downto 35);		--r (write register)
			rs(rsi2)(89 downto 83) <= (others => '1');		--p (write renamed register)
			rs(rsi2)(82 downto 76) <= A2(52 downto 46);		--tag (7 bits)
			rs(rsi2)(75 downto 74) <= A2(45 downto 44);		--main_type (2 bits)
			rs(rsi2)(73 downto 71) <= A2(43 downto 41);		--sub_type (3 bits)
			rs(rsi2)(70 downto 69) <= A2(40 downto 39);		--i_type (2 bits)
			rs(rsi2)(68) <= A2(38);							--spec (1 bit)
			rs(rsi2)(67 downto 55) <= (others => '0');		--extended part of opr1 (13 bits)
			rs(rsi2)(54 downto 52) <= A2(37 downto 35);		--opr1 (3 bits)
			rs(rsi2)(51) <= '0';							--valid1 (1 bit)
			rs(rsi2)(50 downto 38) <= (others => '0');		--extended part of opr2 (13 bits)
			rs(rsi2)(37 downto 35) <= A2(34 downto 32);		--opr2 (3 bits)
			rs(rsi2)(34) <= '0';							--valid2 (1 bit)
			rs(rsi2)(33 downto 18) <= A2(31 downto 16);		--opr3 (16 bits)
			rs(rsi2)(17) <= '0';							--valid3 (1 bit)
			rs(rsi2)(16 downto 1) <= A2(15 downto 0);		--pc (16 bits)
			rs(rsi2)(0)	<= '0';								--ready (1 bit)

			--finding free physical register
			for i in 0 to 126 loop
				if(prf(i)(17)='0') then
					pf1 := i;
					for j in i+1 to 126 loop
						if(prf(j)(17)='0') then
							pf2 := j;
							exit;
						end if;
					end loop;
					exit;
				end if;
			end loop;

			--data forwarded from execution
			xfor(0) <= datarpv1;
			xfor(1) <= datarpv2;

			--write back
				--prf write back
			if(p_datav1(0)='1') then
				prf(to_integer(unsigned(p_datav1(7 downto 1))))(16 downto 0) <= p_datav1(23 downto 8)&'1';
			end if;
			if(p_datav2(0)='1') then
				prf(to_integer(unsigned(p_datav2(7 downto 1))))(16 downto 0) <= p_datav2(23 downto 8)&'1';
			end if;
			if(p_datav3(0)='1') then
				prf(to_integer(unsigned(p_datav3(7 downto 1))))(16 downto 0) <= p_datav3(23 downto 8)&'1';
			end if;
			if(p_datav4(0)='1') then
				prf(to_integer(unsigned(p_datav4(7 downto 1))))(16 downto 0) <= p_datav4(23 downto 8)&'1';
			end if;

				--arf write back
			if(r_datav(0)='1') then
				arf(to_integer(unsigned(r_datav(3 downto 1))))(23 downto 7) <= '0'&r_datav(19 downto 4);
				prf(to_integer(unsigned(arf(to_integer(unsigned(r_datav(3 downto 1))))(6 downto 0))))(17) <= '1';
			end if;

			--operand read
			for i in 0 to 63 loop
				if(rs(i)(75 downto 74)="01") then
					if(rs(i)(34)='0') then
						r <= rs(i)(37 downto 35);
						if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
							p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
							if(to_integer(unsigned(p))/=127) then
								if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
									rs(i)(50 downto 35) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
									rs(i)(34) <= '1';													--set valid bit in rs to '1'
								else
									for j in 0 to 1 loop
										if(xfor(j)(7 downto 0)=p&'1') then
											rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
											rs(i)(34) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else
								for j in 0 to 1 loop
									if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
										rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
										rs(i)(34) <= '1';
										exit;
									end if;
								end loop;
							end if;
						else																		--busy bit in ARF is '0' so data is available in ARF
							rs(i)(50 downto 35) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
							rs(i)(34) <= '1';														--set valid bit in rs to '1'
						end if;
					end if;
					if(rs(i)(17)='0') then
						r <= rs(i)(20 downto 18);
						if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
							p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
							if(to_integer(unsigned(p))/=127) then
								if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
									rs(i)(33 downto 18) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
									rs(i)(17) <= '1';													--set valid bit in rs to '1'
								else
									for j in 0 to 1 loop
										if(xfor(j)(7 downto 0)=p&'1') then
											rs(i)(33 downto 18) <= xfor(j)(26 downto 11);
											rs(i)(17) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else
								for j in 0 to 1 loop
									if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
										rs(i)(33 downto 18) <= xfor(j)(26 downto 11);
										rs(i)(17) <= '1';
										exit;
									end if;
								end loop;
							end if;
						else																		--busy bit in ARF is '0' so data is available in ARF
							rs(i)(33 downto 18) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
							rs(i)(17) <= '1';														--set valid bit in rs to '1'
						end if;
					end if;
				elsif(rs(i)(75 downto 74)="00") then												--Branch
					if(rs(i)(73 downto 71)="000") then												--BEQ
						if(rs(i)(51)='0') then
							r <= rs(i)(54 downto 52);
							if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
								p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
								if(to_integer(unsigned(p))/=127) then
									if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
										rs(i)(67 downto 52) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
										rs(i)(51) <= '1';													--set valid bit in rs to '1'
									else
										for j in 0 to 1 loop
											if(xfor(j)(7 downto 0)=p&'1') then
												rs(i)(67 downto 52) <= xfor(j)(26 downto 11);
												rs(i)(51) <= '1';
												exit;
											end if;
										end loop;
									end if;
								else
									for j in 0 to 1 loop
										if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
											rs(i)(67 downto 52) <= xfor(j)(26 downto 11);
											rs(i)(51) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else																		--busy bit in ARF is '0' so data is available in ARF
								rs(i)(67 downto 52) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
								rs(i)(51) <= '1';														--set valid bit in rs to '1'
							end if;
						end if;
						if(rs(i)(34)='0') then
							r <= rs(i)(37 downto 35);
							if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
								p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
								if(to_integer(unsigned(p))/=127) then
									if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
										rs(i)(50 downto 35) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
										rs(i)(34) <= '1';													--set valid bit in rs to '1'
									else
										for j in 0 to 1 loop
											if(xfor(j)(7 downto 0)=p&'1') then
												rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
												rs(i)(34) <= '1';
												exit;
											end if;
										end loop;
									end if;
								else
									for j in 0 to 1 loop
										if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
											rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
											rs(i)(34) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else																		--busy bit in ARF is '0' so data is available in ARF
								rs(i)(50 downto 35) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
								rs(i)(34) <= '1';														--set valid bit in rs to '1'
							end if;
						end if;
						rs(i)(17) <= '1';																--immediate value so valid bit set to '1'
					elsif(rs(i)(73 downto 71)="001") then											--JAL
						rs(i)(34) <= '1';																--useless field so set valid bit to '1'
						rs(i)(17) <= '1';																--immediate value
					elsif(rs(i)(73 downto 71)="010") then											--JLR
						if(rs(i)(34)='0') then
							r <= rs(i)(37 downto 35);
							if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
								p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
								if(to_integer(unsigned(p))/=127) then
									if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
										rs(i)(50 downto 35) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
										rs(i)(34) <= '1';													--set valid bit in rs to '1'
									else
										for j in 0 to 1 loop
											if(xfor(j)(7 downto 0)=p&'1') then
												rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
												rs(i)(34) <= '1';
												exit;
											end if;
										end loop;
									end if;
								else
									for j in 0 to 1 loop
										if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
											rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
											rs(i)(34) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else																		--busy bit in ARF is '0' so data is available in ARF
								rs(i)(50 downto 35) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
								rs(i)(34) <= '1';														--set valid bit in rs to '1'
							end if;
						end if;
						rs(i)(17) <= '1';																--useless field
					elsif(rs(i)(73 downto 71)="011") then											--JRI
						if(rs(i)(51)='0') then
							r <= rs(i)(54 downto 52);
							if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
								p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
								if(to_integer(unsigned(p))/=127) then
									if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
										rs(i)(67 downto 52) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
										rs(i)(51) <= '1';													--set valid bit in rs to '1'
									else
										for j in 0 to 1 loop
											if(xfor(j)(7 downto 0)=p&'1') then
												rs(i)(67 downto 52) <= xfor(j)(26 downto 11);
												rs(i)(51) <= '1';
												exit;
											end if;
										end loop;
									end if;
								else
									for j in 0 to 1 loop
										if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
											rs(i)(67 downto 52) <= xfor(j)(26 downto 11);
											rs(i)(51) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else																		--busy bit in ARF is '0' so data is available in ARF
								rs(i)(67 downto 52) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
								rs(i)(51) <= '1';														--set valid bit in rs to '1'
							end if;
						end if;
						rs(i)(34) <= '1';																--useless field
						rs(i)(17) <= '1';																--immediate value
					end if;
				elsif(rs(i)(75 downto 74)="10") then												--Load
					if(rs(i)(73 downto 71)="000") then												--LHI
						rs(i)(34) <= '1';																--useless field
						rs(i)(17) <= '1';																--immediate value
					elsif(rs(i)(73 downto 71)="001") then											--LW
						if(rs(i)(34)='0') then
							r <= rs(i)(37 downto 35);
							if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
								p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
								if(to_integer(unsigned(p))/=127) then
									if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
										rs(i)(50 downto 35) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
										rs(i)(34) <= '1';													--set valid bit in rs to '1'
									else
										for j in 0 to 1 loop
											if(xfor(j)(7 downto 0)=p&'1') then
												rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
												rs(i)(34) <= '1';
												exit;
											end if;
										end loop;
									end if;
								else
									for j in 0 to 1 loop
										if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
											rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
											rs(i)(34) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else																		--busy bit in ARF is '0' so data is available in ARF
								rs(i)(50 downto 35) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
								rs(i)(34) <= '1';														--set valid bit in rs to '1'
							end if;
						end if;
					elsif(rs(i)(73 downto 71)="010") then											--LM
						if(rs(i)(51)='0') then
							r <= rs(i)(54 downto 52);
							if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
								p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
								if(to_integer(unsigned(p))/=127) then
									if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
										rs(i)(67 downto 52) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
										rs(i)(51) <= '1';													--set valid bit in rs to '1'
									else
										for j in 0 to 1 loop
											if(xfor(j)(7 downto 0)=p&'1') then
												rs(i)(67 downto 52) <= xfor(j)(26 downto 11);
												rs(i)(51) <= '1';
												exit;
											end if;
										end loop;
									end if;
								else
									for j in 0 to 1 loop
										if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
											rs(i)(67 downto 52) <= xfor(j)(26 downto 11);
											rs(i)(51) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else																		--busy bit in ARF is '0' so data is available in ARF
								rs(i)(67 downto 52) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
								rs(i)(51) <= '1';														--set valid bit in rs to '1'
							end if;
						end if;
						rs(i)(34) <= '1';																--useless field
						rs(i)(17) <= '1';																--immediate value
			 		end if;
			 	elsif(rs(i)(75 downto 74)="11") then												--Store
					if(rs(i)(73 downto 71)="000") then												--SW
						if(rs(i)(34)='0') then
							r <= rs(i)(37 downto 35);
							if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
								p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
								if(to_integer(unsigned(p))/=127) then
									if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
										rs(i)(50 downto 35) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
										rs(i)(34) <= '1';													--set valid bit in rs to '1'
									else
										for j in 0 to 1 loop
											if(xfor(j)(7 downto 0)=p&'1') then
												rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
												rs(i)(34) <= '1';
												exit;
											end if;
										end loop;
									end if;
								else
									for j in 0 to 1 loop
										if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
											rs(i)(50 downto 35) <= xfor(j)(26 downto 11);
											rs(i)(34) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else																		--busy bit in ARF is '0' so data is available in ARF
								rs(i)(50 downto 35) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
								rs(i)(34) <= '1';														--set valid bit in rs to '1'
							end if;
						end if;
						rs(i)(17) <= '1';																--immediate value
					elsif(rs(i)(73 downto 71)="001") then											--SM
						if(rs(i)(51)='0') then
							r <= rs(i)(54 downto 52);
							if(arf(to_integer(unsigned(r)))(23)='1') then								--busy bit in ARF is '1'
								p <= arf(to_integer(unsigned(r)))(6 downto 0);							--mapping to PRF
								if(to_integer(unsigned(p))/=127) then
									if(prf(to_integer(unsigned(p)))(0)='1') then							--valid bit in PRF is '1'
										rs(i)(67 downto 52) <= prf(to_integer(unsigned(p)))(16 downto 1);	--read data from PRF
										rs(i)(51) <= '1';													--set valid bit in rs to '1'
									else
										for j in 0 to 1 loop
											if(xfor(j)(7 downto 0)=p&'1') then
												rs(i)(67 downto 52) <= xfor(j)(26 downto 11);
												rs(i)(51) <= '1';
												exit;
											end if;
										end loop;
									end if;
								else
									for j in 0 to 1 loop
										if(xfor(j)(10 downto 8)=r and xfor(j)(0)='1') then
											rs(i)(67 downto 52) <= xfor(j)(26 downto 11);
											rs(i)(51) <= '1';
											exit;
										end if;
									end loop;
								end if;
							else																		--busy bit in ARF is '0' so data is available in ARF
								rs(i)(67 downto 52) <= arf(to_integer(unsigned(r)))(22 downto 7);		--read data from ARF
								rs(i)(51) <= '1';														--set valid bit in rs to '1'
							end if;
						end if;
						rs(i)(34) <= '1';																--useless field
						rs(i)(17) <= '1';																--immediate value
					end if;
				end if;
			end loop;

			--register renaming for 1st instruction
			if(rs(rsi1)(75 downto 74)="01") then															--ALU
				r1 <= rs(rsi1)(54 downto 52);																--architectural register
				if(arf(to_integer(unsigned(r1)))(23)='1') then												--busy bit in ARF='1'
					arf(to_integer(unsigned(r1)))(6 downto 0) <= std_logic_vector(to_unsigned(pf1,7));		--insert tag of renamed register in ARF
					prf(pf1)(17) <= '1';																	--set busy bit of renamed register to '1'
					p1 <= std_logic_vector(to_unsigned(pf1,7));												--renamed register
					rs(rsi1)(58 downto 51) <= p1&'1';														--renamed register and valid bit in rs
				else																						--busy bit in ARF='0'
					p1 <= (others => '1');																	--p1=127 means no renaming
					arf(to_integer(unsigned(r1)))(23) <= '1';												--set busy bit of architectural register to '1'
				end if;
			elsif(rs(rsi1)(75 downto 74)="00") then															--Branch
				if(rs(rsi1)(73 downto 71)="000" or rs(rsi1)(73 downto 71)="011") then						--BEQ or JRI
					r1 <= (others => '0');																	--architectural register
					p1 <= (others => '1');																	--p1=127 means no renaming
				else
					r1 <= rs(rsi1)(54 downto 52);
					if(arf(to_integer(unsigned(r1)))(23)='1') then
						arf(to_integer(unsigned(r1)))(6 downto 0) <= std_logic_vector(to_unsigned(pf1,7));
						prf(pf1)(17) <= '1';
						p1 <= std_logic_vector(to_unsigned(pf1,7));
						rs(rsi1)(58 downto 51) <= p1&'1';													
					else
						p1 <= (others => '1');
						arf(to_integer(unsigned(r1)))(23) <= '1';												--set busy bit of architectural register to '1'
					end if;
				end if;
			elsif(rs(rsi1)(75 downto 74)="10") then
				if(rs(rsi1)(73 downto 71)="010") then
					r1 <= (others => '0');
					p1 <= (others => '1');
				else
					r1 <= rs(rsi1)(54 downto 52);
					if(arf(to_integer(unsigned(r1)))(23)='1') then
						arf(to_integer(unsigned(r1)))(6 downto 0) <= std_logic_vector(to_unsigned(pf1,7));
						prf(pf1)(17) <= '1';
						p1 <= std_logic_vector(to_unsigned(pf1,7));
						rs(rsi1)(58 downto 51) <= p1&'1';													
					else
						p1 <= (others => '1');
						arf(to_integer(unsigned(r1)))(23) <= '1';												--set busy bit of architectural register to '1'
					end if;
				end if;
			elsif(rs(rsi1)(75 downto 74)="11") then
				r1 <= (others => '0');
				p1 <= (others => '1');
			end if;

			rs(rsi1)(92 downto 90) <= r1;
			rs(rsi1)(89 downto 83) <= p1;

			--register renaming for 2nd instruction
			if(rs(rsi2)(75 downto 74)="01") then
				r2 <= rs(rsi2)(54 downto 52);
				if(arf(to_integer(unsigned(r2)))(23)='1') then
					arf(to_integer(unsigned(r2)))(6 downto 0) <= std_logic_vector(to_unsigned(pf2,7));
					prf(pf2)(17) <= '1';
					p2 <= std_logic_vector(to_unsigned(pf2,7));
					rs(rsi2)(58 downto 51) <= p2&'1';													
				else
					p2 <= (others => '1');
					arf(to_integer(unsigned(r2)))(23) <= '1';												--set busy bit of architectural register to '1'
				end if;
			elsif(rs(rsi2)(75 downto 74)="00") then
				if(rs(rsi2)(73 downto 71)="000" or rs(rsi2)(73 downto 71)="011") then
					r2 <= (others => '0');
					p2 <= (others => '1');
				else
					r2 <= rs(rsi2)(54 downto 52);
					if(arf(to_integer(unsigned(r2)))(23)='1') then
						arf(to_integer(unsigned(r2)))(6 downto 0) <= std_logic_vector(to_unsigned(pf2,7));
						prf(pf2)(17) <= '1';
						p2 <= std_logic_vector(to_unsigned(pf2,7));
						rs(rsi2)(58 downto 51) <= p2&'1';													
					else
						p2 <= (others => '1');
						arf(to_integer(unsigned(r2)))(23) <= '1';												--set busy bit of architectural register to '1'
					end if;
				end if;
			elsif(rs(rsi2)(75 downto 74)="10") then
				if(rs(rsi2)(73 downto 71)="010") then
					r2 <= (others => '0');
					p2 <= (others => '1');
				else
					r2 <= rs(rsi2)(54 downto 52);
					if(arf(to_integer(unsigned(r2)))(23)='1') then
						arf(to_integer(unsigned(r2)))(6 downto 0) <= std_logic_vector(to_unsigned(pf2,7));
						prf(pf2)(17) <= '1';
						p2 <= std_logic_vector(to_unsigned(pf2,7));
						rs(rsi2)(58 downto 51) <= p2&'1';													
					else
						p2 <= (others => '1');
						arf(to_integer(unsigned(r2)))(23) <= '1';												--set busy bit of architectural register to '1'
					end if;
				end if;
			elsif(rs(rsi2)(75 downto 74)="11") then
				r2 <= (others => '0');
				p2 <= (others => '1');
			end if;

			rs(rsi2)(92 downto 90) <= r2;
			rs(rsi2)(89 downto 83) <= p2;

			--ROB entry	--LHI data to ROB
				--lhi bit
			if(rs(rsi1)(75 downto 74)="10" and rs(rsi1)(73 downto 71)="000") then
				lhi1 <= '1';
				lhi_data1 <= rs(rsi1)(33 downto 18);
			else
				lhi1 <= '0';
				lhi_data1 <= (others => '0');
			end if;
			if(rs(rsi2)(75 downto 74)="10" and rs(rsi2)(73 downto 71)="000") then
				lhi2 <= '1';
				lhi_data2 <= rs(rsi2)(33 downto 18);
			else
				lhi2 <= '0';
				lhi_data2 <= (others => '0');
			end if;

				--cz modify bits
			if(rs(rsi1)(75 downto 74)="01") then
				cz1(0) <= '1';
				if(rs(rsi1)(73)='0' or rs(rsi1)(73 downto 71)="111") then
					cz1(1) <= '1';
				else
					cz1(1) <= '0';
				end if;
			elsif(rs(rsi1)(75 downto 74)="10" and rs(rsi1)(73 downto 71)="001") then
				cz1 <= "01";
			else
				cz1 <= "00";
			end if;
			if(rs(rsi2)(75 downto 74)="01") then
				cz2(0) <= '1';
				if(rs(rsi2)(73)='0' or rs(rsi2)(73 downto 71)="111") then
					cz2(1) <= '1';
				else
					cz2(1) <= '0';
				end if;
			elsif(rs(rsi2)(75 downto 74)="10" and rs(rsi2)(73 downto 71)="001") then
				cz2 <= "01";
			else
				cz2 <= "00";
			end if;

				--tag
			tag1 <= rs(rsi1)(82 downto 76);
			tag2 <= rs(rsi2)(82 downto 76);

				--pc
			pc1 <= rs(rsi1)(16 downto 1);
			pc2 <= rs(rsi2)(16 downto 1);

				--r
			--r1 already initialized
			--r2 already initialized

				--p
			--p1 already initialized
			--p2 already initialized

				--branch,type bits
			if(rs(rsi1)(75 downto 74)="00") then
				if(rs(rsi1)(73 downto 71)="000") then
					branch1 <= '1';
					type1 <= "00";
				else
					branch1 <= '0';
					type1 <= rs(rsi1)(72 downto 71);
				end if;
			else
				branch1 <= '0';
				type1 <= "00";
			end if;
			if(rs(rsi2)(75 downto 74)="00") then
				if(rs(rsi2)(73 downto 71)="000") then
					branch2 <= '1';
					type2 <= "00";
				else
					branch2 <= '0';
					type2 <= rs(rsi2)(72 downto 71);
				end if;
			else
				branch2 <= '0';
				type2 <= "00";
			end if;

				--speculation bits
			spec1 <= rs(rsi1)(68);
			spec2 <= rs(rsi2)(68);

			W1 <= lhi1&cz1&tag1&pc1&r1&p1&branch1&type1&spec1;
			W2 <= lhi2&cz2&tag2&pc2&r2&p2&branch2&type2&spec2;

			--updating ready bits of all entries
			for i in 0 to 63 loop
				rs(i)(0) <= rs(i)(51) and rs(i)(34) and rs(i)(17);
			end loop;

			--JLR to BTB <tag(7) PC(16) reg(16) valid(1)>
			jlr_ready <= '0';
			for i in 0 to 63 loop
				if(rs(i)(75 downto 74)="00" and rs(i)(73 downto 71)="010" and rs(i)(0)='1') then
					jlr_ready <= '1';
					jlr(39 downto 33) <= rs(i)(82 downto 76);
					jlr(32 downto 17) <= rs(i)(16 downto 1);
					jlr(16 downto 1) <= rs(i)(50 downto 35);
					jlr(0) <= '1';
					exit;
				end if;
			end loop;
			if(jlr_ready='0') then
				jlr <= (others => '0');
			end if;

			--issue
			h := to_integer(unsigned(head));
			branch_diff_min := 0;
			alu_diff_min := 0;
			load_diff_min := 0;
			store_diff_min := 0;

			for i in 0 to 63 loop
				if(rs(i)(75 downto 74)="00") then
					branch_init := i;
					exit;
				end if;
			end loop;

			for i in 0 to 63 loop
				if(rs(i)(75 downto 74)="01") then
					alu_init := i;
					exit;
				end if;
			end loop;

			for i in 0 to 63 loop
				if(rs(i)(75 downto 74)="10") then
					load_init := i;
					exit;
				end if;
			end loop;

			for i in 0 to 63 loop
				if(rs(i)(75 downto 74)="11") then
					store_init := i;
					exit;
				end if;
			end loop;

			branch_sched := branch_init;
			alu_sched := alu_init;
			load_sched := load_init;
			store_sched := store_init;

			for i in 0 to 63 loop
				tag <= rs(i)(82 downto 76);
				t := to_integer(unsigned(tag));
				if(rs(i)(75 downto 74)="00" and rs(i)(0)='1') then											--branch
					if(t<h) then
						t := t + 127;
						if(t-h<=branch_diff_min) then
							branch_diff_min := t-h;
							branch_sched := i;
						end if;
					end if;
				elsif(rs(i)(75 downto 74)="01" and rs(i)(0)='1') then											--branch
					if(t<h) then
						t := t + 127;
						if(t-h<=alu_diff_min) then
							alu_diff_min := t-h;
							alu_sched := i;
						end if;
					end if;
				elsif(rs(i)(75 downto 74)="10" and rs(i)(0)='1') then											--branch
					if(t<h) then
						t := t + 127;
						if(t-h<=load_diff_min) then
							load_diff_min := t-h;
							load_sched := i;
						end if;
					end if;
				elsif(rs(i)(75 downto 74)="11" and rs(i)(0)='1') then											--branch
					if(t<h) then
						t := t + 127;
						if(t-h<=store_diff_min) then
							store_diff_min := t-h;
							store_sched := i;
						end if;
					end if;
				end if;
			end loop;

			if(rs(branch_sched)(0)='0') then
				--nop
				Y(224 downto 152) <= (others => '1');							--tag=127 implies nop
			else
				Y(224 downto 218) <= rs(branch_sched)(82 downto 76);
				Y(217 downto 216) <= rs(branch_sched)(72 downto 71);
				Y(215 downto 200) <= rs(branch_sched)(67 downto 52);
				Y(199 downto 184) <= rs(branch_sched)(50 downto 35);
				Y(183 downto 168) <= rs(branch_sched)(33 downto 18);
				Y(167 downto 152) <= rs(branch_sched)(16 downto 1);
			end if;

			if(rs(alu_sched)(0)='0') then
				--nop
				Y(151 downto 100) <= (others => '1');
			else
				Y(151 downto 149) <= rs(alu_sched)(92 downto 90);
				Y(148 downto 142) <= rs(alu_sched)(89 downto 83);
				Y(141 downto 135) <= rs(alu_sched)(82 downto 76);
				Y(134 downto 132) <= rs(alu_sched)(73 downto 71);
				Y(131 downto 116) <= rs(alu_sched)(50 downto 35);
				Y(115 downto 100) <= rs(alu_sched)(33 downto 18);
			end if;

			if(rs(load_sched)(0)='0') then
				--nop
				Y(99 downto 48) <= (others => '1');
			else
				Y(99 downto 97) <= rs(load_sched)(92 downto 90);
				Y(96 downto 90) <= rs(load_sched)(89 downto 83);
				Y(89 downto 83) <= rs(load_sched)(82 downto 76);
				Y(82 downto 80) <= rs(load_sched)(92 downto 90);
				Y(79 downto 64) <= rs(load_sched)(50 downto 35);
				Y(63 downto 48) <= rs(load_sched)(33 downto 18);
			end if;

			if(rs(store_sched)(0)='0') then
				--nop
				Y(47 downto 0) <= (others => '1');
			else
				Y(47 downto 32) <= rs(store_sched)(67 downto 52);
				Y(31 downto 16) <= rs(store_sched)(50 downto 35);
				Y(15 downto 0) <= rs(store_sched)(33 downto 18);
				Y(232 downto 226) <= rs(store_sched)(82 downto 76);
				Y(225) <= rs(store_sched)(68);
			end if;
		end if;
	end process;
end arc;