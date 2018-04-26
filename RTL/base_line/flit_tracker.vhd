--copyright (C) 2016 Siavoosh Payandeh Azad
-- 
-- This module Monitors the links status along side with the valid data value
-- in case there is a valid flit on the link, the module produces a log entery
-- in the tracker_file location. 
--

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use IEEE.NUMERIC_STD.all;
 use ieee.std_logic_misc.all;

entity flit_tracker is
    generic (
        DATA_WIDTH: integer := 32;
        tracker_file: string :="track.txt"
    );
    port (
    	clk: in std_logic;
        RX: in std_logic_vector (DATA_WIDTH-1 downto 0); 
        valid_in : in std_logic
    );
end;

architecture behavior of flit_tracker is
begin
process(clk)
	variable source_id, destination_id, Packet_length, packet_id, Mem_address1, Mem_address2, opcode: integer;
 	variable xor_check : std_logic;
 	variable body_flit_number : integer := 0;

 	-- file handeling 
 	file trace_file : text is out tracker_file;
 	variable LINEVARIABLE : line;

	begin
		Packet_length := 0;
		destination_id := 0;
		source_id := 0;
		Mem_address1 := 0;
		Mem_address2 := 0;
		opcode := 0;
		packet_id := 0;
		body_flit_number := 1;
		if clk'event and clk = '1' then 	-- checks the link status on the rising edge of the clock!
			if unsigned(RX) /= to_unsigned(0, RX'length) and valid_in = '1' then
				if RX(DATA_WIDTH-1 downto DATA_WIDTH-3) = "001" then -- header received!
					

		            destination_id := to_integer(unsigned(RX(20 downto 13)));
		            source_id := to_integer(unsigned(RX(28 downto 21)));
		            Mem_address1 := to_integer(unsigned(RX(12 downto 1)));
		            
		            xor_check :=  XOR_REDUCE(RX(DATA_WIDTH-1 downto 1));
		            if xor_check = RX(0) then	-- the flit is healthy
		            	write(LINEVARIABLE, "H flit at " & time'image(now) & " From " & integer'image(source_id) & " to " & integer'image(destination_id) & " with Mem_address1: " & integer'image(Mem_address1);
		            else
		            	write(LINEVARIABLE, "H flit at " & time'image(now) & " From " & integer'image(source_id) & " to " & integer'image(destination_id) & " with Mem_address1: " & integer'image(Mem_address1) & " FAULTY ");
		            end if;
					writeline(trace_file, LINEVARIABLE);
				elsif RX(DATA_WIDTH-1 downto DATA_WIDTH-3) = "010" then 
					xor_check :=  XOR_REDUCE(RX(DATA_WIDTH-1 downto 1));

					
					if body_flit_number = 1 then
						Mem_address2 := to_integer(unsigned(RX(28 downto 9)));
						opcode := to_integer(unsigned(RX(5 downto 1)));
						if xor_check = RX(0) then -- the flit is healthy
						write(LINEVARIABLE, "B flit at " & time'image(now)& " Mem_address2 " & integer'image(Mem_address2) &  " opcode " & integer'image(opcode));
						else
							write(LINEVARIABLE, "B flit at " & time'image(now) & " FAULTY ");
						end if;
					end if;
		            

					if body_flit_number = 2 then
						packet_id := to_integer(unsigned(RX(14 downto 1)));
						Packet_length := to_integer(unsigned(RX(28 downto 15)));
						if xor_check = RX(0) then -- the flit is healthy
						write(LINEVARIABLE, "B flit at " & time'image(now)& " packet_id " & integer'image(packet_id) &  " Packet_length " & integer'image(Packet_length));
						else
							write(LINEVARIABLE, "B flit at " & time'image(now) & " FAULTY ");
						end if;
					end if;

					writeline(trace_file, LINEVARIABLE);
					body_flit_number := body_flit_number +1;
				elsif RX(DATA_WIDTH-1 downto DATA_WIDTH-3) = "100" then 
					xor_check :=  XOR_REDUCE(RX(DATA_WIDTH-1 downto 1));
					max_latency := to_integer(unsigned(RX(14 downto 1)));
					max_router := to_integer(unsigned(RX(28 downto 15)));
		            if xor_check = RX(0) then -- the flit is healthy
						write(LINEVARIABLE, "T flit at " & time'image(now)& " router id " & integer'image(max_router)& " max_latency " & integer'image(max_latency));
					else
						write(LINEVARIABLE, "T flit at " & time'image(now) & " router id " & integer'image(max_router)& " packet_id " & integer'image(packet_id)& " FAULTY ");
					end if;
					writeline(trace_file, LINEVARIABLE);
				end if;
			end if; 
		end if;
end process;

end;
