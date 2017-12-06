-- cpu.vhd: Simple 8-bit CPU (BrainLove interpreter)
-- Copyright (C) 2017 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): DOPLNIT
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity cpu is
 port (
   CLK   : in std_logic;  -- hodinovy signal
   RESET : in std_logic;  -- asynchronni reset procesoru
   EN    : in std_logic;  -- povoleni cinnosti procesoru
 
   -- synchronni pamet ROM
   CODE_ADDR : out std_logic_vector(11 downto 0); -- adresa do pameti
   CODE_DATA : in std_logic_vector(7 downto 0);   -- CODE_DATA <- rom[CODE_ADDR] pokud CODE_EN='1'
   CODE_EN   : out std_logic;                     -- povoleni cinnosti
   
   -- synchronni pamet RAM
   DATA_ADDR  : out std_logic_vector(9 downto 0); -- adresa do pameti
   DATA_WDATA : out std_logic_vector(7 downto 0); -- mem[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
   DATA_RDATA : in std_logic_vector(7 downto 0);  -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
   DATA_RDWR  : out std_logic;                    -- cteni z pameti (DATA_RDWR='0') / zapis do pameti (DATA_RDWR='1')
   DATA_EN    : out std_logic;                    -- povoleni cinnosti
   
   -- vstupni port
   IN_DATA   : in std_logic_vector(7 downto 0);   -- IN_DATA obsahuje stisknuty znak klavesnice pokud IN_VLD='1' a IN_REQ='1'
   IN_VLD    : in std_logic;                      -- data platna pokud IN_VLD='1'
   IN_REQ    : out std_logic;                     -- pozadavek na vstup dat z klavesnice
   
   -- vystupni port
   OUT_DATA : out  std_logic_vector(7 downto 0);  -- zapisovana data
   OUT_BUSY : in std_logic;                       -- pokud OUT_BUSY='1', LCD je zaneprazdnen, nelze zapisovat,  OUT_WE musi byt '0'
   OUT_WE   : out std_logic                       -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
 );
end cpu;


-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of cpu is

	-- Program counter signals --
	signal pcVal: std_logic_vector(11 downto 0);
	signal pcInc: std_logic;
--	signal pc_dec: std_logic;
	signal pcValSet: std_logic;
	signal pcValLoopStart: std_logic_vector(11 downto 0);

	-- Pointer signals --
--	signal ptr_reg: std_logic_vector(9 downto 0);
--	signal ptr_inc: std_logic;
--	signal ptr_dec: std_logic;

	-- Instructions --
	type instructions_t is (
		INS_ptrInc,
		INS_ptrDec,
		INS_dataInc,
		INS_dataDec,
		INS_loopBegin,
		INS_loopEnd,
		INS_print,
		INS_read,
		INS_loopBreak,
		INS_end
	);
	signal instruction: instructions_t;

	-- FSM states ---
	type state_t is (
		FSM_end,
		FSM_fetch,
		FSM_decode,
		FSM_dataInc,
		FSM_dataDec,
		FSM_print,
		FSM_loopBegin,
		FSM_loopSkip,
		FSM_loopSkipWait,
		FSM_loopEnd
	);
	signal presentState: state_t;
	signal nextState: state_t;
	
begin
        

	-- Program counter --
	pc: process(RESET, CLK)
	begin
		CODE_ADDR <= pcVal;
                
		if RESET = '1' then
			pcVal <= (others => '0');

		elsif rising_edge(CLK)  then
			if pcInc = '1' then
				pcVal <= pcVal + 1;
			elsif pcValSet = '1' then
				pcVal <= pcValLoopStart;
			end if;
		end if;
	end process;

	-- Program counter --
	--ptr: process(RESET, CLK)
	--begin
	--if RESET = '1' then
	--ptr_reg <= (others=>'0');
	--
	--elsif rising_edge(CLK)  then
	--if ptr_inc = '1' and ptr_dec = '0' then
	--ptr_reg <= ptr_reg + 1;
	--elsif ptr_inc = '0' and ptr_dec = '1' then
	--ptr_reg <= ptr_reg - 1;
	--end if;
	--end if;
	--end process;


	-- Finite state machine update --
	updateState: process(CLK, EN)
	begin
		if RESET = '1' then
			presentState <= FSM_fetch;
		elsif rising_edge(CLK) and EN = '1' then
			presentState <= nextState;
		end if;
	end process;


	-- Finite state machine --
	finiteStateMachine: process(presentState, OUT_BUSY, DATA_RDATA, instruction)
	begin
		CODE_EN <= '0';
		DATA_EN <= '0';
		IN_REQ <= '0';
		OUT_WE <= '0';

		pcInc <= '0';
		pcValSet <= '0';

		nextState <= FSM_fetch;

		case presentState is
			-- Fetch Instruction (load on CODE_DATA) --
			when FSM_fetch =>
				nextState <= FSM_decode;			
				CODE_EN <= '1';
				
			-- Decode Instruction (determinate next action) --
			when FSM_decode =>
				case instruction is
					when INS_end =>
						nextState <= FSM_end;				
		
					when INS_dataInc =>
						DATA_EN <= '1';
						DATA_RDWR <= '0';
						nextState <= FSM_dataInc;
						
					when INS_dataDec =>
						DATA_EN <= '1';
						DATA_RDWR <= '0';
						nextState <= FSM_dataDec;	
											
					when INS_print =>
                        DATA_EN <= '1';
						DATA_RDWR <= '0';
						nextState <= FSM_print;
					
					when INS_loopBegin =>
						DATA_EN <= '1';
						DATA_RDWR <= '0';
						nextState <= FSM_loopBegin;			
						
					when INS_loopEnd =>
						DATA_EN <= '1';
						DATA_RDWR <= '0';
						nextState <= FSM_loopEnd;				

                                                
					when others => pcInc <= '1';
				end case;

			-- Data Incerement (symbol '+') --
			when FSM_dataInc =>
                pcInc <= '1';
                        
				DATA_EN <= '1';
				DATA_RDWR <= '1';
				DATA_WDATA <= DATA_RDATA + 1;
                                
				nextState <= FSM_fetch;
			
			-- Data Decerement (symbol '-') --
			when FSM_dataDec =>
                pcInc <= '1';
                        
                DATA_EN <= '1';   
                DATA_RDWR <= '1';     
				DATA_WDATA <= DATA_RDATA - 1;
                                
				nextState <= FSM_fetch;

			-- Character print (symbol '.') --
			when FSM_print =>
				if OUT_BUSY = '0' then
					pcInc <= '1';

					OUT_DATA <= DATA_RDATA;
					OUT_WE <= '1';

					nextState <= FSM_fetch;
				end if;

			-- Beginning of loop cycle (symbol '[') --
			when FSM_loopBegin =>
				pcInc <= '1';
				
				if DATA_RDATA = 0 then
					pcValLoopStart <= pcVal;
					nextState <= FSM_loopSkipWait;
				else
					nextState <= FSM_fetch;
				end if;
			
			-- Skipping instructions inside loop (while symbol ']' is found) --		
			when FSM_loopSkip =>
				if instruction = INS_loopEnd then
					nextState <= FSM_loopEnd;
				else
					pcInc <= '1';
					nextState <= FSM_loopSkipWait;
				end if;
				
			-- Loading instruction for skipping inside loop --	
			when FSM_loopSkipWait =>
				CODE_EN <= '1';
				nextState <= FSM_loopSkip;

			when FSM_loopEnd =>
				if DATA_RDATA = 0 then	-- End cycle
					pcInc <= '1';
					nextState <= FSM_fetch;
				else	-- Run cycle again
					pcValSet <= '1';
					nextState <= FSM_fetch;
				end if;
				
			when others =>
					nextState <= FSM_end;
		end case;   
	end process;

	-- Instruction decoder
	decoder: process(CODE_DATA)
	begin
		case CODE_DATA(7 downto 4) is
			when X"0" =>
				if CODE_DATA(3 downto 0) = X"0" then
					instruction <= INS_end;	-- null
				end if;

			when X"2" =>
				case CODE_DATA(3 downto 0) is
					when X"B" => instruction <= INS_dataInc;	-- +
					when X"D" => instruction <= INS_dataDec;	-- -
					when X"E" => instruction <= INS_print;	-- .
					when X"C" => instruction <= INS_read;	-- ,
					when others =>
				end case;

			when X"3" =>
				case CODE_DATA(3 downto 0) is
					when X"E" => instruction <= INS_ptrInc;	-- >
					when X"C" => instruction <= INS_ptrDec;	-- <
					when others =>
				end case;

			when X"5" =>
				case CODE_DATA(3 downto 0) is
					when X"B" => instruction <= INS_loopBegin;	-- [
					when X"D" => instruction <= INS_loopEnd;	-- ]
					when others =>
				end case;

			when X"7" =>
				if CODE_DATA(3 downto 0) = X"E" then
					instruction <= INS_loopBreak;	-- ~
				end if;

			when others =>
		end case;
	end process;

end behavioral;
 
