----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:15:29 06/16/2015 
-- Design Name: 
-- Module Name:    mux_in - Behavioral 
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

entity mux_in is
    Port ( bit_in : in  STD_LOGIC_VECTOR (0 downto 0);
           sel_in : in  STD_LOGIC_VECTOR (5 downto 0);
           data_io : inout  STD_LOGIC_VECTOR (32 downto 0));
end mux_in;

architecture Behavioral of mux_in is


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
                data_in(0) <= data_in when "00000",
                data_in(1) <= data_in when "00001",
                data_in(2) <= data_in when "00010",
                data_in(3) <= data_in  when "00011",
                data_in(4)  <= data_in when "00100",
                data_in(5)  <= data_in when "00101",
                data_in(6)  <= data_in when "00110",
                data_in(7)  <= data_in when "00111",
                data_in(8)  <= data_in when "01000",
                data_in(9)  <= data_in when "01001",
                data_in(10)  <= data_in when "01010",
                data_in(11) <= data_in  when "01011",
                data_in(12)  <= data_in when "01100",
                data_in(13) <= data_in  when "01101",
                data_in(14)  <= data_in when "01110",
                data_in(15)  <= data_in when "01111",
                data_in(16)  <= data_in when "10000",
                data_in(17)  <= data_in when "10001",
                data_in(18)  <= data_in when "10010",
                data_in(19) <= data_in  when "10011",
                data_in(20) <= data_in  when "10100",
                data_in(21)  <= data_in when "10101",
                data_in(22)  <= data_in when "10110",
                data_in(23) <= data_in  when "10111",
                data_in(24)  <= data_in when "11000",
                data_in(25)  <= data_in when "11001",
                data_in(26)  <= data_in when "11010",
                data_in(27)  <= data_in when "11011",
                data_in(28)  <= data_in when "11100",
                data_in(29)  <= data_in when "11101",
                data_in(30)  <= data_in when "11110",
                data_in(31)  <= data_in when "11111";
         
end Behavioral;


begin


end Behavioral;

