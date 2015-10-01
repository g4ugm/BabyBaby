--Copyright (c) 2012 Richard T Stofer
--
--Permission is hereby granted, free of charge, to any person obtaining
--a copy of this software and associated documentation files (the
--"Software"), to deal in the Software without restriction, including
--without limitation the rights to use, copy, modify, merge, publish,
--distribute, sublicense, and/or sell copies of the Software, and to
--permit persons to whom the Software is furnished to do so, subject to
--the following conditions:
--
--The above copyright notice and this permission notice shall be
--included in all copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
--EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
--MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
--NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
--LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
--OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
--WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:54:10 11/30/2006 
-- Design Name: 
-- Module Name:    Debounce - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Debounce is
    Port ( Input	: in	STD_LOGIC;
           Clk		: in	STD_LOGIC;
           Output	: out	STD_LOGIC);
end Debounce;

architecture Behavioral of Debounce is

	signal counter		: std_logic_vector(19 downto 0);
	signal newstate	: std_logic;

begin

	process(Input, Clk)
	begin
		if rising_edge(Clk) then
			if Input /= newstate then
				newstate <= Input;
				counter	<= (others => '0');
			elsif counter = 500000 then
				Output <= Input;
			else
				counter <= counter + 1;
			end if;
		end if;
	end process;

end Behavioral;

