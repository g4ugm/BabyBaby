----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:25:35 05/29/2015 
-- Design Name: 
-- Module Name:    mux - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mux is
    Port ( data_in : in  STD_LOGIC_VECTOR (31 downto 0);
           sel : in  STD_LOGIC_VECTOR (4 downto 0);
           data_out : out  STD_LOGIC);
end mux;

architecture Behavioral of mux is

begin

with sel select
    data_out <= data_in(0) when "00000",
                data_in(1) when "00001",
                data_in(2) when "00010",
                data_in(3) when "00011",
                data_in(4) when "00100",
                data_in(5) when "00101",
                data_in(6) when "00110",
                data_in(7) when "00111",
                data_in(8) when "01000",
                data_in(9) when "01001",
                data_in(10) when "01010",
                data_in(11) when "01011",
                data_in(12) when "01100",
                data_in(13) when "01101",
                data_in(14) when "01110",
                data_in(15) when "01111",
                data_in(16) when "10000",
                data_in(17) when "10001",
                data_in(18) when "10010",
                data_in(19) when "10011",
                data_in(20) when "10100",
                data_in(21) when "10101",
                data_in(22) when "10110",
                data_in(23) when "10111",
                data_in(24) when "11000",
                data_in(25) when "11001",
                data_in(26) when "11010",
                data_in(27) when "11011",
                data_in(28) when "11100",
                data_in(29) when "11101",
                data_in(30) when "11110",
                data_in(31) when "11111",
         '0'  when others;


end Behavioral;

