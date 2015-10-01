--
-- Extremeley Small Scale Experimental Machine (ESSEM) or "Baby Baby"
--
--
-- A VHDL FPGA emulation of the Manchester Small Scale Experimental Machine (SSEM) or "Baby"
--
-- The emulation runs at the same clock speed as the Replica "Baby" currently in the Museum of Science and Industry in Manchester
-- This means programs should run at the same speed as Baby and the the Test programs and Program loader work
--
-- However it uses a 32 bit parallel CPU so its not 100% accurate internbally
-- 
--
--
--
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ssem is
  port(clk50_in  : in std_logic;
       red_out   : out std_logic;
       green_out : out STD_LOGIC_VECTOR(3 DOWNTO 1);
       blue_out  : out std_logic;
       hs_out    : out std_logic;
       vs_out    : out std_logic;
--		 led7		  : out std_logic;
--		 led6		  : out std_logic;
--		 led5		  : out std_logic;
       halt_led  : out std_logic;
		 hooter	  : out std_logic;
		 sw0		  : in  std_logic;     -- run switch
		 KC        : in  std_logic;     -- single step
		 KCC	     : in  std_logic;     -- KCC - Clear CI,PI and Accumulator
		 KAC		  : in  std_logic;     -- KAC - Clear Accumulator
		 KSC       : in  std_logic;     -- KSC - Clear Store
		 disp_sw	  : in  std_logic_vector(2 downto 0); -- display switches
--		 led0		  : out std_logic;     -- run lamp
		 leds		  : out STD_LOGIC_VECTOR(7 DOWNTO 0);
		 sw7		  : in  std_logic;
		 sw6		  : in  std_logic;
		 pc_sync	  : out  std_logic; -- this is C4
	    pc_dash   : OUT STD_LOGIC;
--		 KMC		  : in std_logic; --	  LOC = "N17"; -- SW6
		 Load_button : in std_logic;
--
-- 7-segment display
--		 
		 led_anodes : Out std_logic_vector (3 downto 0);
		 led_segs   : out std_logic_vector (7 downto 0);
--
-- i/o expander for typewriter buttons
--
           MCP_T_CS : out  STD_LOGIC;
           MCP_T_CLK : out  STD_LOGIC;
           MCP_T_SI : out  STD_LOGIC;
           MCP_T_SO : in  STD_LOGIC;
--
-- i/o expander for other F-STAT, L-STAT, Write/erase and Auto/Manual sitches
--
           MCP_S_CS : out  STD_LOGIC;
           MCP_S_CLK : out  STD_LOGIC;
           MCP_S_SI : out  STD_LOGIC;
           MCP_S_SO : in  STD_LOGIC;
--
--
-- PC Interface

		 store_read : out std_logic;
		 PC_Write   : in std_logic;     -- input being received
		 PC_Data    : in std_logic;     -- data byte
       PC_BUSY   : out std_logic); --    LOC = "K13";);
end ssem;


architecture Behavioral of ssem is

COMPONENT main
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

component mux 
    Port ( data_in : in  STD_LOGIC_VECTOR (31 downto 0);
           sel : in  STD_LOGIC_VECTOR (4 downto 0);
           data_out : out  STD_LOGIC);
end component;

component Debounce 
    Port ( Input	: in	STD_LOGIC;
           Clk		: in	STD_LOGIC;
           Output	: out	STD_LOGIC);
end component;

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
-- 
-- ROM holding sample programs
---
COMPONENT Programs
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------


--
-- Typewriter Switches and Clock for IO expanders
--
Signal T_Switches		:	STD_LOGIC_VECTOR (31 downto 0);
Signal S_Switches		:  STD_LOGIC_VECTOR (31 downto 0);
--
-- S_Switches are used as follows
--
-- F-Stat =      7,6,5
-- L-Stat =      0 to 4
-- Highlight =   8
-- KMC =         9
-- Write/Erase = 10
-- Man/Auto =    11


signal ClkDivider			: std_logic_vector(2 downto 0);


signal clk25              : std_logic;
signal clk_slow			  : std_logic;
signal horizontal_counter : std_logic_vector (9 downto 0);
signal vertical_counter   : std_logic_vector (9 downto 0);
signal wea                : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal addra              : STD_LOGIC_VECTOR(4 DOWNTO 0);
signal dina               : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal douta              : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal mux_out				  : std_logic;
signal mux_sel       	  : STD_LOGIC_VECTOR(4 downto 0);
signal web                : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal addrb              : STD_LOGIC_VECTOR(4 DOWNTO 0);
signal dinb               : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal doutb              : STD_LOGIC_VECTOR(31 DOWNTO 0);

--
-- signals for ROM
--

signal rom_addr           : STD_LOGIC_VECTOR(6 DOWNTO 0);
signal rom_dout           : STD_LOGIC_VECTOR(31 DOWNTO 0);

type   beat	 is 	(scan1, action1, scan2, action2);
signal current_beat       : beat  :=scan1;  --current and next state declaration.
signal next_beat          : beat  :=action1;  --current and next state declaration.	
signal dash					  : std_logic_vector (25 downto 0);
-- signal leds					  : std_logic_vector(3 downto 0);		
--
-- extra bits for cpu
--

signal l_stats            : STD_LOGIC_VECTOR(4 DOWNTO 0);
signal f_stats				  : STD_LOGIC_VECTOR(2 DOWNTO 0);
signal acc					  : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal CI					  : STD_LOGIC_VECTOR(31 DOWNTO 0) := "00000000000000000000000000000000" ; -- Program Counter
signal PI					  : STD_LOGIC_VECTOR(31 DOWNTO 0); -- Present Instruction
signal test					  : STD_LOGIC :='0';
signal run					  : STD_LOGIC :='0';
signal wr_store		     : STD_logic_vector (0 downto 0);
signal mux_in  			  : STD_LOGIC_VECTOR(31 DOWNTO 0); -- Present Instruction
--
-- VGA display
--
signal disp_line 			   :std_logic_vector (3 downto 0) := "0000"; -- Used to cvount groups of 12 lines
signal disp_addr				: STD_LOGIC_VECTOR (4 DOWNTO 0) := "00000"; -- used to address memory

--
-- Clock signals for the PC interface
--

signal dash_count	        : STD_Logic_vector (8 downto 0) := "000000000";  --- Counter for the dash
signal bo_count	        : STD_Logic_vector (5 downto 0) := "000000"; 		--- Counter for the black out
signal bo_clk			     : std_logic;
signal dash1 				  : std_logic := '0'; -- Dash signal for the PC
signal c_count            : STD_logic_vector  (4 downto 0) := "00000"; 		--  C-Counter
signal sel_count          : std_logic_vector (4 downto 0); -- Count bits out for PC interface
signal ha					  : STD_LOgic := '0';
signal hs					  : STD_logic := '1';
signal tfr_reg            : std_logic_vector (31 downto 0); -- => memory output
signal tfr_inp				  : std_logic_vector (31 downto 0); -- => memory input
signal data_rcvd			  : std_logic; -- data received from PC => write to store in next BO
--
-- CS switch logic (single step)
--

signal cs_sw : std_logic; -- cs switch pressed a single step
signal cs_done  : std_logic; -- single step complete
signal single_step : std_logic; -- single step in operation

--
-- halt/run logic
--

signal halted  : std_logic:='0'; -- Halt op-code executed - CS has not been pressed

begin
  
------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG

store : main
  PORT MAP (
    clka => clk25,
    wea => wea,
    addra => addra,
    dina => dina,
    douta => douta,
    clkb => clk25,
    web => web,
    addrb => addrb,
    dinb => dinb,
    doutb => doutb
  );
-- INST_TAG_END ------ End INSTANTIATION Template ------------
  
disp_mux : mux               -- Used to select bits for the VGA display
    Port map ( 
		data_in => mux_in,
       sel => mux_sel,
       data_out => mux_out);
		 
store_mux : mux               -- used to serialize the store for the PC interface
    Port map ( 
		data_in => tfr_reg,
       sel => sel_count,
       data_out => store_read);	 
		 
DB_CS : Debounce              -- used to de-bounce the Single Step (KC) key
    Port  map( 
	        Input => KC,
           Clk	=> clk25,
           Output	=> cs_sw);

Inst_CES1 : entity work.CES PORT MAP(
		Clk					=> ClkDivider(2),
		Switches				=> T_Switches,
		CES_SELn				=> MCP_T_CS,
		CES_MISO				=> MCP_T_SO,
		CES_MOSI				=> MCP_T_SI,
		CES_SCK				=> MCP_T_CLK
	);

Inst_CES2 : entity work.CES PORT MAP(
		Clk					=> ClkDivider(2),
		Switches				=> S_Switches,
		CES_SELn				=> MCP_S_CS,
		CES_MISO				=> MCP_S_SO,
		CES_MOSI				=> MCP_S_SI,
		CES_SCK				=> MCP_S_CLK
	);
	
ROM : Programs
  PORT MAP (
    clka => clk25,
    addra => rom_addr,
    douta => rom_dout
  );	
	
---
--- This bit of VHDL can be enabled (with changes to the UCF file) to allow the i/o expanders to be tested
---
-- Console Entry Switches
--	Process(clk)
--		begin
--	
--  	if rising_edge (ClkDivider(2)) then
--		   if sw6 = '1' then
--				if sw7 = '1' then
--					led <= MCP_switches (7 downto 0);
--				else
--					led <= MCP_switches (15 downto 8);
--				end if;
--			else
--				if sw7 = '1' then
--					led <= MCP_switches (23 downto 16);
--				else
--					led <= MCP_switches (31 downto 24);
--				end if;
--			end if;	
--		end if;
--		
--	end process;


--
-- generate a 25Mhz clock - used by the VGA
--
process (clk50_in)
begin
  wea <= "0";
  dina <= "00000000000000000000000000000000";
  if clk50_in'event and clk50_in='1' then
    if (clk25 = '0') then
      clk25 <= '1';
    else
      clk25 <= '0';
    end if;
  end if;
  PC_BUSY <= S_Switches(9);  -- KMC Key
end process;
--
-- clock for the i/o expanders
--
	process(Clk50_in)
	
	begin
		if Clk50_in'event and Clk50_IN = '1' then
			ClkDivider <= ClkDivider + 1;
		end if;
		
	if (sw7 = '1') then
--		leds <= S_Switches(7 downto 0);
	else
--	   leds <= S_Switches(15 downto 8); 
	end if;
	
	end process;

--
-- Generate the main SSEM clock signals
--

process(clk50_in,dash1, bo_clk,  HA)
begin
--
-- the PC interface expects a dash signal with 300ms on, 200ms off.
--
if clk50_in'event and clk50_in='1' then
    if (dash_count < "100101100") then  -- Less than 600
	  dash1 <= '0';
	  pc_dash <= '0';
	 else
	  dash1 <= '1';
	  pc_dash <= '1';
	 end if;
    if (dash_count < "1111101011") then
        dash_count <= Dash_count + "000000001";	 
	 else
        dash_count <= "000000000";
    end if;
end if;

--
-- Each beat is 36 dash pulses. 
--
-- On the replica SSEM the The first 32 are used to clock data through the machine
-- and the other four allow time for the store beams to retrace.
--
-- In this emulation the first 32 are used to clock data in and out of the PC interface
-- The "CPU" works in parallel so only needs one pulse to operate.
-- The four in the blackout phase are used as to manage storing the data back to memory
--

if dash1'event and dash1='1' then
    
	 sel_count <= bo_count (4 downto 0);
--
-- Generate the Black Out waveform and clock the data in/out from the PC
--
	 if (bo_count < "100000") then  -- Netween 0 and 31
	   bo_clk <= '1';
	   clk_slow <= '1';
--
--  if button three (KSC) is pressed clear the store
--- top do this we pretend data has arrived from the PC
--
      if ( KSC = '1' ) then
		      data_rcvd <= '1';
		end if;
--
-- sort out the input from the typewriter buttons => fake a read from the PC
--
      if((current_beat = scan1) OR (current_beat = scan2)) then
			if( (NOT (T_Switches = X"FFFFFFFF")) and  ( (c_count - "00001")  = (NOT  S_Switches(4 downto 0)) ) )  Then
				if ( S_Switches(10) = '1' ) then
						tfr_inp <= doutb OR (NOT T_Switches);
				else
						tfr_inp <= doutb AND (T_Switches);
				end if;					
				data_rcvd <= '1';
			end if;	
		end if;		
--
-- Load from ROM => again a read from the PC
--
      if((current_beat = scan1)  OR (current_beat = scan2))then
			if( Load_button = '1' )  Then
				tfr_inp <= rom_dout;
				data_rcvd <= '1';
				leds(4 downto 0) <= "11111";
			end if;	
		end if;				
		
--
-- If the PC interface is sending data store it in the appropriate bit of "tfr_inp"
-- Along with any bits from the typewriter buttons
--
      if ( pc_write = '1' ) then -- data received from PC
			  data_rcvd <= pc_write; -- flag it
	   case  bo_count(4 downto 0) is
            when "00000" =>
                tfr_inp(0) <= pc_data; 
				when "00001" =>
                tfr_inp(1) <= pc_data;
				when "00010" =>
                tfr_inp(2) <= pc_data;  
				when "00011" =>
                tfr_inp(3)  <= pc_data; 
				when "00100" =>
                tfr_inp(4)  <= pc_data; 
				when "00101" =>
                tfr_inp(5)  <= pc_data; 
				when "00110" =>
                tfr_inp(6)  <= pc_data;
			   when "00111" =>
                tfr_inp(7)  <= pc_data;
				when "01000" =>
                tfr_inp(8) <= pc_data ;
				when "01001" =>
                tfr_inp(9) <= pc_data ;
				when "01010" =>
                tfr_inp(10) <= pc_data  ;
				when "01011" =>
                tfr_inp(11)  <= pc_data ;
				when "01100" =>
                tfr_inp(12) <= pc_data  ;
				when "01101" =>
                tfr_inp(13)  <= pc_data ;
				when "01110" =>
                tfr_inp(14)  <= pc_data ;
				when "01111" =>
                tfr_inp(15)  <= pc_data ;
				when "10000" =>
                tfr_inp(16)  <= pc_data ;
				when "10001" =>
                tfr_inp(17)  <= pc_data ;
				when "10010" =>
                tfr_inp(18) <= pc_data  ;
				when "10011" =>
                tfr_inp(19) <= pc_data  ;
				when "10100" =>
                tfr_inp(20)  <= pc_data ;
				when "10101" =>
                tfr_inp(21)  <= pc_data ;
				when "10110" =>
                tfr_inp(22) <= pc_data  ;
				when "10111" =>
                tfr_inp(23)  <= pc_data ;
				when "11000" =>
                tfr_inp(24)  <= pc_data ;
				when "11001" =>
                tfr_inp(25)  <= pc_data ;
				when "11010" =>
                tfr_inp(26)  <= pc_data ;
				when "11011" =>
                tfr_inp(27)  <= pc_data ;
				when "11100" =>
                tfr_inp(28)  <= pc_data ;
				when "11101" =>
                tfr_inp(29)  <= pc_data ;
				when "11110" =>
                tfr_inp(30)  <= pc_data ;
				when "11111" =>
					tfr_inp(31)  <= pc_data ;
				when others =>
			end case;
			end if;		
	 else	   ------- Counts 32-35 are the blackout period
	   bo_clk <= '0';
      clk_slow <= '0';
	 end if;
---	 
    if (bo_count < "100011") then  -- count 0 to 35
        bo_count <= bo_count + "000001";	 
	 else
        bo_count <= "000000";
    end if;
---	 
    if (bo_count = "100000") then  -- count 32. If we need to write to store put the data on the input lines
	    if(wr_store = "1") then     -- The SSEM has executed a store so we need to save the accumulator
			dinb <= ACC;                   
--			web <= "1";
       elsif (	data_rcvd = '1' ) then -- Data has arrived from the PC or the KSC swicth has been pressed.
		   dinb <= tfr_inp;
   	 else
		    web <= "0";
--		 elsif (data_rcvd = '1') then
--         dinb <= tfr_inp;		 
		 end if;	
	 end if;	 

	 if (bo_count = "100001") then -- BO count = 33 - Wriet enable the RAM if necessary
--	   if ( (web = "1") or (data_rcvd = '1') ) then
--			web <= "1";          -- write to store
--		else
--       web <= "0";	 
--			data_rcvd <= '0';
--		end if;	
      if wr_store = "1" then
			web <= wr_store;
		elsif data_rcvd = '1' then
		   web <= "1";
		elsif KSC = '1' then
         web <= "1";		
		end if;
	 end if;	

--	 
	 
	 if (bo_count = "100010") then -- Dash 34 set address for read 	
      web <= "0";                 -- disable the write line
		data_rcvd <= '0';           -- clar the data received flag
	  	if (next_beat = action1) then  -- the next beat is an action1 beat read an instruction
  			addrb <= CI (4 downto 0);
      elsif (next_beat = action2) then -- the next beat is an action2 beat -- read data
  			addrb <= l_stats;
		else
         addrb <= c_count - "00001";	-- the next beat is a scan beat scan memory using the "C" counters.
			rom_addr(4 downto 0) <= c_count - "00001";  -- also set the rom address
			rom_addr (6) <= sw7;
			rom_addr (5) <= sw6;
		end if;
		
	 elsif (bo_count = "100011" ) then -- Dash 35 - clean up the PC interface flags for the next scan
	
      tfr_reg <= doutb;
		tfr_inp <= "00000000000000000000000000000000";
		web <= "0";
	 end if;		 
end if;

--
-- the BO signal is halved to generate HA and HS
--

if bo_clk'event and bo_clk='0' then
    if ha = '1' then
	     ha <= '0';
	     hs <= '1';
	 else
	     ha <= '1';
		  hs <= '0';
	end if;		  
end if;

--
-- AND a Line Counter
--

if ha'event and ha='1' then          -- just try this
    c_count <= c_count + "00001";
	 pc_sync <= c_count(4);
	 if ((sw0 = '1') AND (halted = '1')) then
		hooter <= c_count(1);
	 end if;
end if;


end process;
	 
process(clk_slow )
begin

if (falling_edge(clk_slow)) then
--
-- this is the start of the black out period
--
  current_beat <= next_beat;   --state change.
--  web <= wr_store;
    halt_led <= halted;
  if (next_beat = scan1) then
      run <= sw0;
    	if (cs_sw = '0') then
          single_step <= '0';
          cs_done <= '0';			 
		elsif (cs_sw = '1' ) then
		   if (cs_done = '0') then
			 	 single_step <= '1';
				 cs_done <= '1';
			else
				single_step <= '0';
			end if;	 
		end if;
  end if;
--  if (next_beat = action1) then
--			addrb <= CI;
--  elsif (next_beat = action2) then
--			addrb <= l_stats;
--  else
--			addrb <= c_count;
--  end if;
end if;

end process;

process(clk_slow)
begin

if (rising_edge(clk_slow)) then

--
-- This is then end of the Black Out period. 
--

case current_beat is
-------------
-- SCAN1
-------------
     when scan1 =>        --when current state is "s0"
     wr_store <= "0";
--	  leds <= "0001";
	  next_beat <= action1;

--
-- increment the CI and store in the LSTATS
--	  
	  if( ( (run = '1') and (halted = '0') ) or (Single_step = '1') )then
	  	   if (single_step = '1') then
	         halted <= '0';
--			   led0 <= '0';
	      end if;
			if(test = '1')then
			   CI <= CI + "00000000000000000000000000000010";
				test <= '0';
			else
			   CI <= CI + "00000000000000000000000000000001";
			end if;
	  end if;
--------------
-- Action 1
-------------	  
	  when action1 =>
--	  leds <= "0010";
	  next_beat <= scan2;
--
-- Get the next instruction and put in PI
--
	  if( ( (run = '1') and (halted = '0') ) or (Single_step = '1') ) then
			PI <= doutb;
	  end if;
--------------
-- Scan 2
--------------
	  when scan2 =>        --when current state is "s0"
--	  leds <= "0100";
	  next_beat <= action2;
	  if(((run = '1') and (halted = '0')) or (Single_step = '1'))then
	    if ( S_Switches(11) = '1' )then -- Manual Auto switch in manual
		 	L_STATS <= NOT S_Switches(4 downto 0);
--			leds(4 downto 0) <= NOT S_Switches(4 downto 0);
--
			F_STATS(0) <= NOT S_Switches(7);
			F_STATS(1) <= NOT S_Switches(6);
			F_STATS(2) <= NOT S_Switches(5);
			leds(5) <= NOT S_Switches(7);
			leds(6) <= NOT S_Switches(6);
			leds(7) <= NOT S_Switches(5);
		else	
			L_STATS(0) <= PI(0);
			L_STATS(1) <= PI(1);
			L_STATS(2) <= PI(2);
			L_STATS(3) <= PI(3);
			L_STATS(4) <= PI(4);
--
			F_STATS(0) <= PI(13);
			F_STATS(1) <= PI(14);
			F_STATS(2) <= PI(15);
		end if;	
--
						
	  end if;
	  
--------------	  
-- Action 2
--------------
	  when action2 =>
--	  leds <= "1000";
	  next_beat <= scan1;
--	      led7 <= f_stats(2);
--			led6 <= f_stats(1);
--			led5 <= f_stats(0);
	  if( ( (run = '1') and (halted = '0') ) or (Single_step = '1') )then
			case F_STATS is
				when "000" =>
				--
				-- JMP
				--
					CI <= doutb;
				when "001" =>
					CI <= CI + doutb ;
				when "010" =>
				   ACC <= "00000000000000000000000000000000" - doutb ;
				when "011" =>
--					DINB <= ACC;
					wr_store <= "1";
				when "100" =>
				   ACC <= ACC - doutb;
				when "101" =>
				   ACC <= ACC - doutb;
				when "110" =>
				   TEST <= ACC(31);
	         when "111" =>
				  halted <= '1';
--  			  halt_led <= '1';
				null;
				when others =>
					null;
    			end case;
	  end if;
--
--  clear ACC, PI and CI as necessary
--
	  if KAC = '1' Then
	         ACC <= "00000000000000000000000000000000";
	  end if;			
	  if KCC = '1' Then
	         ACC <= "00000000000000000000000000000000";
				PI  <= "00000000000000000000000000000000";
				CI  <= "00000000000000000000000000000000";
	  end if;			
end case;
end if;
end process;

--
-- generate VGA display
--

process (clk25) 
begin
  if clk25'event and clk25 = '1' then    --- Level 1
    blue_out <= '0';
	 red_out <= '0';
--	 green_out <= "000";
	 --
	 -- This bit displays the memory
	 --
	 --
	 -- Is the scan line horizontally on the visible portion of the screen
	 --
	 --
	 -- set the MUX inputs at the start of the scan line
	 --
	 if (horizontal_counter = "0011001000" ) then
	 	if (vertical_counter <=  "110110110" ) then -- 110110110
--                              9876543210
--										  0000110000
		case disp_sw is
		when "001" =>  -- Display CI (Program Counter)
		  if (run = '1') and (disp_addr(0) = '0') then
				mux_in <= PI;
		  else
				mux_in <= CI;
		 end if;
		when "010" =>  -- Display Accumulator
 		  mux_in <= ACC;
		when others =>  -- Display Store
-- 	     addra <= vertical_counter(8 downto 4) - "00000";
		  mux_in <= douta;
		end case;  
		end if;
	 end if;	
	 
    if (horizontal_counter >= "0011010000" ) -- 144 Level 2 (was 0100010000)
    and (horizontal_counter <= "0011010000" + "0111111110" ) Then -- 784  
	 --                          9876543210 
	 --
	 -- and are we within the range of lines we want to use for the memory display
	 --	 
		if                                             -- level 3
		(vertical_counter >=  "000111100" ) -- 64
		and (vertical_counter <=  "000111100" + "110000000") -- 519 -- 110000000
		and (disp_line(3 downto 1) = "100")
		then
		--
		-- yes - display the memory along the line
	  
	     mux_sel <= horizontal_counter(8 downto 4) - "01101";
		  --
		  -- Always display a dot at the start of each bit
		  --
	     if (horizontal_counter(3 downto 1) = "000")	-- level 4
		  then
				green_out(1) <= '0';
				green_out(2) <= '1';
				green_out(3) <= '1';
		  --
		  -- Then a short dash if the RAM is a "1" bit
		  --
		  else if (horizontal_counter(3 downto 2) < "11") and (mux_out = '1') 
				then 
					green_out <= "111";
		  --
        -- high light the current instruction
        --		  
		  else if (disp_sw = "100" or disp_sw = "000") AND 
						( ( (S_Switches(11) = '0') and  (addra = CI( 4 downto 0))) 
				  or  ( (S_Switches(11) = '1') and  (addra = NOT S_Switches(4 downto 0))))  then
		   
		         green_out <= "010";
		  else
		         green_out <= "000";
		  end if; -- end of Horizontal counter for memory display -- end L4
		 --
		 -- now display PI & AC
		 --
		end if; -- end L3
		--
		-- end of memory display
		--
		end if;
    end if;	
    else
		green_out <= "000";
	 end if;
--	 
	 if (horizontal_counter > "0000000000" )
      and (horizontal_counter < "0001100001" ) -- 96+1
    then
      hs_out <= '0';
    else
      hs_out <= '1';
    end if;  -- line sync
 --   
	 if (vertical_counter > "0000000000" )
      and (vertical_counter < "0000000011" ) -- 2+1
    then
      vs_out <= '0';
    else
      vs_out <= '1';
    end if; -- vsync
--  

    horizontal_counter <= horizontal_counter+"0000000001";
    if (horizontal_counter="1100100000") then
      vertical_counter <= vertical_counter+"0000000001";
--- count every 12 lines for the display
      --if Vertical_counter > "0000000100" then
			disp_line <= disp_line + 1;
		--end if;	
      horizontal_counter <= "0000000000";
    end if; -- end of hsync
--    
	 if (vertical_counter="1000001001") then		    
      vertical_counter <= "0000000000";
		disp_line <= "0000";
		disp_addr <= "00000";
    end if; -- end of vsync
--
    if disp_line = "1100" then
			disp_line <= "0000";
			disp_addr <= disp_addr + "00001";		
	 end if;	
  
    if disp_line = "0000" then
			addra <= disp_addr - "00101";
	 end if;

  end if;  --- clk event
  
end process;

---
-- dinky code to display "baby" in the 7-segment display
--

process(bo_count)
begin

Case Bo_count(1 downto 0) is
					when "00" =>
					   led_anodes <= "0111";
						led_segs   <=  "10000000";
					when "01" =>
                  led_anodes <= "1011";
						led_segs   <=  "10001000";
               When "10" =>
                  led_anodes <= "1101";
						led_segs   <=  "10000000";
					when "11" =>
					   led_anodes <= "1110";
						led_segs   <=  "10011001";
						--              pgfedcba
						--              10011010 
					when others =>
					   null;
					end case;
end process;

end Behavioral;
