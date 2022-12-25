library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--ROB buffer and Writeback
--there are 127 indexes in rob from 0 to 126 and if tag=1111111 (127) (it means NOP)

--inputs

--Universal Input: reset, clock

--lhi: 0-no,1-yes
--C_Z : 00-none, 01-only Z, 10-only C,11 both
--type(2) : 01-JAL,10-JLR,00-none, 11-JRI
--branch(1) : BEQ-1
--from decode and dispatch stage: lhi(1) C_Z(2),c_rename(1),Z_rename(1),tag(7),PC(16),R(3),P(7),branch(1),type(2),spec(1) = 40bits
-- the above will be for 2 instruction so First_Ins,Second_Ins 

--	from execute stage
-- there are alu,load,store pipelines, so there will be this many results 
--ALU pipeline: tag(7) result_alu(16),C_result(1),Z_result(1) = 25bits
-- LOAD pipeline : tag(7) result_load(16) Z_result(1) {execute stage will tell whether content is zero or not} = 24bits


--from fetch stage (it will confirm its prediction of BEQ instruction to make instruction S->NS or flush)
--tag(7) prediction_right(1) = 8 bits

--rob length = 40+16+1+1=58


--outputs

--to decode and dispatch stage (ROB will tell it where is next two free location)
-- head(7),location1(7),location2(7) = 21 bits

-- to writeback stage (store instruction will write back to memory while alu instruction to architectural registers)
-- dataout(16) --> it will be address for data for store ins and data for alu type ins
--address of register (3) [for alu instructions]

--Universal Output
--full(1): if rob is full


package Re_Order_Buffer_Writeback is
	component rob_wb is
		Port( 
			clk: in  std_logic;
			rst: in  std_logic;
			ins1: in std_logic_vector (39 downto 0); --instruction 1
			ins2: in std_logic_vector (39 downto 0) ;--instruction 2
			imm_lhi1 : in std_logic_vector (15 downto 0); --immediate 9 bits + "0000000" of LHI instruction1
			imm_lhi2 : in std_logic_vector (15 downto 0); --immediate 9 bits + "0000000" of LHI instruction2
			inp_alu: in std_logic_vector (24 downto 0); --from alu pipeline
			inp_load: in std_logic_vector ( 23 downto 0) ;--from load pipeline
			inp_fetch: in std_logic_vector (14 downto 0) ;--from fetch stage
			
			indexes:out std_logic_vector(20 downto 0); --for decode and dispatch stage
			
			
			
			rename_reg_addr1 : out std_logic_vector (6 downto 0);
			rename_reg_data1: out std_logic_vector (15 downto 0);
			rename_reg_writeEn1 : out std_logic;


			rename_reg_addr2 : out std_logic_vector (6 downto 0);
			rename_reg_data2: out std_logic_vector (15 downto 0);
			rename_reg_writeEn2 : out std_logic;

			rename_reg_addr3 : out std_logic_vector (6 downto 0);
			rename_reg_data3: out std_logic_vector (15 downto 0);
			rename_reg_writeEn3 : out std_logic;

			rename_reg_addr4 : out std_logic_vector (6 downto 0);
			rename_reg_data4: out std_logic_vector (15 downto 0);
			rename_reg_writeEn4 : out std_logic;			
			
			rename_c_data : out std_logic;
			rename_z_data : out std_logic; 
			
			reg_data : out std_logic_vector (15 downto 0);
			reg_addr: out std_logic_vector (2 downto 0) ;
			reg_writeEn : out std_logic;
			
			C_data : out std_logic;
			Z_data : out std_logic;
			
			full	: out std_logic;
			
			branch_present : out std_logic
		);
	end component rob_wb;
end package Re_Order_Buffer_Writeback;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity rob_wb is
		Port( 
			clk: in  std_logic;
			rst: in  std_logic;
			ins1: in std_logic_vector (39 downto 0); --instruction 1
			ins2: in std_logic_vector (39 downto 0) ;--instruction 2
			imm_lhi1 : in std_logic_vector (15 downto 0); --immediate 9 bits + "0000000" of LHI instruction1
			imm_lhi2 : in std_logic_vector (15 downto 0); --immediate 9 bits + "0000000" of LHI instruction2
			inp_alu: in std_logic_vector (24 downto 0); --from alu pipeline
			inp_load: in std_logic_vector ( 23 downto 0) ;--from load pipeline
			inp_fetch: in std_logic_vector (14 downto 0) ;--from fetch stage
			
			indexes:out std_logic_vector(20 downto 0); --for decode and dispatch stage
			
			
			
			rename_reg_addr1 : out std_logic_vector (6 downto 0);
			rename_reg_data1: out std_logic_vector (15 downto 0);
			rename_reg_writeEn1 : out std_logic;


			rename_reg_addr2 : out std_logic_vector (6 downto 0);
			rename_reg_data2: out std_logic_vector (15 downto 0);
			rename_reg_writeEn2 : out std_logic;

			rename_reg_addr3 : out std_logic_vector (6 downto 0);
			rename_reg_data3: out std_logic_vector (15 downto 0);
			rename_reg_writeEn3 : out std_logic;

			rename_reg_addr4 : out std_logic_vector (6 downto 0);
			rename_reg_data4: out std_logic_vector (15 downto 0);
			rename_reg_writeEn4 : out std_logic;			
			
			rename_c_data : out std_logic;
			rename_z_data : out std_logic; 
			
			reg_data : out std_logic_vector (15 downto 0);
			reg_addr: out std_logic_vector (2 downto 0) ;
			reg_writeEn : out std_logic;
			
			C_data : out std_logic;
			Z_data : out std_logic;
			
			full	: out std_logic;
			
			branch_present : out std_logic
		);

end rob_wb;

architecture rob_wb_arc of rob_wb is



begin

	rob_wb_proc : process (clk)
	

	type table is array (0 to 126) of std_logic_VECTOR (59 downto 0);
	variable rob_table : table := (others => (others => '0'));
	
	variable head : integer:=0;
	variable tail : integer:=0;
	variable looped : integer := 0;
	variable i : integer := 0; --used in flushing and S->NS
	variable orig_i : integer := 0; --recording tail while flushing
	variable j : integer := 0; --used in checking valid tag when sent by exe stage
	variable br_count : integer :=0 ; --branch count in rob
	variable empty : integer:= 1 ; --is rob empty
	variable oldest_tag : integer:= 0 ; 
	variable tag2 : integer:= 0 ; 
	variable tag1 : integer:= 0 ; 
	
	
	
	begin
--	if(rising_edge(clk)) then
			if (rst = '1') then
				head := 0;
				tail := 0;
				looped := 0;
				rob_table := (others => (others => '0'));
			else 
				
				--doing work related to rob entry ins1 and ins2
				if(ins1(34 downto 28) /= "1111111") then
					rob_table(tail)(57 downto 18 ) := ins1;
					empty:=0;
					if(rob_table(head)(20 downto 19) /= "00" and rob_table(head)(20 downto 19) /= "11") then -- JAL/JLR
						rob_table(tail)(17 downto 2) := std_logic_vector(to_unsigned(to_integer(unsigned(ins1(29 downto 14)))+16,16));
						rename_reg_addr1<=ins1(10 downto 4);
						rename_reg_data1<=rob_table(tail)(17 downto 2); --storing PC+16 in rename register
						rename_reg_writeEn1 <= '1';
					elsif(ins1(39) ='1') then --LHI instruction
						rob_table(tail)(17 downto 2) := imm_lhi1;
--						rob_table(tail)(8 down to 2) := "0000000";
						rename_reg_addr1<=ins1(10 downto 4);
						rename_reg_data1<=rob_table(tail)(17 downto 2); --storing Imm+"0000000" in rename register
						rename_reg_writeEn1 <= '1';
					end if;
					if(ins1(3) ='1' or ins1(2 downto 1) /= "00") then --branch type ins
						br_count:=br_count+1;
					end if;
					tail := (tail+1) mod 127;
					rename_reg_writeEn1<='0';
				end if;
				
				
				if(ins2(34 downto 28) /= "1111111") then
					rob_table(tail)(57 downto 18 ) := ins2;
					empty:=0;
					if(rob_table(head)(20 downto 19) /="00" and rob_table(head)(20 downto 19) /= "11") then -- JAL/JLR
						rob_table(tail)(17 downto 2) := std_logic_vector(to_unsigned(to_integer(unsigned(ins2(29 downto 14)))+16,16));
						rename_reg_addr2<=ins2(10 downto 4);
						rename_reg_data2<=rob_table(tail)(17 downto 2); --storing PC+16 in rename register
						rename_reg_writeEn2<='1';
					elsif(ins2(39) = '1') then --LHI instruction
						rob_table(tail)(17 downto 2) := imm_lhi2;
--						rob_table(tail)(8 down to 2) := "0000000";
						rename_reg_addr2<=ins2(10 downto 4);
						rename_reg_data2<=rob_table(tail)(17 downto 2); --storing Imm+"0000000" in rename register
						rename_reg_writeEn2<='1';
					end if;
					if(ins2(3) ='1' or ins2(2 downto 1) /= "00") then --branch ins
						br_count:=br_count+1;
					end if;					
					tail := (tail+1) mod 127;
					rename_reg_writeEn2<='0';
				end if;
				
				
				--checking if it got looped after adding new entries
				-- it can't be changed from looped to unlooped since head is not moving
				-- looped means that latest instruction added is behind head (you know what I mean)
				if(looped = 0 and tail<= head) then --earlier it was not looped and now it got looped
					looped :=1 ;
				end if;
				
				
				-- doing work related to confirmed branch prediction/JAL JLR JRI type from fetch stage
				-- "whenever there is nothing to tell, make tag =127"
				-- "whenever JRI/JAL/JLR address is known from exe stage then send inp_fetch(0) =0 (for flush) "
				
				if(inp_fetch(14) = '0') then --both prediction correct

					i := to_integer(unsigned(inp_fetch(6 downto 0)));						
					if(looped=1) then 
						rob_table(i)(0):='0';
						br_count:=br_Count-1;
						if(i<tail) then
							i:=(i+1);
							while(rob_table(i)(21) = '0' and rob_table(i)(20 downto 19) = "00" and i<tail) loop
								rob_table(i)(18) := '0'; --making NS
								i :=i+1;
							end loop;
						else 
							i :=(i+1) mod 127;
							while(rob_table(i)(21) = '0' and rob_table(i)(20 downto 19) = "00" and i/=tail) loop
								rob_table(i)(18) := '0'; --making NS
								i :=(i+1) mod 127;
							end loop;							
						end if;
					else  --looped =0
						rob_table(i)(0):='0';
						br_count:=br_count-1;
						i:=(i+1);
						while(rob_table(i)(21) = '0' and rob_table(i)(20 downto 19) = "00" and i<tail) loop
							rob_table(i)(18) := '0'; --making NS
							i :=(i+1) mod 127;
						end loop;							
					end if;
					
					i := to_integer(unsigned(inp_fetch(13 downto 7)));						
					if(looped=1) then 
						rob_table(i)(0):='0';
						br_count:=br_Count-1;
						if(i<tail) then
							i:=(i+1);
							while(rob_table(i)(21) = '0' and rob_table(i)(20 downto 19) = "00" and i<tail) loop
								rob_table(i)(18) := '0'; --making NS
								i :=i+1;
							end loop;
						else 
							i :=(i+1) mod 127;
							while(rob_table(i)(21) = '0' and rob_table(i)(20 downto 19) = "00" and i/=tail) loop
								rob_table(i)(18) := '0'; --making NS
								i :=(i+1) mod 127;
							end loop;							
						end if;
					else  --looped =0
						rob_table(i)(0):='0';
						br_count:=br_count-1;
						i:=(i+1);
						while(rob_table(i)(21) = '0' and rob_table(i)(20 downto 19) = "00" and i<tail) loop
							rob_table(i)(18) := '0'; --making NS
							i :=(i+1) mod 127;
						end loop;							
					end if;
				
				else --See for oldest valid tag(not 127) and flush the instructions that came after that
				
					tag1:=to_integer(unsigned(inp_fetch(6 downto 0)));
					tag2:=to_integer(unsigned(inp_fetch(7 downto 13)));
					
					if(tag1=127) then
						oldest_tag:=tag2;
					elsif(tag2=127) then
						oldest_tag:=tag1;
					else --find oldest tag
					   
						if(to_integer(unsigned(rob_table(head)(54 downto 48))) = tag1) then
							oldest_tag:=tag1;
						elsif(to_integer(unsigned(rob_table(head)(54 downto 48))) = tag2) then
							oldest_tag:=tag2;
						else 
							i:=(head+1) mod 127;
							while(i/=tail) loop
								if(to_integer(unsigned(rob_table(i)(54 downto 48))) = tag1) then
									oldest_tag:=tag1;
									exit;
								elsif(to_integer(unsigned(rob_table(i)(54 downto 48))) = tag2) then
									oldest_tag:=tag2;
									exit;
								end if;
								i:=(i+1) mod 127;
							end loop;

						end if;
						
						
					
						i:=oldest_tag;
						--finding whether ROB will be empty after flushing
						if(i=head and (rob_table(i)(21) = '1' or rob_table(i)(20 downto 19) = "11" )) then
							empty:=1;
							head:=0;
							tail:=0;
						else 
							empty:=0;
						end if;
						
						
						--finding where will be tail pointer after flushing
						if(rob_table(i)(21) = '1' or rob_table(i)(20 downto 19) = "11") then --BEQ orJRI (will be flushed)
							orig_i:=i;
						else 
							orig_i:=(i+1) mod 127;
						end if;

						-- flushing BEQ/JRI at i and not flushing JLR/JAL at i
						if(rob_table(i)(21) = '1' or rob_table(i)(20 downto 19) = "11") then	--if BEQ or JRI then flush (JLR/JAL will need writeback)
							rob_table(i) := (others => '0');
							
						else -- JAL/JLR have to be made NS
							rob_table(i)(0) := '0';  
						end if;
						br_count:=br_count-1; --BEQ/JRI flushed, JAL/JLR marked NS : in either case br_count--;
						
						
						
						if(looped=1) then 
							if(i<tail) then
								i:=(i+1);
								while(i<tail) loop
									if(rob_table(i)(21) = '1' or rob_table(i)(20 downto 19) /= "00") then
										br_count:=br_count-1; --if BEQ/JAL/JLR/JLI then br_count--
									end if ;
									rob_table(i) := (others => '0'); --flushing
									i :=i+1;
								end loop;
								
								
								
								
							else 
								i :=(i+1) mod 127;
								while(i/=tail) loop
									if(rob_table(i)(21) = '1' or rob_table(i)(20 downto 19) /= "00") then
										br_count:=br_count-1; --if BEQ/JAL/JLR/JLI then br_count--
									end if ;
									rob_table(i) := (others => '0'); --flushing
									i :=(i+1) mod 127;
								end loop;
								
							end if;
							
							tail:=orig_i;
							if(tail>=head) then
								looped:=0;
							end if ;
							
						else  --looped =0
							i:=(i+1);
							
							while(i<tail) loop
								if(rob_table(i)(21) = '1' or rob_table(i)(20 downto 19) /= "00") then
									br_count:=br_count-1; --if BEQ/JAL/JLR/JLI then br_count--
								end if ;
								rob_table(i) := (others => '0'); --flushing
								i :=i+1;
							end loop;
							
							looped :=0 ;--redundant
							tail:=orig_i;
						end if;	
					
					end if;
				
				end if;
				
				
				
				--doing work related to results given by execute stage
				--alu pipeline
				
				rename_reg_writeEn3<= '0';
				j := to_integer(unsigned(inp_alu(24 downto 18)));
				if(inp_alu(24 downto 18) /= "1111111" and ((j>=head and j<tail) or (tail=head and empty=0) or (j>=head or j<tail)) ) then
					rob_table(j)(17 downto 0) := inp_alu(17 downto 0);
					rename_reg_addr3<=rob_table(j)(28 downto 22);	
					rename_reg_data3<=rob_table(j)(17 downto 2);
					rename_reg_writeEn3<= '1';
					rename_c_data<=rob_table(j)(1);
					rename_z_data<=rob_table(j)(0);
				end if;
				
				--load pipeline 
				
				rename_reg_writeEn4<= '0';
				j := to_integer(unsigned(inp_load(23 downto 17)));
				if(inp_load(7 downto 1) /= "1111111" and ((j>=head and j<tail) or (tail=head and empty=0) or (j>=head or j<tail))) then
					rob_table(j)(0) := inp_load(0); --z result
					rob_table(j)(17 downto 2) := inp_load(16 downto 1); -- content
					rename_reg_writeEn4<= '1';
					rename_reg_addr4<=rob_table(j)(28 downto 22);	
					rename_reg_data4<=rob_table(j)(17 downto 2);
					rename_z_data<=rob_table(j)(0);					
				end if;
				
				
				
				--retiring instructions
				--C_Z : 00-none, 01-only Z, 10-only C,11 both
				--type(2) : 01-JAL,10-JLR,00-none, 11-JRI
				--branch(1) : BEQ-1
				--"something related to write enable in reg file;"
				j := to_integer(unsigned(rob_table(head)(54 downto 48)));
				if(rob_table(head)(18) = '0' and empty=0 and ((j>=head and j<tail) or (tail=head and empty=0) or (j>=head or j<tail))) then -- it means tag is valid and non speculative
					if(rob_table(head)(21) /= '1' and rob_table(head)(20 downto 19) /= "11" ) then --neither a BEQ nor JRI
							reg_data<=rob_table(head)(17 downto 2);
							reg_addr<=rob_table(head)(31 downto 29);
							reg_writeEn<='1';
							
						--modify CZ flags
						
						if(rob_table(head)(56 downto 55) = "11") then
							C_data<= rob_table(head)(1);
							Z_data<= rob_table(head)(0);
						elsif(rob_table(head)(56 downto 55) = "10") then
							C_data<= rob_table(head)(1);
						elsif(rob_table(head)(56 downto 55) = "01") then
							Z_data<= rob_table(head)(0);
						end if;
					end if;
					
					--about looped(can be only looped to unlooped)
					if(head = 126) then
						looped:=0;
					end if;
					
					--about br_count
					
					if(rob_table(head)(21) = '1' or rob_table(head)(20 downto 19) /= "00" ) then
						br_count:=br_count-1;
					end if;
					
					rob_table(head) := (others => '0');
					head:=(head+1) mod 127;
					
					if(head=tail) then
						empty:=1;
						head:=0;
						tail:=0;
					end if;
				end if;
				
			
			end if;
						
				
				
	-- sending head, free locations, branch_present to decode and fetch stage				
					
			indexes(20 downto 14) <= std_logic_vector(to_unsigned(head,7));
			if (tail = head and empty=0 ) then 
				indexes(13 downto 0) <= "11111111111111"; --no place for any instruction 
			elsif(tail=head and empty=1) then --empty
				indexes(13 downto 7) <= std_logic_vector(to_unsigned(tail,7));
				indexes(6 downto 0) <= std_logic_vector(to_unsigned((tail+1) mod 127,7));
			end if;
			
			
			if(tail > head) then
				indexes(13 downto 7) <= std_logic_vector(to_unsigned(tail,7));
				if(head>0 or tail /=126) then
					indexes(6 downto 0) <= std_logic_vector(to_unsigned((tail+1) mod 127,7)); --there is place for second ins
				else 
					indexes(6 downto 0) <= "1111111"; -- no place for second instruction
				end if;
			end if;
			
			if(tail<head) then
				indexes(13 downto 7) <= std_logic_vector(to_unsigned(tail,7));
				if (head /=tail+1) then
					indexes(6 downto 0) <= std_logic_vector(to_unsigned(tail+1,7)); --there is place for second ins
				else 
					indexes(6 downto 0) <= "1111111"; --no place for second instruction
				end if;
			end if;
			
			if(br_count>0) then
				branch_present<='1';
			end if;
			if(tail=head and empty=0) then
				full<='1';
			else
				full<='0';
			end if;
--		end if;	
	end process;
		
end rob_wb_arc;