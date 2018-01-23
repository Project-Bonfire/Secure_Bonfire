--Copyright (C) 2018 Siavoosh Payandeh Azad and Behrad Niazmand

library ieee;
use ieee.std_logic_1164.all;

-- Is this like the old arbiter in the router with handshaking FC ??
entity arbiter_in is
    port (  reset: in  std_logic;
            clk: in  std_logic;
            Req_X_N, Req_X_E, Req_X_W, Req_X_S, Req_X_L:in std_logic; -- From LBDR modules
            credit_counter_N, credit_counter_E, credit_counter_W, credit_counter_S: in std_logic_vector (1 downto 0);
            X_N, X_E, X_W, X_S, X_L:out std_logic -- Grants given to LBDR requests (encoded as one-hot)
            );
end;

architecture behavior of arbiter_in is

 
 TYPE STATE_TYPE IS (IDLE, North, East, West, South, Local);
 TYPE DIRECTION is (N, E, W, S, Invalid);
 SIGNAL state, state_in   : STATE_TYPE := IDLE;
 SIGNAL Free_Slots_N, Free_Slots_E, Free_Slots_W, Free_Slots_S, Free_Slots_L : std_logic_vector(2 downto 0) := "000";
 SIGNAL dir: DIRECTION := N;

begin
process (clk, reset)begin
  if reset = '0' then
      state <= IDLE;
  elsif clk'event and clk ='1'then
      state <= state_in;
  end if;
end process;

-- anything below here is pure combinational

Free_Slots_N <= req_X_N & credit_counter_N;
Free_Slots_E <= req_X_E & credit_counter_E;
Free_Slots_W <= req_X_W & credit_counter_W;
Free_Slots_S <= req_X_S & credit_counter_S;
--Free_Slots_L <= req_X_L & credit_counter_L;


process (Free_Slots_N, Free_Slots_E, Free_Slots_W, Free_Slots_S)
	variable Max_Free_Slots : std_logic_vector (2 downto 0) := Free_Slots_N;
begin
	 dir <= N;
	 Max_Free_Slots := Free_Slots_N;

     if (Free_Slots_E > Max_Free_Slots) then 
        Max_Free_Slots := Free_Slots_E;
        dir <= E;
     end if;

     if (Free_Slots_W > Max_Free_Slots) then
        Max_Free_Slots := Free_Slots_W;
        dir <= W;        
     end if;

     if (Free_Slots_S > Max_Free_Slots) then
        Max_Free_Slots := Free_Slots_S;
        dir <= S;       
     end if;
     if req_X_N = '0' and req_X_E = '0' and req_X_W = '0' and req_X_S = '0' then 
     	dir <= Invalid;
     end if;
end process;

-- Selection function process
process(state, dir, req_X_N, req_X_E, req_X_W, req_X_S, req_X_L)
begin

	-- Initialize all as zero!
    X_N <= '0';
    X_E <= '0';
    X_W <= '0';
    X_S <= '0';
    X_L <= '0';
    
    case state is 
      when IDLE => -- In the arbiter for hand-shaking FC router, L had the  highest priority (L, N, E, W, S)
      			   -- Here it seems N has the higest priority, is it fine ? 
      	if req_X_L = '1' then
      		state_in <= Local;
			X_L <= '1';	   		         		     	
      	else
      		if dir = N then
	      		state_in <= North;
				X_N <= '1';	   		         		     	
      		elsif dir = E then
	      		state_in <= East;
				X_E <= '1';	   		         		     	
      		elsif dir = W then
	      		state_in <= West;
				X_W <= '1';	   		         		     	
			elsif dir = S then
	      		state_in <= South;
				X_S <= '1';	 
			else -- Invalid
				state_in <= IDLE;
      		end if;
      	end if;

      when North => 
      	 	X_N <= '1';
      		if  req_X_N = '0' then
      			X_N <= '0';
				if req_X_L = '1' then
		      		state_in <= Local;
					X_L <= '1';	   		         		     	
		      	else
		      		if dir = N then
			      		state_in <= North;
						X_N <= '1';	   		         		     	
		      		elsif dir = E then
			      		state_in <= East;
						X_E <= '1';	   		         		     	
		      		elsif dir = W then
			      		state_in <= West;
						X_W <= '1';	   		         		     	
					elsif dir = S then
			      		state_in <= South;
						X_S <= '1';	 
					else -- Invalid
						state_in <= IDLE;
		      		end if;
      			end if;
			else
				state_in <= state;	
      		end if;

      when East =>
      	X_E <= '1';	
      	if  req_X_E = '0' then
				X_E <= '0';
				if req_X_L = '1' then
		      		state_in <= Local;
					X_L <= '1';	   		         		     	
		      	else
		      		if dir = N then
			      		state_in <= North;
						X_N <= '1';	   		         		     	
		      		elsif dir = E then
			      		state_in <= East;
						X_E <= '1';	   		         		     	
		      		elsif dir = W then
			      		state_in <= West;
						X_W <= '1';	   		         		     	
					elsif dir = S then
			      		state_in <= South;
						X_S <= '1';	 
					else -- Invalid
						state_in <= IDLE;
		      		end if;
      			end if;
			else
				state_in <= state;
				
      		end if;

      when West =>
      	X_W <= '1';	
      	if  req_X_W = '0' then
				X_W <= '0';
				if req_X_L = '1' then
		      		state_in <= Local;
					X_L <= '1';	   		         		     	
		      	else
		      		if dir = N then
			      		state_in <= North;
						X_N <= '1';	   		         		     	
		      		elsif dir = E then
			      		state_in <= East;
						X_E <= '1';	   		         		     	
		      		elsif dir = W then
			      		state_in <= West;
						X_W <= '1';	   		         		     	
					elsif dir = S then
			      		state_in <= South;
						X_S <= '1';	 
					else -- Invalid
						state_in <= IDLE;
		      		end if;
      			end if;
			else
				state_in <= state;
				
      		end if;

      when South =>
      	X_S <= '1';	
      	if  req_X_S = '0' then
				X_S <= '0';
				if req_X_L = '1' then
		      		state_in <= Local;
					X_L <= '1';	   		         		     	
		      	else
		      		if dir = N then
			      		state_in <= North;
						X_N <= '1';	   		         		     	
		      		elsif dir = E then
			      		state_in <= East;
						X_E <= '1';	   		         		     	
		      		elsif dir = W then
			      		state_in <= West;
						X_W <= '1';	   		         		     	
					elsif dir = S then
			      		state_in <= South;
						X_S <= '1';	 
					else -- Invalid
						state_in <= IDLE;
		      		end if;
      			end if;
			else
				state_in <= state;
				
      		end if;

      when others => -- Includes local
      	X_L <= '1';	
      	if  req_X_L = '0' then
				X_L <= '0';
				if req_X_L = '1' then
		      		state_in <= Local;
					X_L <= '1';	   		         		     	
		      	else
		      		if dir = N then
			      		state_in <= North;
						X_N <= '1';	   		         		     	
		      		elsif dir = E then
			      		state_in <= East;
						X_E <= '1';	   		         		     	
		      		elsif dir = W then
			      		state_in <= West;
						X_W <= '1';	   		         		     	
					elsif dir = S then
			      		state_in <= South;
						X_S <= '1';	 
					else -- Invalid
						state_in <= IDLE;
		      		end if;
      			end if;
			else
				state_in <= state;
				
      		end if;
	    
    end case;
    
end process;
end;
