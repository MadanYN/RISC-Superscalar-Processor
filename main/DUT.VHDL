library ieee;
use ieee.std_logic_1164.all;

library work;
use work.InF.all;
use work.InstructionDecode.all;
use work.InstructionDispatch.all;

entity DUT is
	port(instruction: in std_logic_vector(15 downto 0); clk,rst: in std_logic);
end entity DUT;

architecture arc of DUT is
	signal pcw: std_logic;
	signal jlr: std_logic_vector(39 downto 0);
	signal exec: std_logic_vector(40 downto 0);
	signal ifout: std_logic_vector(63 downto 0);
	signal wrongpred: std_logic;
	signal wrongpredpc: std_logic_vector(13 downto 0);
	signal branches: std_logic;
	signal tags: std_logic_vector(13 downto 0);
	signal decout1,decout2: std_logic_vector(52 downto 0);
	signal head: std_logic_vector(6 downto 0);
	signal datarpv1,datarpv2: std_logic_vector(26 downto 0);
	signal r_datav: std_logic_vector(19 downto 0);
	signal p_datav1,p_datav2,p_datav3,p_datav4: std_logic_vector(23 downto 0);
	signal disoutex: std_logic_vector(232 downto 0);
	signal disoutrob1,disoutrob2: std_logic_vector(39 downto 0);
	signal lhi1,lhi2: std_logic_vector(15 downto 0);
	signal resalu: std_logic_vector(24 downto 0);
	signal resload: std_logic_vector(23 downto 0);
	signal resfetch: std_logic_vector(14 downto 0);
	signal crename,zrename,cdata,zdata: std_logic;
	signal full: std_logic;
begin
	FETCH_STAGE: fetchStage port map(clk,pcw,rst,jlr,exec,ifout,wrongpred,wrongpredpc);
	DECODE_STAGE: decode port map(ifout,clk,rst,branches,tags,decout1,decout2);
	DISPATCH_STAGE: dispatch port map(crename,zrename,cdata,zdata,full,decout1,decout2,clk,rst,head,datarpv1,datarpv2,r_datav,p_datav1,p_datav2,p_datav3,p_datav4,disoutex,disoutrob1,disoutrob2,jlr,lhi1,lhi2);
	EXECUTE_ALUBR: execute port map(clk,rst,disoutex(224 downto 0),resalu,exec,datarpv1);
	EXECUTE_LS: exeLWSW port map(disoutex(225)&disoutex(99 downto 90)&disoutex(232 downto 236)&disoutex(89 downto 0),clk,resload&'1',datarpv2);
	REORDER_STAGE: rob_wb port map(clk,rst,disoutrob1,disoutrob2,lhi1,lhi2,resalu,resload,resfetch,head&tags,p_datav1(7 downto 1),p_datav1(23 downto 8),p_datav1(0),p_datav2(7 downto 1),p_datav2(23 downto 8),p_datav2(0),p_datav3(7 downto 1),p_datav3(23 downto 8),p_datav3(0),p_datav4(7 downto 1),p_datav4(23 downto 8),p_datav4(0),crename,zrename,r_datav(19 downto 4),r_datav(3 downto 1),r_datav(0),cdata,zdata,full,branches);
end arc;
