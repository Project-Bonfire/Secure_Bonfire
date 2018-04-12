--Copyright (C) 2016 Siavoosh Payandeh Azad Behrad Niazmand

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;

use work.router_pack.all;

entity allocator is
    generic (
        FIFO_DEPTH : integer := 4; -- FIFO counter size for read and write pointers would also be the same as FIFO depth, because of one-hot encoding of them!
        CREDIT_COUNTER_LENGTH : integer := 2;
        CREDIT_COUNTER_LENGTH_LOCAL : integer := 2
    );
    port (  reset: in  std_logic;
            clk: in  std_logic;
            -- flow control
            credit_in_N, credit_in_E, credit_in_W, credit_in_S, credit_in_L: in std_logic;
           	req_N_N, req_N_E, req_N_W, req_N_S, req_N_L: in std_logic;
           	req_E_N, req_E_E, req_E_W, req_E_S, req_E_L: in std_logic;
           	req_W_N, req_W_E, req_W_W, req_W_S, req_W_L: in std_logic;
           	req_S_N, req_S_E, req_S_W, req_S_S, req_S_L: in std_logic;
           	req_L_N, req_L_E, req_L_W, req_L_S, req_L_L: in std_logic;
            empty_N, empty_E, empty_W, empty_S, empty_L: in std_logic;
            valid_N, valid_E, valid_W, valid_S, valid_L : out std_logic;

            -- vc signals
            credit_in_vc_N, credit_in_vc_E, credit_in_vc_W, credit_in_vc_S, credit_in_vc_L: in std_logic;
            req_N_N_vc, req_N_E_vc, req_N_W_vc, req_N_S_vc, req_N_L_vc: in std_logic;
           	req_E_N_vc, req_E_E_vc, req_E_W_vc, req_E_S_vc, req_E_L_vc: in std_logic;
           	req_W_N_vc, req_W_E_vc, req_W_W_vc, req_W_S_vc, req_W_L_vc: in std_logic;
           	req_S_N_vc, req_S_E_vc, req_S_W_vc, req_S_S_vc, req_S_L_vc: in std_logic;
           	req_L_N_vc, req_L_E_vc, req_L_W_vc, req_L_S_vc, req_L_L_vc: in std_logic;

            empty_vc_N, empty_vc_E, empty_vc_W, empty_vc_S, empty_vc_L: in std_logic;
            valid_vc_N, valid_vc_E, valid_vc_W, valid_vc_S, valid_vc_L : out std_logic;

            grants_N, grants_E, grants_W, grants_S, grants_L: out std_logic;
            grants_N_vc, grants_E_vc, grants_W_vc, grants_S_vc, grants_L_vc: out std_logic;
            Xbar_sel_N, Xbar_sel_E, Xbar_sel_W, Xbar_sel_S, Xbar_sel_L: out  std_logic_vector (9 downto 0)

            );
end allocator;

architecture behavior of allocator is

  signal grant_N, grant_E, grant_W, grant_S, grant_L: std_logic;

  signal Grant_N_N, Grant_N_E, Grant_N_W, Grant_N_S, Grant_N_L: std_logic;
  signal Grant_E_N, Grant_E_E, Grant_E_W, Grant_E_S, Grant_E_L: std_logic;
  signal Grant_W_N, Grant_W_E, Grant_W_W, Grant_W_S, Grant_W_L: std_logic;
  signal Grant_S_N, Grant_S_E, Grant_S_W, Grant_S_S, Grant_S_L: std_logic;
  signal Grant_L_N, Grant_L_E, Grant_L_W, Grant_L_S, Grant_L_L: std_logic;

  signal credit_counter_N_in, credit_counter_N_out: std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0);
  signal credit_counter_E_in, credit_counter_E_out: std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0);
  signal credit_counter_W_in, credit_counter_W_out: std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0);
  signal credit_counter_S_in, credit_counter_S_out: std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0);
  signal credit_counter_L_in, credit_counter_L_out: std_logic_vector(CREDIT_COUNTER_LENGTH_LOCAL-1 downto 0);

  signal X_N_N, X_N_E, X_N_W, X_N_S, X_N_L: std_logic;
  signal X_E_N, X_E_E, X_E_W, X_E_S, X_E_L: std_logic;
  signal X_W_N, X_W_E, X_W_W, X_W_S, X_W_L: std_logic;
  signal X_S_N, X_S_E, X_S_W, X_S_S, X_S_L: std_logic;
  signal X_L_N, X_L_E, X_L_W, X_L_S, X_L_L: std_logic;

  signal grant_N_N_sig, grant_N_E_sig, grant_N_W_sig, grant_N_S_sig, grant_N_L_sig: std_logic;
  signal grant_E_N_sig, grant_E_E_sig, grant_E_W_sig, grant_E_S_sig, grant_E_L_sig: std_logic;
  signal grant_W_N_sig, grant_W_E_sig, grant_W_W_sig, grant_W_S_sig, grant_W_L_sig: std_logic;
  signal grant_S_N_sig, grant_S_E_sig, grant_S_W_sig, grant_S_S_sig, grant_S_L_sig: std_logic;
  signal grant_L_N_sig, grant_L_E_sig, grant_L_W_sig, grant_L_S_sig, grant_L_L_sig: std_logic;
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  --------------------------------------------------------------------------------
  signal grant_vc_N, grant_vc_E, grant_vc_W, grant_vc_S, grant_vc_L: std_logic;

  signal Grant_N_N_vc, Grant_N_E_vc, Grant_N_W_vc, Grant_N_S_vc, Grant_N_L_vc: std_logic;
  signal Grant_E_N_vc, Grant_E_E_vc, Grant_E_W_vc, Grant_E_S_vc, Grant_E_L_vc: std_logic;
  signal Grant_W_N_vc, Grant_W_E_vc, Grant_W_W_vc, Grant_W_S_vc, Grant_W_L_vc: std_logic;
  signal Grant_S_N_vc, Grant_S_E_vc, Grant_S_W_vc, Grant_S_S_vc, Grant_S_L_vc: std_logic;
  signal Grant_L_N_vc, Grant_L_E_vc, Grant_L_W_vc, Grant_L_S_vc, Grant_L_L_vc: std_logic;

  signal credit_counter_N_in_vc, credit_counter_N_out_vc: std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0);
  signal credit_counter_E_in_vc, credit_counter_E_out_vc: std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0);
  signal credit_counter_W_in_vc, credit_counter_W_out_vc: std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0);
  signal credit_counter_S_in_vc, credit_counter_S_out_vc: std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0);
  signal credit_counter_L_in_vc, credit_counter_L_out_vc: std_logic_vector(CREDIT_COUNTER_LENGTH_LOCAL-1 downto 0);

  signal X_N_N_vc, X_N_E_vc, X_N_W_vc, X_N_S_vc, X_N_L_vc: std_logic;
  signal X_E_N_vc, X_E_E_vc, X_E_W_vc, X_E_S_vc, X_E_L_vc: std_logic;
  signal X_W_N_vc, X_W_E_vc, X_W_W_vc, X_W_S_vc, X_W_L_vc: std_logic;
  signal X_S_N_vc, X_S_E_vc, X_S_W_vc, X_S_S_vc, X_S_L_vc: std_logic;
  signal X_L_N_vc, X_L_E_vc, X_L_W_vc, X_L_S_vc, X_L_L_vc: std_logic;

  signal grant_N_N_sig_vc, grant_N_E_sig_vc, grant_N_W_sig_vc, grant_N_S_sig_vc, grant_N_L_sig_vc: std_logic;
  signal grant_E_N_sig_vc, grant_E_E_sig_vc, grant_E_W_sig_vc, grant_E_S_sig_vc, grant_E_L_sig_vc: std_logic;
  signal grant_W_N_sig_vc, grant_W_E_sig_vc, grant_W_W_sig_vc, grant_W_S_sig_vc, grant_W_L_sig_vc: std_logic;
  signal grant_S_N_sig_vc, grant_S_E_sig_vc, grant_S_W_sig_vc, grant_S_S_sig_vc, grant_S_L_sig_vc: std_logic;
  signal grant_L_N_sig_vc, grant_L_E_sig_vc, grant_L_W_sig_vc, grant_L_S_sig_vc, grant_L_L_sig_vc: std_logic;



  constant max_credit_counter_value: std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0) := std_logic_vector(to_unsigned(FIFO_DEPTH-1, CREDIT_COUNTER_LENGTH));
  constant max_credit_counter_value_Local: std_logic_vector(CREDIT_COUNTER_LENGTH_LOCAL-1 downto 0) := (others=>'1');

begin

-- sequential part
process(clk, reset)
begin
	if reset = '0' then
		-- we start with all full cradit
	 	credit_counter_N_out <= max_credit_counter_value;
		credit_counter_E_out <= max_credit_counter_value;
		credit_counter_W_out <= max_credit_counter_value;
		credit_counter_S_out <= max_credit_counter_value;
		credit_counter_L_out <= max_credit_counter_value_Local;

    credit_counter_N_out_vc <= max_credit_counter_value;
		credit_counter_E_out_vc <= max_credit_counter_value;
		credit_counter_W_out_vc <= max_credit_counter_value;
		credit_counter_S_out_vc <= max_credit_counter_value;
		credit_counter_L_out_vc <= max_credit_counter_value_Local;

	elsif clk'event and clk = '1' then
		credit_counter_N_out <= credit_counter_N_in;
		credit_counter_E_out <= credit_counter_E_in;
		credit_counter_W_out <= credit_counter_W_in;
		credit_counter_S_out <= credit_counter_S_in;
		credit_counter_L_out <= credit_counter_L_in;

    credit_counter_N_out_vc <= credit_counter_N_in_vc;
    credit_counter_E_out_vc <= credit_counter_E_in_vc;
    credit_counter_W_out_vc <= credit_counter_W_in_vc;
    credit_counter_S_out_vc <= credit_counter_S_in_vc;
    credit_counter_L_out_vc <= credit_counter_L_in_vc;
	end if;
end process;

-- The combionational part

grant_N_N <= grant_N_N_sig and not empty_N and not grant_vc_N;
grant_N_E <= grant_N_E_sig and not empty_E and not grant_vc_N;
grant_N_W <= grant_N_W_sig and not empty_W and not grant_vc_N;
grant_N_S <= grant_N_S_sig and not empty_S and not grant_vc_N;
grant_N_L <= grant_N_L_sig and not empty_L and not grant_vc_N;

grant_E_N <= grant_E_N_sig and not empty_N and not grant_vc_E;
grant_E_E <= grant_E_E_sig and not empty_E and not grant_vc_E;
grant_E_W <= grant_E_W_sig and not empty_W and not grant_vc_E;
grant_E_S <= grant_E_S_sig and not empty_S and not grant_vc_E;
grant_E_L <= grant_E_L_sig and not empty_L and not grant_vc_E;

grant_W_N <= grant_W_N_sig and not empty_N and not grant_vc_W;
grant_W_E <= grant_W_E_sig and not empty_E and not grant_vc_W;
grant_W_W <= grant_W_W_sig and not empty_W and not grant_vc_W;
grant_W_S <= grant_W_S_sig and not empty_S and not grant_vc_W;
grant_W_L <= grant_W_L_sig and not empty_L and not grant_vc_W;

grant_S_N <= grant_S_N_sig and not empty_N and not grant_vc_S;
grant_S_E <= grant_S_E_sig and not empty_E and not grant_vc_S;
grant_S_W <= grant_S_W_sig and not empty_W and not grant_vc_S;
grant_S_S <= grant_S_S_sig and not empty_S and not grant_vc_S;
grant_S_L <= grant_S_L_sig and not empty_L and not grant_vc_S;

grant_L_N <= grant_L_N_sig and not empty_N and not grant_vc_L;
grant_L_E <= grant_L_E_sig and not empty_E and not grant_vc_L;
grant_L_W <= grant_L_W_sig and not empty_W and not grant_vc_L;
grant_L_S <= grant_L_S_sig and not empty_S and not grant_vc_L;
grant_L_L <= grant_L_L_sig and not empty_L and not grant_vc_L;

grant_N <=  grant_N_N or grant_N_E or grant_N_W or grant_N_S or grant_N_L;
grant_E <=  grant_E_N or grant_E_E or grant_E_W or grant_E_S or grant_E_L;
grant_W <=  grant_W_N or grant_W_E or grant_W_W or grant_W_S or grant_W_L;
grant_S <=  grant_S_N or grant_S_E or grant_S_W or grant_S_S or grant_S_L;
grant_L <=  grant_L_N or grant_L_E or grant_L_W or grant_L_S or grant_L_L;

-- this process handels the credit counters!
process(credit_in_N, credit_in_E, credit_in_W, credit_in_S, credit_in_L,
        grant_N, grant_E, grant_W, grant_S, grant_L,
		    credit_counter_N_out, credit_counter_E_out, credit_counter_W_out,
        credit_counter_S_out, credit_counter_L_out)
 begin
 	credit_counter_N_in <= credit_counter_N_out;
 	credit_counter_E_in <= credit_counter_E_out;
 	credit_counter_W_in <= credit_counter_W_out;
 	credit_counter_S_in <= credit_counter_S_out;
 	credit_counter_L_in <= credit_counter_L_out;

 	if credit_in_N = '1' and grant_N = '1' then
      credit_counter_N_in <= credit_counter_N_out;
  elsif credit_in_N = '1'  and credit_counter_N_out < max_credit_counter_value then
      credit_counter_N_in <= credit_counter_N_out + 1;
 	elsif grant_N = '1' and credit_counter_N_out > 0 then
      credit_counter_N_in <= credit_counter_N_out - 1;
 	end if;


  if credit_in_E = '1' and grant_E = '1' then
      credit_counter_E_in <= credit_counter_E_out;
 	elsif credit_in_E = '1' and credit_counter_E_out < max_credit_counter_value then
      credit_counter_E_in <= credit_counter_E_out + 1;
 	elsif grant_E = '1' and credit_counter_E_out > 0 then
      credit_counter_E_in <= credit_counter_E_out - 1;
 	end if;

 	if credit_in_W = '1' and grant_W = '1' then
      credit_counter_W_in <= credit_counter_W_out;
  elsif credit_in_W = '1' and credit_counter_W_out < max_credit_counter_value then
      credit_counter_W_in <= credit_counter_W_out + 1;
  elsif grant_W = '1' and credit_counter_W_out > 0 then
      credit_counter_W_in <= credit_counter_W_out - 1;
  end if;

 	if credit_in_S = '1' and grant_S = '1' then
      credit_counter_S_in <= credit_counter_S_out;
  elsif credit_in_S = '1' and credit_counter_S_out < max_credit_counter_value then
      credit_counter_S_in <= credit_counter_S_out + 1;
  elsif grant_S = '1' and credit_counter_S_out > 0 then
      credit_counter_S_in <= credit_counter_S_out - 1;
  end if;


 	if credit_in_L = '1' and grant_L = '1' then
      credit_counter_L_in <= credit_counter_L_out;
  elsif credit_in_L = '1' and credit_counter_L_out < max_credit_counter_value then
      credit_counter_L_in <= credit_counter_L_out + 1;
  elsif grant_L = '1' and credit_counter_L_out > 0 then
      credit_counter_L_in <= credit_counter_L_out - 1;
  end if;

 end process;


arb_N_X: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                     PORT MAP (reset => reset, clk => clk,
				                       Req_X_N=>req_N_N, Req_X_E=> req_N_E,
                               Req_X_W=>req_N_W, Req_X_S=>req_N_S, Req_X_L=>req_N_L,
                               credit_counter_N => credit_counter_N_out,
                               credit_counter_E => credit_counter_E_out,
                               credit_counter_W => credit_counter_W_out,
                               credit_counter_S => credit_counter_S_out,
                               X_N=>X_N_N, X_E=>X_N_E, X_W=>X_N_W, X_S=>X_N_S, X_L=>X_N_L);

arb_E_X: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                     PORT MAP (reset => reset, clk => clk,
				                       Req_X_N=>req_E_N, Req_X_E=> req_E_E,
                               Req_X_W=>req_E_W, Req_X_S=>req_E_S, Req_X_L=>req_E_L,
                               credit_counter_N => credit_counter_N_out,
                               credit_counter_E => credit_counter_E_out,
                               credit_counter_W => credit_counter_W_out,
                               credit_counter_S => credit_counter_S_out,
                               X_N=>X_E_N, X_E=>X_E_E, X_W=>X_E_W, X_S=>X_E_S, X_L=>X_E_L);

arb_W_X: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                     PORT MAP (reset => reset, clk => clk,
                               Req_X_N=>req_W_N, Req_X_E=> req_W_E,
                               Req_X_W=>req_W_W, Req_X_S=>req_W_S, Req_X_L=>req_W_L,
                               credit_counter_N => credit_counter_N_out,
                               credit_counter_E => credit_counter_E_out,
                               credit_counter_W => credit_counter_W_out,
                               credit_counter_S => credit_counter_S_out,
                               X_N=>X_W_N, X_E=>X_W_E, X_W=>X_W_W, X_S=>X_W_S, X_L=>X_W_L);

arb_S_X: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                     PORT MAP (reset => reset, clk => clk,
                               Req_X_N=>req_S_N, Req_X_E=> req_S_E,
                               Req_X_W=>req_S_W, Req_X_S=>req_S_S, Req_X_L=>req_S_L,
                               credit_counter_N => credit_counter_N_out,
                               credit_counter_E => credit_counter_E_out,
                               credit_counter_W => credit_counter_W_out,
                               credit_counter_S => credit_counter_S_out,
                               X_N=>X_S_N, X_E=>X_S_E, X_W=>X_S_W, X_S=>X_S_S, X_L=>X_S_L);

arb_L_X: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                     PORT MAP (reset => reset, clk => clk,
                               Req_X_N=>req_L_N, Req_X_E=> req_L_E,
                               Req_X_W=>req_L_W, Req_X_S=>req_L_S, Req_X_L=>req_L_L,
                               credit_counter_N => credit_counter_N_out,
                               credit_counter_E => credit_counter_E_out,
                               credit_counter_W => credit_counter_W_out,
                               credit_counter_S => credit_counter_S_out,
                               X_N=>X_L_N, X_E=>X_L_E, X_W=>X_L_W, X_S=>X_L_S, X_L=>X_L_L);

-- Y is N now
arb_X_N: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                     port map (reset => reset, clk => clk,
                               X_N_Y => X_N_N, X_E_Y => X_E_N,  X_W_Y => X_W_N,
                               X_S_Y => X_S_N,  X_L_Y => X_L_N,
                               credit => credit_counter_N_out,
                               grant_Y_N => grant_N_N_sig,
                               grant_Y_E => grant_N_E_sig,
                               grant_Y_W => grant_N_W_sig,
                               grant_Y_S => grant_N_S_sig,
                               grant_Y_L => grant_N_L_sig);

-- Y is E now
arb_X_E: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                     port map (reset => reset, clk => clk,
                               X_N_Y => X_N_E, X_E_Y => X_E_E, X_W_Y => X_W_E,
                               X_S_Y => X_S_E, X_L_Y => X_L_E,
                               credit => credit_counter_E_out,
                               grant_Y_N => grant_E_N_sig,
                               grant_Y_E => grant_E_E_sig,
                               grant_Y_W => grant_E_W_sig,
                               grant_Y_S => grant_E_S_sig,
                               grant_Y_L => grant_E_L_sig);

-- Y is W now
arb_X_W: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                     port map (reset => reset, clk => clk,
                               X_N_Y => X_N_W, X_E_Y => X_E_W, X_W_Y => X_W_W,
                               X_S_Y => X_S_W, X_L_Y => X_L_W,
                               credit => credit_counter_W_out,
                               grant_Y_N => grant_W_N_sig,
                               grant_Y_E => grant_W_E_sig,
                               grant_Y_W => grant_W_W_sig,
                               grant_Y_S => grant_W_S_sig,
                               grant_Y_L => grant_W_L_sig);

-- Y is S now
arb_X_S: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                     port map (reset => reset, clk => clk,
                               X_N_Y => X_N_S, X_E_Y => X_E_S, X_W_Y => X_W_S,
                               X_S_Y => X_S_S, X_L_Y => X_L_S,
                               credit => credit_counter_S_out,
                               grant_Y_N => grant_S_N_sig,
                               grant_Y_E => grant_S_E_sig,
                               grant_Y_W => grant_S_W_sig,
                               grant_Y_S => grant_S_S_sig,
                               grant_Y_L => grant_S_L_sig);

-- Y is L now
arb_X_L: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH_LOCAL)
                     port map (reset => reset, clk => clk,
                               X_N_Y => X_N_L, X_E_Y => X_E_L, X_W_Y => X_W_L,
                               X_S_Y => X_S_L, X_L_Y => X_L_L,
                               credit => credit_counter_L_out,
                               grant_Y_N => grant_L_N_sig,
                               grant_Y_E => grant_L_E_sig,
                               grant_Y_W => grant_L_W_sig,
                               grant_Y_S => grant_L_S_sig,
                               grant_Y_L => grant_L_L_sig);

valid_N <= grant_N and not grant_vc_N;
valid_E <= grant_E and not grant_vc_E;
valid_W <= grant_W and not grant_vc_W;
valid_S <= grant_S and not grant_vc_S;
valid_L <= grant_L and not grant_vc_L;

-- grant_X_Y means the grant for X output port towards Y input port
-- this means for any X in [N, E, W, S, L] then set grant_X_Y is one hot!
grants_N <=  Grant_N_N  or Grant_E_N or Grant_W_N or Grant_S_N or Grant_L_N;
grants_E <=  Grant_N_E  or Grant_E_E or Grant_W_E or Grant_S_E or Grant_L_E;
grants_W <=  Grant_N_W  or Grant_E_W or Grant_W_W or Grant_S_W or Grant_L_W;
grants_S <=  Grant_N_S  or Grant_E_S or Grant_W_S or Grant_S_S or Grant_L_S;
grants_L <=  Grant_N_L  or Grant_E_L or Grant_W_L or Grant_S_L or Grant_L_L;

-- VC part

grant_N_N_vc <= grant_N_N_sig_vc and not empty_vc_N;
grant_N_E_vc <= grant_N_E_sig_vc and not empty_vc_E;
grant_N_W_vc <= grant_N_W_sig_vc and not empty_vc_W;
grant_N_S_vc <= grant_N_S_sig_vc and not empty_vc_S;
grant_N_L_vc <= grant_N_L_sig_vc and not empty_vc_L;

grant_E_N_vc <= grant_E_N_sig_vc and not empty_vc_N;
grant_E_E_vc <= grant_E_E_sig_vc and not empty_vc_E;
grant_E_W_vc <= grant_E_W_sig_vc and not empty_vc_W;
grant_E_S_vc <= grant_E_S_sig_vc and not empty_vc_S;
grant_E_L_vc <= grant_E_L_sig_vc and not empty_vc_L;

grant_W_N_vc <= grant_W_N_sig_vc and not empty_vc_N;
grant_W_E_vc <= grant_W_E_sig_vc and not empty_vc_E;
grant_W_W_vc <= grant_W_W_sig_vc and not empty_vc_W;
grant_W_S_vc <= grant_W_S_sig_vc and not empty_vc_S;
grant_W_L_vc <= grant_W_L_sig_vc and not empty_vc_L;

grant_S_N_vc <= grant_S_N_sig_vc and not empty_vc_N;
grant_S_E_vc <= grant_S_E_sig_vc and not empty_vc_E;
grant_S_W_vc <= grant_S_W_sig_vc and not empty_vc_W;
grant_S_S_vc <= grant_S_S_sig_vc and not empty_vc_S;
grant_S_L_vc <= grant_S_L_sig_vc and not empty_vc_L;

grant_L_N_Vc <= grant_L_N_sig_vc and not empty_vc_N;
grant_L_E_Vc <= grant_L_E_sig_vc and not empty_vc_E;
grant_L_W_Vc <= grant_L_W_sig_vc and not empty_vc_W;
grant_L_S_Vc <= grant_L_S_sig_vc and not empty_vc_S;
grant_L_L_Vc <= grant_L_L_sig_vc and not empty_vc_L;

grant_vc_N <=  grant_N_N_vc or grant_N_E_vc or grant_N_W_vc or grant_N_S_vc or grant_N_L_vc;
grant_vc_E <=  grant_E_N_vc or grant_E_E_vc or grant_E_W_vc or grant_E_S_vc or grant_E_L_vc;
grant_vc_W <=  grant_W_N_vc or grant_W_E_vc or grant_W_W_vc or grant_W_S_vc or grant_W_L_vc;
grant_vc_S <=  grant_S_N_vc or grant_S_E_vc or grant_S_W_vc or grant_S_S_vc or grant_S_L_vc;
grant_vc_L <=  grant_L_N_vc or grant_L_E_vc or grant_L_W_vc or grant_L_S_vc or grant_L_L_vc;

-- this process handels the credit counters!
process(credit_in_vc_N, credit_in_vc_E, credit_in_vc_W, credit_in_vc_S, credit_in_vc_L,
        grant_vc_N, grant_vc_E, grant_vc_W, grant_vc_S, grant_vc_L,
        credit_counter_N_out_vc, credit_counter_E_out_vc, credit_counter_W_out_vc,
        credit_counter_S_out_vc, credit_counter_L_out_vc)
begin
      credit_counter_N_in_vc <= credit_counter_N_out_vc;
      credit_counter_E_in_vc <= credit_counter_E_out_vc;
      credit_counter_W_in_vc <= credit_counter_W_out_vc;
      credit_counter_S_in_vc <= credit_counter_S_out_vc;
      credit_counter_L_in_vc <= credit_counter_L_out_vc;

      if credit_in_vc_N = '1' and grant_vc_N = '1' then
            credit_counter_N_in_vc <= credit_counter_N_out_vc;
      elsif credit_in_vc_N = '1'  and credit_counter_N_out_vc < max_credit_counter_value then
            credit_counter_N_in_vc <= credit_counter_N_out_vc + 1;
      elsif grant_vc_N = '1' and credit_counter_N_out_vc > 0 then
            credit_counter_N_in_vc <= credit_counter_N_out_vc - 1;
      end if;


      if credit_in_vc_E = '1' and grant_vc_E = '1' then
            credit_counter_E_in_vc <= credit_counter_E_out_vc;
      elsif credit_in_vc_E = '1'  and credit_counter_E_out_vc < max_credit_counter_value then
            credit_counter_E_in_vc <= credit_counter_E_out_vc + 1;
      elsif grant_vc_E = '1' and credit_counter_E_out_vc > 0 then
            credit_counter_E_in_vc <= credit_counter_E_out_vc - 1;
      end if;

      if credit_in_vc_W = '1' and grant_vc_W = '1' then
            credit_counter_W_in_vc <= credit_counter_W_out_vc;
      elsif credit_in_vc_W = '1'  and credit_counter_W_out_vc < max_credit_counter_value then
            credit_counter_W_in_vc <= credit_counter_W_out_vc + 1;
      elsif grant_vc_W = '1' and credit_counter_W_out_vc > 0 then
            credit_counter_W_in_vc <= credit_counter_W_out_vc - 1;
      end if;

      if credit_in_vc_S = '1' and grant_vc_S = '1' then
            credit_counter_S_in_vc <= credit_counter_S_out_vc;
      elsif credit_in_vc_S = '1'  and credit_counter_S_out_vc < max_credit_counter_value then
            credit_counter_S_in_vc <= credit_counter_S_out_vc + 1;
      elsif grant_vc_S = '1' and credit_counter_S_out_vc > 0 then
            credit_counter_S_in_vc <= credit_counter_S_out_vc - 1;
      end if;


      if credit_in_vc_L = '1' and grant_vc_L = '1' then
            credit_counter_L_in_vc <= credit_counter_L_out_vc;
      elsif credit_in_vc_L = '1'  and credit_counter_L_out_vc < max_credit_counter_value then
            credit_counter_L_in_vc <= credit_counter_L_out_vc + 1;
      elsif grant_vc_L = '1' and credit_counter_L_out_vc > 0 then
            credit_counter_L_in_vc <= credit_counter_L_out_vc - 1;
      end if;

end process;


arb_N_X_vc: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                        PORT MAP (reset => reset, clk => clk,
                                  Req_X_N=>req_N_N_vc, Req_X_E=> req_N_E_vc,
                                  Req_X_W=>req_N_W_vc, Req_X_S=>req_N_S_vc, Req_X_L=>req_N_L_vc,
                                  credit_counter_N => credit_counter_N_out_vc,
                                  credit_counter_E => credit_counter_E_out_vc,
                                  credit_counter_W => credit_counter_W_out_vc,
                                  credit_counter_S => credit_counter_S_out_vc,
                                  X_N=>X_N_N_vc, X_E=>X_N_E_vc, X_W=>X_N_W_vc, X_S=>X_N_S_vc, X_L=>X_N_L_vc);

arb_E_X_vc: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                        PORT MAP (reset => reset, clk => clk,
                                  Req_X_N=>req_E_N_vc, Req_X_E=> req_E_E_vc,
                                  Req_X_W=>req_E_W_vc, Req_X_S=>req_E_S_vc, Req_X_L=>req_E_L_vc,
                                  credit_counter_N => credit_counter_N_out_vc,
                                  credit_counter_E => credit_counter_E_out_vc,
                                  credit_counter_W => credit_counter_W_out_vc,
                                  credit_counter_S => credit_counter_S_out_vc,
                                  X_N=>X_E_N_vc, X_E=>X_E_E_vc, X_W=>X_E_W_vc, X_S=>X_E_S_vc, X_L=>X_E_L_vc);

arb_W_X_vc: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                        PORT MAP (reset => reset, clk => clk,
                                  Req_X_N=>req_W_N_vc, Req_X_E=> req_W_E_vc,
                                  Req_X_W=>req_W_W_vc, Req_X_S=>req_W_S_vc, Req_X_L=>req_W_L_vc,
                                  credit_counter_N => credit_counter_N_out_vc,
                                  credit_counter_E => credit_counter_E_out_vc,
                                  credit_counter_W => credit_counter_W_out_vc,
                                  credit_counter_S => credit_counter_S_out_vc,
                                  X_N=>X_W_N_vc, X_E=>X_W_E_vc, X_W=>X_W_W_vc, X_S=>X_W_S_vc, X_L=>X_W_L_vc);

arb_S_X_vc: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                        PORT MAP (reset => reset, clk => clk,
                                  Req_X_N=>req_S_N_vc, Req_X_E=> req_S_E_vc,
                                  Req_X_W=>req_S_W_vc, Req_X_S=>req_S_S_vc, Req_X_L=>req_S_L_vc,
                                  credit_counter_N => credit_counter_N_out_vc,
                                  credit_counter_E => credit_counter_E_out_vc,
                                  credit_counter_W => credit_counter_W_out_vc,
                                  credit_counter_S => credit_counter_S_out_vc,
                                  X_N=>X_S_N_vc, X_E=>X_S_E_vc, X_W=>X_S_W_vc, X_S=>X_S_S_vc, X_L=>X_S_L_vc);

arb_L_X_vc: arbiter_in  generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                        PORT MAP (reset => reset, clk => clk,
                                  Req_X_N=>req_L_N_vc, Req_X_E=> req_L_E_vc,
                                  Req_X_W=>req_L_W_vc, Req_X_S=>req_L_S_vc, Req_X_L=>req_L_L_vc,
                                  credit_counter_N => credit_counter_N_out_vc,
                                  credit_counter_E => credit_counter_E_out_vc,
                                  credit_counter_W => credit_counter_W_out_vc,
                                  credit_counter_S => credit_counter_S_out_vc,
                                  X_N=>X_L_N_vc, X_E=>X_L_E_vc, X_W=>X_L_W_vc, X_S=>X_L_S_vc, X_L=>X_L_L_vc);

-- Y is N now
arb_X_N_vc: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                        port map (reset => reset, clk => clk,
                                  X_N_Y => X_N_N_vc, X_E_Y => X_E_N_vc,
                                  X_W_Y => X_W_N_vc,  X_S_Y => X_S_N_vc,  X_L_Y => X_L_N_vc,
                                  credit => credit_counter_N_out_vc,
                                  grant_Y_N => grant_N_N_sig_vc,
                                  grant_Y_E => grant_N_E_sig_vc,
                                  grant_Y_W => grant_N_W_sig_vc,
                                  grant_Y_S => grant_N_S_sig_vc,
                                  grant_Y_L => grant_N_L_sig_vc);

-- Y is E now
arb_X_E_vc: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                        port map (reset => reset, clk => clk,
                                  X_N_Y => X_N_E_vc, X_E_Y => X_E_E_vc,
                                  X_W_Y => X_W_E_vc, X_S_Y => X_S_E_vc, X_L_Y => X_L_E_vc,
                                  credit => credit_counter_E_out_vc,
                                  grant_Y_N => grant_E_N_sig_vc,
                                  grant_Y_E => grant_E_E_sig_vc,
                                  grant_Y_W => grant_E_W_sig_vc,
                                  grant_Y_S => grant_E_S_sig_vc,
                                  grant_Y_L => grant_E_L_sig_vc);

-- Y is W now
arb_X_W_vc: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                        port map (reset => reset, clk => clk,
                                  X_N_Y => X_N_W_vc, X_E_Y => X_E_W_vc,
                                  X_W_Y => X_W_W_vc, X_S_Y => X_S_W_vc, X_L_Y => X_L_W_vc,
                                  credit => credit_counter_W_out_vc,
                                  grant_Y_N => grant_W_N_sig_vc,
                                  grant_Y_E => grant_W_E_sig_vc,
                                  grant_Y_W => grant_W_W_sig_vc,
                                  grant_Y_S => grant_W_S_sig_vc,
                                  grant_Y_L => grant_W_L_sig_vc);

-- Y is S now
arb_X_S_vc: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH)
                        port map (reset => reset, clk => clk,
                                  X_N_Y => X_N_S_vc, X_E_Y => X_E_S_vc,
                                  X_W_Y => X_W_S_vc, X_S_Y => X_S_S_vc, X_L_Y => X_L_S_vc,
                                  credit => credit_counter_S_out_vc,
                                  grant_Y_N => grant_S_N_sig_vc,
                                  grant_Y_E => grant_S_E_sig_vc,
                                  grant_Y_W => grant_S_W_sig_vc,
                                  grant_Y_S => grant_S_S_sig_vc,
                                  grant_Y_L => grant_S_L_sig_vc);

-- Y is L now
arb_X_L_vc: arbiter_out generic map (CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH_LOCAL)
                        port map (reset => reset, clk => clk,
                                  X_N_Y => X_N_L_vc, X_E_Y => X_E_L_vc,
                                  X_W_Y => X_W_L_vc, X_S_Y => X_S_L_vc, X_L_Y => X_L_L_vc,
                                  credit => credit_counter_L_out_vc,
                                  grant_Y_N => grant_L_N_sig_vc,
                                  grant_Y_E => grant_L_E_sig_vc,
                                  grant_Y_W => grant_L_W_sig_vc,
                                  grant_Y_S => grant_L_S_sig_vc,
                                  grant_Y_L => grant_L_L_sig_vc);

valid_vc_N <= grant_vc_N;
valid_vc_E <= grant_vc_E;
valid_vc_W <= grant_vc_W;
valid_vc_S <= grant_vc_S;
valid_vc_L <= grant_vc_L;

grants_N_vc <=  Grant_N_N_vc  or Grant_E_N_vc or Grant_W_N_vc or Grant_S_N_vc or Grant_L_N_vc;
grants_E_vc <=  Grant_N_E_vc  or Grant_E_E_vc or Grant_W_E_vc or Grant_S_E_vc or Grant_L_E_vc;
grants_W_vc <=  Grant_N_W_vc  or Grant_E_W_vc or Grant_W_W_vc or Grant_S_W_vc or Grant_L_W_vc;
grants_S_vc <=  Grant_N_S_vc  or Grant_E_S_vc or Grant_W_S_vc or Grant_S_S_vc or Grant_L_S_vc;
grants_L_vc <=  Grant_N_L_vc  or Grant_E_L_vc or Grant_W_L_vc or Grant_S_L_vc or Grant_L_L_vc;


-- all the Xbar selectnals
Xbar_sel_N <= '0' 		         & Grant_N_E_vc & Grant_N_W_vc & Grant_N_S_vc & Grant_N_L_vc & '0' 	         & Grant_N_E & Grant_N_W & Grant_N_S & Grant_N_L;
Xbar_sel_E <= Grant_E_N_vc & '0' 		          & Grant_E_W_vc & Grant_E_S_vc & Grant_E_L_vc & Grant_E_N & '0'           & Grant_E_W & Grant_E_S & Grant_E_L;
Xbar_sel_W <= Grant_W_N_vc & Grant_W_E_vc & '0' 		         & Grant_W_S_vc & Grant_W_L_vc & Grant_W_N & Grant_W_E & '0' 	         & Grant_W_S & Grant_W_L;
Xbar_sel_S <= Grant_S_N_vc & Grant_S_E_vc & Grant_S_W_vc & '0' 		          & Grant_S_L_vc & Grant_S_N & Grant_S_E & Grant_S_W & '0' 	         & Grant_S_L;
Xbar_sel_L <= Grant_L_N_vc & Grant_L_E_vc & Grant_L_W_vc & Grant_L_S_vc & '0' 	           & Grant_L_N & Grant_L_E & Grant_L_W & Grant_L_S & '0';

END;
