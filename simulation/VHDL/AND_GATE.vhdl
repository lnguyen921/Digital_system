
------
--// Company: 
--// Engineer: 
--// 
--// Create Date: 03/07/2024 10:00:34 AM
--// Design Name: 
--// Module Name: AND_GATE


--// Additional Comments:
-- VHDL TB code generator: https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
-- Copyright Doulos ltd

-------------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity AND_GATE is
    Port ( a: in STD_LOGIC;
           b: in STD_LOGIC;
           c: out STD_LOGIC);  
end AND_GATE;
    

architecture Behavioral of AND_GATE is

begin

    c <= a AND b;


end Behavioral;
