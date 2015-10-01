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
-- Create Date:    08:51:22 01/28/2007 
-- Design Name: 
-- Module Name:    CES - Behavioral 
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
--
-- MCP27S16
--
-----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CES is
    Port ( Clk				: in	STD_LOGIC;
           Switches		: out	STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
           CES_SELn		: out	STD_LOGIC := '1';
           CES_MISO		: in	STD_LOGIC;
           CES_MOSI		: out	STD_LOGIC;
           CES_SCK		: out	STD_LOGIC);
end CES;

architecture Behavioral of CES is

	signal Shifter				:	std_logic_vector(15 downto 0) := (others => '0');
	signal ShiftCount			:	std_logic_vector( 3 downto 0) := (others => '0');
	signal LoadSwitches		:	std_logic;
	signal DelayCount			:	std_logic_vector( 7 downto 0) := x"7F";
--
-- added by dw - set chip address
--
	signal Chip		:  std_logic := '0';
	
	type CES_SELECT_TYPE is (CES_NOP, CES_SELECT, CES_RELEASE);
	signal CESSelectCmd : CES_SELECT_TYPE := CES_NOP;
	
	type STATE_TYPE is (CES_INIT, CES_WAIT, CES_START, 
							  CES_SEND_WRITE, CES_SEND_WRITE1, CES_SEND_WRITE2,
							  CES_SEND_ONES, CES_SEND_ONES1, CES_SEND_ONES2,
-- added dw							  
							  CES_SEND_IOCON, CES_SEND_IOCON1, CES_SEND_IOCON2, CES_SEND_IOCON3, CES_SEND_IOCON4,
							  CES_SEND_CONDAT, CES_SEND_CONDAT1, CES_SEND_CONDAT2,
--
							  CES_READ, CES_READ1, CES_READ2,
							  CES_READ3, CES_READ4, CES_READ5, CES_READ6, CES_READ7);
	signal CESState, CESNextState : STATE_TYPE := CES_INIT;
	
	type SHIFT_COUNT_TYPE is (SHIFTCOUNT_NOP, SHIFTCOUNT_LOAD, SHIFTCOUNT_DEC);
	signal ShiftCountCmd : SHIFT_COUNT_TYPE := SHIFTCOUNT_NOP;
	
	type SHIFTER_CMD_TYPE is (SHIFTER_NOP, 
									  SHIFTER_SEND_WRITE_IOCONA, SHIFTER_SEND_WRITE_IOCONB,
									  SHIFTER_SEND_WRITE_GPPUA,
									  SHIFTER_SEND_ALL_ONES, SHIFTER_SEND_READ_CMD,
									  SHIFTER_SHIFT_LEFT);
	signal ShifterCmd		: SHIFTER_CMD_TYPE := SHIFTER_NOP;
	
	type INPUT_SELECT_TYPE is (WR_GPPUA, ALL_ONES,READ_CMD);
	signal ShifterInputSelect	: INPUT_SELECT_TYPE;
	
begin

-- The chip will default to all 16 bits as input - no problem
-- We need to initialize the pullup resistors with registers x"0C" & x"0D"
-- Then just continually read registers x"12" and x"13"
-- GPIOA will shift out first, followed by GPIOB.
-- The bits within each byte are reversed for the convenience of PCB layout.
-- See below where this is fixed up
-- The chip defaults to sequential operation so the address increments
-- The write operation to set up the resistors is
-- <01000000><00001100><11111111><11111111>
-- The read operation to get the switches is
-- <01000001><00010010><xxxxxxxx><xxxxxxxx>
--
-- Substitute 1's for x's and we have 2 things to send as 16 bit words
-- <01000000><00001100><11111111><11111111>
-- <01000001><00010010><11111111><11111111>


---
--- Extra Code needed to control two chips on same port
---

---
--- The first byte needs to contain the address so if second chip is address 1 we need
--- to use 
--- <01000011> for a read
--- <01000010> for a write
--
-- In addition we need to write to the iocon.haen bit which is address "A" and "B" so
--
-- <01000000><00001000>
---

	CES_MOSI			<= Shifter(15);
	
	process(Clk, DelayCount)
	begin
		if rising_edge(Clk) then
			if DelayCount /= 0 then
				DelayCount <= DelayCount - 1;
			end if;
		end if;
	end process;
	
	process(Clk, ShifterCmd, CES_MISO)
	begin
		if rising_edge(Clk) then
			case ShifterCmd is
				when SHIFTER_NOP					=> null;
				when SHIFTER_SEND_WRITE_IOCONA => Shifter <= x"400A";
				when SHIFTER_SEND_WRITE_IOCONB => Shifter <= x"0808";
				when SHIFTER_SEND_WRITE_GPPUA	=> Shifter <= x"400C";
				when SHIFTER_SEND_ALL_ONES		=> Shifter <= x"FFFF";
			-- test different address
		   --	when SHIFTER_SEND_READ_CMD		=> Shifter <= x"4112"; --- Address '000'
			   when SHIFTER_SEND_READ_CMD		=> 
				   If Chip = '0' then
						Shifter <= x"4112"; --- Address '000'
					else
                  Shifter <= x"4312"; --- Address '001'
               end if;						
				when SHIFTER_SHIFT_LEFT			=> Shifter <= Shifter(14 downto 0) & CES_MISO;
				when others							=> null;
			end case;
		end if;
	end process;
	
	process(Clk, CESSelectCmd)
	begin
		if rising_edge(Clk) then
			case CESSelectCmd is
				when CES_NOP		=> null;
				when CES_SELECT	=> CES_SELn <= '0';
				when CES_RELEASE	=> CES_SELn <= '1';
				when others			=> null;
			end case;
		end if;
	end process;

	process(Clk, ShiftCountCmd, ShiftCount)
	begin
		if rising_edge(Clk) then
			case ShiftCountCmd is
				when SHIFTCOUNT_NOP	=> null;
				when SHIFTCOUNT_LOAD	=> ShiftCount <= x"f";
				when SHIFTCOUNT_DEC	=> ShiftCount <= ShiftCount - 1;
				when others				=> null;
			end case;
		end if;
	end process;
	
	process(Clk, LoadSwitches, Shifter)
	begin
		if rising_edge(Clk) then
			if LoadSwitches = '1' then
			  if Chip = '0' then
				Switches( 0) <= Shifter( 7);
				Switches( 1) <= Shifter( 6);
				Switches( 2) <= Shifter( 5);
				Switches( 3) <= Shifter( 4);
				Switches( 4) <= Shifter( 3);
				Switches( 5) <= Shifter( 2);
				Switches( 6) <= Shifter( 1);
				Switches( 7) <= Shifter( 0);
				Switches( 8) <= Shifter(15);
				Switches( 9) <= Shifter(14);
				Switches(10) <= Shifter(13);
				Switches(11) <= Shifter(12);
				Switches(12) <= Shifter(11);
				Switches(13) <= Shifter(10);
				Switches(14) <= Shifter( 9);
				Switches(15) <= Shifter( 8);
				Chip <= '1';
			else
				Switches(16) <= Shifter( 7);
				Switches(17) <= Shifter( 6);
				Switches(18) <= Shifter( 5);
				Switches(19) <= Shifter( 4);
				Switches(20) <= Shifter( 3);
				Switches(21) <= Shifter( 2);
				Switches(22) <= Shifter( 1);
				Switches(23) <= Shifter( 0);
				Switches(24) <= Shifter(15);
				Switches(25) <= Shifter(14);
				Switches(26) <= Shifter(13);
				Switches(27) <= Shifter(12);
				Switches(28) <= Shifter(11);
				Switches(29) <= Shifter(10);
				Switches(30) <= Shifter( 9);
				Switches(31) <= Shifter( 8);
				chip <= '0';
			end if;
			end if;
		end if;
	end process;
	
	process(Clk, CESNextState)
	begin
		if rising_edge(Clk) then
			CESState	<= CESNextState;
		end if;
	end process;
	
	process(CESState, ShiftCount, DelayCount)
	begin
		CES_SCK				<= '0';
		CESSelectCmd		<= CES_NOP;
		LoadSwitches		<= '0';
		ShiftCountCmd		<= SHIFTCOUNT_NOP;
		ShifterCmd			<= SHIFTER_NOP;
		case CESState is
			when CES_INIT			=> CESNextState				<= CES_WAIT;
			
			when CES_WAIT			=> if DelayCount = 0 then
												CESNextState			<= CES_START;
											else
												CESNextState			<= CES_WAIT;
											end if;
											
			when CES_START			=> ShifterCmd					<= SHIFTER_SEND_WRITE_GPPUA;
											ShiftCountCmd				<= SHIFTCOUNT_LOAD;
											CESSelectCmd				<= CES_SELECT;
											CESNextState				<= CES_SEND_WRITE;
											
			when CES_SEND_WRITE	=> CESNextState				<= CES_SEND_WRITE1;
			
			when CES_SEND_WRITE1	=>	CES_SCK						<= '1';	-- set clock
											CESNextState				<= CES_SEND_WRITE2;
											
			when CES_SEND_WRITE2	=> if ShiftCount = 0 then
												ShifterCmd				<= SHIFTER_SEND_ALL_ONES;
												ShiftCountCmd			<= SHIFTCOUNT_LOAD;
												CESNextState			<= CES_SEND_ONES;
											else
												ShifterCmd				<= SHIFTER_SHIFT_LEFT;
												ShiftCountCmd			<= SHIFTCOUNT_DEC;
												CESNextState			<= CES_SEND_WRITE;
											end if;
											
			when CES_SEND_ONES	=>	CESNextState				<= CES_SEND_ONES1;
			
			when CES_SEND_ONES1	=>	CES_SCK						<= '1';
											CESNextState				<= CES_SEND_ONES2;
											
			when CES_SEND_ONES2	=>	if ShiftCount = 0 then
												CESSelectCmd			<= CES_RELEASE;
												CESNextState			<= CES_SEND_IOCON; --CES_SEND_IOCON; -- was CES_READ;
											else
												ShifterCmd				<= SHIFTER_SHIFT_LEFT;
												ShiftCountCmd			<= SHIFTCOUNT_DEC;
												CESNextState			<= CES_SEND_ONES;
											end if;
											
--
-- If things have gone well at this point we have configured all MCP devices as input, with pull-ups.
-- we now need to configure them to honour addresses by sending X"400A" X"0404" 
--
			when CES_SEND_IOCON	=> ShifterCmd			<= SHIFTER_SEND_WRITE_IOCONA;
											ShiftCountCmd				<= SHIFTCOUNT_LOAD;
											CESNextState				<= CES_SEND_IOCON1;
						
			when CES_SEND_IOCON1	=> CESNextState				<= CES_SEND_IOCON2;
											CESSelectCmd				<= CES_SELECT;
											
			when CES_SEND_IOCON2	=> CESNextState				<= CES_SEND_IOCON3;
			
			when CES_SEND_IOCON3	=>	CES_SCK						<= '1';	-- set clock
											CESNextState				<= CES_SEND_IOCON4;
											
			when CES_SEND_IOCON4 => if ShiftCount = 0 then
												ShifterCmd				<= SHIFTER_SEND_WRITE_IOCONB;
												ShiftCountCmd			<= SHIFTCOUNT_LOAD;
												CESNextState			<= CES_SEND_CONDAT;
											else
												ShifterCmd				<= SHIFTER_SHIFT_LEFT;
												ShiftCountCmd			<= SHIFTCOUNT_DEC;
												CESNextState			<= CES_SEND_IOCON2;
											end if;
											
			when CES_SEND_CONDAT	=>	CESNextState				<= CES_SEND_CONDAT1;
			
			when CES_SEND_CONDAT1	=>	CES_SCK						<= '1';
											CESNextState				<= CES_SEND_CONDAT2;
											
			when CES_SEND_CONDAT2	=>	if ShiftCount = 0 then
												CESSelectCmd			<= CES_RELEASE;
												CESNextState			<= CES_READ;
											else
												ShifterCmd				<= SHIFTER_SHIFT_LEFT;
												ShiftCountCmd			<= SHIFTCOUNT_DEC;
												CESNextState			<= CES_SEND_CONDAT;
											end if;

--- end of mod
			when CES_READ			=>	ShifterCmd					<= SHIFTER_SEND_READ_CMD;
											ShiftCountCmd				<= SHIFTCOUNT_LOAD;
											CESNextState				<= CES_READ1;
											
			when CES_READ1			=> CESSelectCmd				<= CES_SELECT;
											CESNextState				<= CES_READ2;
											
			when CES_READ2			=> CESNextState				<= CES_READ3;
			
			when CES_READ3			=> CES_SCK						<= '1';
											CESNextState				<= CES_READ4;
											
			when CES_READ4			=> if ShiftCount = 0 then
												ShifterCmd				<= SHIFTER_SEND_ALL_ONES;
												ShiftCountCmd			<= SHIFTCOUNT_LOAD;
												CESNextState			<= CES_READ5;
											else
												ShifterCmd				<= SHIFTER_SHIFT_LEFT;
												ShiftCountCmd			<= SHIFTCOUNT_DEC;
												CESNextState			<= CES_READ1;
											end if;
											
			when CES_READ5			=> CESNextState				<= CES_READ6;
			
			when CES_READ6			=> CES_SCK						<= '1';
											ShifterCmd					<= SHIFTER_SHIFT_LEFT;
											CESNextState				<= CES_READ7;
											
			when CES_READ7			=>	if Shiftcount = 0 then
												CESSelectCmd			<= CES_RELEASE;
												LoadSwitches			<= '1';
												CESNextState			<= CES_READ;
											else
												ShiftCountCmd			<= SHIFTCOUNT_DEC;
												CESNextState			<= CES_READ5;
											end if;
											
			when others				=> CESNextState				<= CES_INIT;
		end case;
	end process;
	
end Behavioral;

