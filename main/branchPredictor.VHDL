library ieee;
use ieee.std_logic_1164.all;

package brPred is
	component biMode is
		port(clk, rst : in std_logic; fromExe : in std_logic_vector(40 downto 0); fromDispatch : in std_logic_vector(39 downto 0); 
		PC : in std_logic_vector(15 downto 0); predn, wrongPredn00, wrongPredn01 : out std_logic; predAddr : out std_logic_vector(15 downto 0); tag0, tag1 : out std_logic_vector(6 downto 0));
	end component biMode;
end package brPred;
--fromDispatch : 7 bit tag & 16 bit PC & 16 bit branch addr result & 1 bit valid
--fromExe : 7 bit tag & 16 bit PC & 16 bit branch addr result & 1 bit result & 1 bit valid(en)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity biMode is
	port(clk, rst : in std_logic; fromExe : in std_logic_vector(40 downto 0); fromDispatch : in std_logic_vector(39 downto 0);
	PC : in std_logic_vector(15 downto 0); predn, wrongPredn00, wrongPredn01 : out std_logic; predAddr : out std_logic_vector(15 downto 0); tag0, tag1 : out std_logic_vector(6 downto 0));
end entity biMode;

architecture arc of biMode is
	type PHT is array (0 to 255) of std_logic_vector(1 downto 0);
   type choicePred is array (0 to 255) of std_logic;
   type branchTargetBuffer is array (0 to 255) of std_logic_vector(24 downto 0);

	signal gBHR : std_logic_vector(7 downto 0) := (others => '0');
	signal wrongPredn0, wrongPredn1, predn0 : std_logic;
	signal bhr_for_dispatch : std_logic := '0';
   signal PHT0 : PHT := (others => "00");
   signal PHT1 : PHT := (others => "00");
   signal cPred : choicePred := (others => '0');
   signal brBuff : branchTargetBuffer := (others => "0000000000000000000000000"); 
	--brBuff is 16 bit addr prediction & 8 bit gBHR xor 8 bit PC & 1 bit prediction
	
begin
	tag0 <= fromExe(40 downto 34);
	tag1 <= fromDispatch(39 downto 33);
	wrongPredn00 <= wrongPredn0;
	wrongPredn01 <= wrongPredn1;
	
	predict : process(clk)
   begin
		--if the instruction is a branch instruction pred and predAddr are taken from 2-bit predictor and the
      --brAddr array respectively
      predAddr <= brBuff(to_integer(unsigned(PC(7 downto 0))))(24 downto 9);
      if(cPred(to_integer(unsigned(PC(7 downto 0)))) = '0') then
          predn0 <= PHT0(to_integer(unsigned(PC( 7 downto 0) xor gBHR)))(0);
      else
          predn0 <= PHT1(to_integer(unsigned(PC( 7 downto 0) xor gBHR)))(0);
      end if;
		  
		predn <= predn0;
		  
--		if(fromExe(1) /= brBuff(to_integer(unsigned(PC(7 downto 0))))(0)) then
--			wrongPredn0 <= '1';
--		else
--			wrongPredn0 <= '0';
--		end if;
			
		brBuff(to_integer(unsigned(PC(7 downto 0))))(8 downto 1) <= PC( 7 downto 0) xor gBHR;
		brBuff(to_integer(unsigned(PC(7 downto 0))))(0) <= predn0;
	end process predict;
	
	update : process
	begin
		if(fromExe(0) = '1') then 
			--updating branch target buffer and 1 bit choice predictor
			brBuff(to_integer(unsigned(fromExe(25 downto 18))))(24 downto 9) <= fromExe(17 downto 2);
         cPred(to_integer(unsigned(fromExe(25 downto 18)))) <= fromExe(1);
			
			--updating the 2 bit staurating predictors in the pht0 and pht1
			if(fromExe(1) = '0') then
				case PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) is
					when "00" =>
						PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "00";
               when "01" =>
                  PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "00";
               when "10" => 
                  PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "01";
               when "11" =>
                  PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "10";
            end case;

            case PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) is
                when "00" =>
                   PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "00";
                when "01" =>
                   PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "00";
                when "10" => 
                   PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "01";
                when "11" =>
                   PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "10";
            end case;

          elsif(fromExe(1) = '1') then
             case PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) is
					  when "00" =>
							PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "01";
					  when "01" =>
							PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "10";
					  when "10" => 
							PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "11";
					  when "11" =>
							PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "11";
				 end case;

				 case PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) is
					  when "00" =>
							PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "01";
					  when "01" =>
							PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "10";
					  when "10" => 
							PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "11";
					  when "11" =>
							PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromExe(25 downto 18))))(8 downto 1)))) <= "11";
				 end case;
			end if;
			
			--updating global BHR
			gBHR <= std_logic_vector(to_unsigned(to_integer(unsigned(shift_left(unsigned(gBHR), 1))) + to_integer(unsigned'('0'&fromExe(1))),8));
			
			--checking for wrong prediction
			if(fromExe(1) /= brBuff(to_integer(unsigned(PC(7 downto 0))))(0)) then
						wrongPredn0 <= '1';
			else
						wrongPredn0 <= '0';
			end if;
	   end if;
		
		wait until clk'event and clk = '1';
		
		if(fromDispatch(0) = '1') then
			--updating branch target buffer and 1 bit choice predictor
			bhr_for_dispatch <= '1';
         brBuff(to_integer(unsigned(fromDispatch(24 downto 17))))(24 downto 9) <= fromDispatch(16 downto 1);
         cPred(to_integer(unsigned(fromDispatch(25 downto 18)))) <= '1';
			
			--updating the 2 bit staurating predictors in the pht0 and pht1
			PHT0(to_integer(unsigned(brBuff(to_integer(unsigned(fromDispatch(24 downto 17))))(8 downto 1)))) <= "11";
			PHT1(to_integer(unsigned(brBuff(to_integer(unsigned(fromDispatch(24 downto 17))))(8 downto 1)))) <= "11";
			 
			 --updating global BHR
			 gBHR <= std_logic_vector(to_unsigned(to_integer(unsigned(shift_left(unsigned(gBHR), 1))) + to_integer(unsigned'('0' & bhr_for_dispatch)),8));
			 
			 --checking for wrong prediction
			 if(brBuff(to_integer(unsigned(fromDispatch(24 downto 17))))(0) /= '1') then
					wrongPredn1 <= '1';
			 else 
					wrongPredn1 <= '0';
			 end if;
			 
		else
			 bhr_for_dispatch <= '0';
			 
		end if;
		
	end process update;
	
end arc;
