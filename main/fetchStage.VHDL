library ieee;
use ieee.std_logic_1164.all;

package InF is
    component fetchStage is
        port(clk, pcw, rst : in std_logic; fromDispatch : in std_logic_vector(39 downto 0); fromExe : in std_logic_vector(40 downto 0); 
		  ifOut : out std_logic_vector(63 downto 0); wrongPredn : out std_logic; wrongPrednPC : out std_logic_vector(13 downto 0));
    end component fetchStage;
end package InF; 
--fromExe : 16 bit PC & 16 bit branch addr result & 1 bit result & 1 bit valid(en)


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.iMemory.all;            --iMem.vhd
use work.progCounter.all;     --pc.vhd
use work.brPred.all;          --branchPredictor.vhd
use work.Notify.all;          --note.vhdl

entity fetchStage is
    port(clk, pcw, rst : in std_logic; fromDispatch : in std_logic_vector(39 downto 0); fromExe : in std_logic_vector(40 downto 0);
	 ifOut : out std_logic_vector(63 downto 0); wrongPredn : out std_logic; wrongPrednPC : out std_logic_vector(13 downto 0));
end entity fetchStage;

architecture arc of fetchStage is
    signal predn : std_logic;
	 signal wrong0, wrong1 : std_logic;
	 signal tag00, tag01 : std_logic_vector(6 downto 0);
	 signal targetAddr0 : std_logic_vector(15 downto 0);
    signal brPredIn, brPredOut, pcIn, iMemIn, pcOut : std_logic_vector(15 downto 0);
    signal iMemOut : std_logic_vector(31 downto 0);

begin
    --clk <= clk0;
	 --res <= res0;
	 --en <= en0;
	 --pcw <= pcw0;
	 --rst <= rst0;
	 --targetAddr <= targetAddr0;
    PC0 : pc port map (pcIn, clk, pcw, rst, pcOut);
    iMem0 : imem port map (iMemIn, clk, iMemOut);
    brPred0 : biMode port map (clk, rst, fromExe, fromDispatch, pcOut, predn, wrong0, wrong1, brPredOut, tag00, tag01);
	 note0 : noti port map (wrong0, wrong1, tag00, tag01, wrongPredn, wrongPrednPC);
	 
	 process(clk)
	 begin
	 
		if(predn = '1') then
			pcIn <= brPredOut;
		else
			pcIn <= std_logic_vector(to_unsigned(to_integer(unsigned(pcOut)) + 2, 16));
		end if;

		ifOut(31 downto 0) <= iMemOut;
	end process;
end arc;