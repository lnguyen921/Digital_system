----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/07/2024 11:05:52 AM
-- Design Name: 
-- Module Name: AND_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- Additional Comments:
-- TB created from: https://www.doulos.com/knowhow/perl/vhdl-testbench-creation-using-perl/
----------------------------------------------------------------------------------


library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity AND_GATE_tb is
end;

architecture bench of AND_GATE_tb is

  component AND_GATE
      Port ( a: in STD_LOGIC;
             b: in STD_LOGIC;
             c: out STD_LOGIC);  
  end component;

  signal a: STD_LOGIC;
  signal b: STD_LOGIC;
  signal c: STD_LOGIC;

begin

  uut: AND_GATE port map ( a => a,
                           b => b,
                           c => c );

  stimulus: process
  begin
  
    -- Put initialisation code here
        a <= '0';
        b <= '0';
        wait for 10 ns;
        
        a <= '1';
        b <= '0';
        wait for 10 ns;
        
        a <= '0';
        b <= '1';
        wait for 10 ns;
        
        a <= '1';
        b <= '1';
        wait for 10 ns;
        
      

    -- Put test bench stimulus code here

    wait;
  end process;


end;
  
