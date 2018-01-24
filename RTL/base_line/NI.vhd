---------------------------------------------------------------------
-- Copyright (C) 2016 Siavoosh Payandeh Azad
--
-- 	Network interface: Its an interrupt based memory mapped I/O for sending and recieving packets.
--	the data that is sent to NI should be of the following form:
-- 	FIRST write:  4bit source(31-28), 4 bit destination(27-14), 8bit packet length(23-16)
-- 	Body write:  28 bit data(27-0)
-- 	Last write:  28 bit data(27-0)

---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use ieee.std_logic_misc.all;


entity NI is
   generic(current_x : integer := 10; 	-- the current node's x
           current_y : integer := 10; 	-- the current node's y
           network_x : integer := 4 ;
           NI_depth : integer := 32;
           NI_couter_size: integer:= 5; -- should be set to log2 of NI_depth
           reserved_address : std_logic_vector(29 downto 0) := "000000000000000001111111111111"; -- NI's memory mapped reserved
           flag_address : std_logic_vector(29 downto 0) :=     "000000000000000010000000000000";  -- reserved address for the flag register
           counter_address : std_logic_vector(29 downto 0) :=     "000000000000000010000000000001");  -- packet counter register address!
   port(clk               : in std_logic;
        reset             : in std_logic;
        enable            : in std_logic;
        write_byte_enable : in std_logic_vector(3 downto 0);
        address           : in std_logic_vector(31 downto 2);
        data_write        : in std_logic_vector(31 downto 0);
        data_read         : out std_logic_vector(31 downto 0);

        -- interrupt signal: disabled!
        irq_out           : out std_logic;

        -- signals for sending packets to network
        credit_in : in std_logic;
        valid_out: out std_logic;
        TX: out std_logic_vector(31 downto 0);	-- data sent to the NoC

        -- signals for reciving packets from the network
        credit_out : out std_logic;
        valid_in: in std_logic;
        RX: in std_logic_vector(31 downto 0)	-- data recieved form the NoC

	);
end; --entity NI

architecture logic of NI is

  -- all the following signals are for sending data from processor to NoC
  signal storage, storage_in : std_logic_vector(31 downto 0);
  signal valid_data_in, valid_data: std_logic;

  -- this old address is put here to make it compatible with Plasma processor!
  signal old_address: std_logic_vector(31 downto 2);

  signal P2N_FIFO_read_pointer, P2N_FIFO_read_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);
  signal P2N_FIFO_write_pointer, P2N_FIFO_write_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);
  signal P2N_write_en: std_logic;

  type MEM is array (0 to NI_depth-1) of std_logic_vector(31 downto 0);
  signal P2N_FIFO, P2N_FIFO_in : MEM;
  signal P2N_full, P2N_empty: std_logic;


  signal credit_counter_in, credit_counter_out: std_logic_vector(1 downto 0);
  signal packet_counter_in, packet_counter_out: std_logic_vector(13 downto 0);
  signal packet_length_counter_in, packet_length_counter_out: std_logic_vector(13 downto 0);
  signal grant : std_logic;

  type STATE_TYPE IS (IDLE, HEADER_FLIT, BODY_FLIT_2, BODY_FLIT_1, BODY_FLIT, TAIL_FLIT);
  signal state, state_in   : STATE_TYPE := IDLE;
  signal FIFO_Data_out : std_logic_vector(31 downto 0);
  signal flag_register, flag_register_in : std_logic_vector(31 downto 0);


  -- all the following signals are for sending the packets from NoC to processor
  signal N2P_FIFO, N2P_FIFO_in : MEM;

  signal N2P_Data_out : std_logic_vector(31 downto 0);


  signal N2P_FIFO_read_pointer, N2P_FIFO_read_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);
  signal N2P_FIFO_write_pointer, N2P_FIFO_write_pointer_in: std_logic_vector(NI_couter_size-1 downto 0);

  signal N2P_full, N2P_empty: std_logic;
  signal N2P_read_en, N2P_read_en_in, N2P_write_en: std_logic;
  signal counter_register_in, counter_register : std_logic_vector(1 downto 0);

  -- this is for depacketizer section
  type depacketizer_state_type is (Header, Body_1, Body_2, other_body, IDLE_input);
  signal depack_read, proc_read : std_logic;
  signal depack_state, depack_state_in : depacketizer_state_type;
  signal Rec_Valid, Rec_Valid_in  : std_logic;
  signal Rec_MEM_Address, Rec_MEM_Address_in                  : std_logic_vector(31 downto 0);
  signal Rec_RightsAndOpCode, Rec_RightsAndOpCode_in          : std_logic_vector(7 downto 0);
  signal Rec_Source_Address,  Rec_Source_Address_in           : std_logic_vector(7 downto 0);
  signal Rec_Destination_Address, Rec_Destination_Address_in  : std_logic_vector(7 downto 0);
  signal Rec_Packet_ID, Rec_Packet_ID_in                      : std_logic_vector(13 downto 0);
  signal Rec_Packet_Lenght, Rec_Packet_Lenght_in              : std_logic_vector(13 downto 0);

begin

process(clk, enable, write_byte_enable) begin
   if reset = '1' then
      storage <= (others => '0');
      valid_data <= '0';
      P2N_FIFO_read_pointer  <= (others=>'0');
      P2N_FIFO_write_pointer <= (others=>'0');


      P2N_FIFO  <= (others => (others=>'0'));

      credit_counter_out <= "11";
      packet_length_counter_out <= "00000000000000";
      state <= IDLE;
      packet_counter_out <= "00000000000000";
      ------------------------------------------------
      N2P_FIFO  <= (others => (others=>'0'));

      N2P_FIFO_read_pointer  <= (others=>'0');
      N2P_FIFO_write_pointer <= (others=>'0');
      credit_out <= '0';
      counter_register <= (others => '0');
      N2P_read_en <= '0';
      flag_register <= (others =>'0');
      old_address <= (others =>'0');
      -------------------------------
      Rec_Valid <= '0';
      Rec_MEM_Address <= (others =>'0');
      Rec_RightsAndOpCode <= (others =>'0');
      Rec_Source_Address <= (others =>'0');
      Rec_Destination_Address <= (others =>'0');
      Rec_Packet_ID <= (others =>'0');
      Rec_Packet_Lenght <= (others =>'0');
      depack_state <= IDLE_input;
   elsif clk'event and clk = '1'  then
      old_address <= address;
      P2N_FIFO_write_pointer <= P2N_FIFO_write_pointer_in;
      P2N_FIFO_read_pointer  <=  P2N_FIFO_read_pointer_in;
      credit_counter_out <= credit_counter_in;
      packet_length_counter_out <= packet_length_counter_in;
      valid_data <= valid_data_in;
      if P2N_write_en = '1' then
        --write into the memory
        P2N_FIFO  <= P2N_FIFO_in;
       end if;
      packet_counter_out <= packet_counter_in;
      if write_byte_enable /= "0000" then
         storage <= storage_in;
      end if;
      state <= state_in;
      ------------------------------------------------
      if N2P_write_en = '1' then
        --write into the memory
        N2P_FIFO <= N2P_FIFO_in;
      end if;
      counter_register <= counter_register_in;
      N2P_FIFO_write_pointer <= N2P_FIFO_write_pointer_in;
      N2P_FIFO_read_pointer  <= N2P_FIFO_read_pointer_in;
      credit_out <= '0';
      N2P_read_en <= N2P_read_en_in;
      if N2P_read_en = '1' then
        credit_out <= '1';
      end if;
      flag_register <= flag_register_in;
      -------------------------------
      Rec_Valid <= Rec_Valid_IN;
      Rec_MEM_Address <= Rec_MEM_Address_IN;
      Rec_RightsAndOpCode <= Rec_RightsAndOpCode_in;
      Rec_Source_Address <= Rec_Source_Address_in;
      Rec_Destination_Address <= Rec_Destination_Address_in;
      Rec_Packet_ID <= Rec_Packet_ID_in;
      Rec_Packet_Lenght <= Rec_Packet_Lenght_in;
      depack_state <= depack_state_in;
   end if;
end process;

-- everything bellow this line is pure combinatorial!

---------------------------------------------------------------------------------------
--below this is code for communication from PE 2 NoC



process(write_byte_enable, enable, address, storage, data_write, valid_data, P2N_write_en) begin
   storage_in <= storage ;
   valid_data_in <= valid_data;

   -- If PE wants to send data to NoC via NI (data is valid)
   if enable = '1' and address = reserved_address then
      if write_byte_enable /= "0000" then
        valid_data_in <= '1';
      end if;
      if write_byte_enable(0) = '1' then
         storage_in(7 downto 0) <= data_write(7 downto 0);
      end if;
      if write_byte_enable(1) = '1' then
         storage_in(15 downto 8) <= data_write(15 downto 8);
      end if;
      if write_byte_enable(2) = '1' then
         storage_in(23 downto 16) <= data_write(23 downto 16);
      end if;
      if write_byte_enable(3) = '1' then
         storage_in(31 downto 24) <= data_write(31 downto 24);
    end if;
   end if;

   if P2N_write_en = '1' then
      valid_data_in <= '0';
    end if;

end process;

    process(storage, P2N_FIFO_write_pointer, P2N_FIFO) begin
        P2N_FIFO_in <= P2N_FIFO;
        P2N_FIFO_in(to_integer(unsigned(P2N_FIFO_write_pointer))) <= storage;
    end process;

    FIFO_Data_out <= P2N_FIFO(to_integer(unsigned(P2N_FIFO_read_pointer)));


-- Write pointer update process (after each write operation, write pointer is rotated one bit to the left)
process(P2N_write_en, P2N_FIFO_write_pointer)begin
    if P2N_write_en = '1' then
       P2N_FIFO_write_pointer_in <= P2N_FIFO_write_pointer +1 ;
    else
       P2N_FIFO_write_pointer_in <= P2N_FIFO_write_pointer;
    end if;
  end process;

-- Read pointer update process (after each read operation, read pointer is rotated one bit to the left)
 process(P2N_FIFO_read_pointer, grant)begin
  P2N_FIFO_read_pointer_in <=  P2N_FIFO_read_pointer;
  if grant  = '1' then
    P2N_FIFO_read_pointer_in <= P2N_FIFO_read_pointer +1;
  end if;
end process;

process(P2N_full, valid_data) begin
     if valid_data = '1' and P2N_full ='0' then
         P2N_write_en <= '1';
     else
         P2N_write_en <= '0';
     end if;
  end process;

-- Process for updating full and empty signals
process(P2N_FIFO_write_pointer, P2N_FIFO_read_pointer) begin
      P2N_empty <= '0';
      P2N_full <= '0';
      if P2N_FIFO_read_pointer = P2N_FIFO_write_pointer  then
              P2N_empty <= '1';
      end if;
      if P2N_FIFO_write_pointer = P2N_FIFO_read_pointer - 1 then
              P2N_full <= '1';
      end if;
  end process;

process (credit_in, credit_counter_out, grant)begin
    credit_counter_in <= credit_counter_out;
    if credit_in = '1' and grant = '1' then
         credit_counter_in <= credit_counter_out;
    elsif credit_in = '1'  and credit_counter_out < 3 then
         credit_counter_in <= credit_counter_out + 1;
    elsif grant = '1' and credit_counter_out > 0 then
         credit_counter_in <= credit_counter_out - 1;
    end if;
end process;



process(P2N_empty, state, credit_counter_out, packet_length_counter_out, packet_counter_out, FIFO_Data_out)

    begin
        -- Some initializations
        TX <= (others => '0');
        grant<= '0';
        packet_length_counter_in <= packet_length_counter_out;
        packet_counter_in <= packet_counter_out;

        case(state) is
            when IDLE =>
                if P2N_empty = '0' then
                    state_in <= HEADER_FLIT;
                else
                    state_in <= IDLE;
                end if;

            when HEADER_FLIT =>
                if credit_counter_out /= "00" and P2N_empty = '0' then
                    grant <= '1';
                    --FIFO_Data_out(19 downto 0) contains the following: Destination Y- 4 bits, Destination X-4 bits, Mem_address_1 12bit
                    TX <= "001" & std_logic_vector(to_unsigned(current_y, 4)) & std_logic_vector(to_unsigned(current_x, 4)) & FIFO_Data_out(19 downto 0) & XOR_REDUCE("001" & std_logic_vector(to_unsigned(current_y, 4)) & std_logic_vector(to_unsigned(current_x, 4)) & FIFO_Data_out(19 downto 0));
                    state_in <= BODY_FLIT_1;
                else
                    state_in <= HEADER_FLIT;
                end if;
            when BODY_FLIT_1 =>
                      if credit_counter_out /= "00" and P2N_empty = '0'then
                        grant <= '1';
                        TX <=  "010" & FIFO_Data_out(27 downto 0) & XOR_REDUCE( "010" & FIFO_Data_out(27 downto 0));
                        state_in <= BODY_FLIT_2;
                      else
                        state_in <= BODY_FLIT_1;
                      end if;

            when BODY_FLIT_2 =>
                  if credit_counter_out /= "00" and P2N_empty = '0'then
                    packet_length_counter_in <=   (FIFO_Data_out(27 downto 14))-3;
                    grant <= '1';
                    -- FIFO_Data_out(27 downto 14) contains the packet length
                    -- FIFO_Data_out(13 downto 0) is used for passing the packet_counter_out from PE and we can compare here! or reuse it for other purpose
                    TX <=  "010" & FIFO_Data_out(27 downto 14) &  packet_counter_out & XOR_REDUCE( "010" & FIFO_Data_out(27 downto 14) &  packet_counter_out);
                    state_in <= BODY_FLIT;
                  else
                    state_in <= BODY_FLIT_2;
                  end if;

            when BODY_FLIT =>
                if credit_counter_out /= "00" and P2N_empty = '0'then
                    grant <= '1';
                    TX <= "010" & FIFO_Data_out(27 downto 0) & XOR_REDUCE("010" & FIFO_Data_out(27 downto 0));
                    packet_length_counter_in <= packet_length_counter_out - 1;

                    if packet_length_counter_out > 2 then
                      state_in <= BODY_FLIT;
                    else
                      state_in <= TAIL_FLIT;
                    end if;
                else
                    state_in <= BODY_FLIT;
                end if;

            when TAIL_FLIT =>
                if credit_counter_out /= "00" and P2N_empty = '0' then
                    grant <= '1';
                    packet_length_counter_in <= packet_length_counter_out - 1;
                    TX <= "100" & FIFO_Data_out(27 downto 0) & XOR_REDUCE("100" & FIFO_Data_out(27 downto 0));
                    packet_counter_in <= packet_counter_out +1;
                    state_in <= IDLE;
                else
                    state_in <= TAIL_FLIT;
                end if;
            when others =>
                state_in <= IDLE;
        end case ;

end procesS;

valid_out <= grant;


  process(RX, N2P_FIFO_write_pointer, N2P_FIFO) begin
      N2P_FIFO_in <= N2P_FIFO;
      N2P_FIFO_in(to_integer(unsigned(N2P_FIFO_write_pointer))) <= RX;
  end process;

  N2P_Data_out <= N2P_FIFO(to_integer(unsigned(N2P_FIFO_read_pointer)));


  process(address, write_byte_enable, N2P_empty, Rec_Valid)begin
    if (address = reserved_address and write_byte_enable = "0000" and Rec_Valid = '1' and N2P_empty = '0') then
      proc_read <= '1';
    else
      proc_read <= '0';
    end if;
  end process;


  process (proc_read, depack_read, N2P_empty) begin
    if (proc_read = '1' or depack_read = '1') and N2P_empty = '0' then
      N2P_read_en_in <= '1';
    else
      N2P_read_en_in <= '0';
    end if;
end process;


  process(N2P_write_en, N2P_FIFO_write_pointer)begin
    if N2P_write_en = '1'then
       N2P_FIFO_write_pointer_in <= N2P_FIFO_write_pointer + 1;
    else
       N2P_FIFO_write_pointer_in <= N2P_FIFO_write_pointer;
    end if;
  end process;

  process(N2P_read_en, N2P_empty, N2P_FIFO_read_pointer)begin
       if (N2P_read_en = '1' and N2P_empty = '0') then
           N2P_FIFO_read_pointer_in <= N2P_FIFO_read_pointer + 1;
       else
           N2P_FIFO_read_pointer_in <= N2P_FIFO_read_pointer;
       end if;
  end process;

  process(N2P_full, valid_in) begin
     if (valid_in = '1' and N2P_full ='0') then
         N2P_write_en <= '1';
     else
         N2P_write_en <= '0';
     end if;
  end process;

  process(N2P_FIFO_write_pointer, N2P_FIFO_read_pointer) begin
      if N2P_FIFO_read_pointer = N2P_FIFO_write_pointer  then
              N2P_empty <= '1';
      else
              N2P_empty <= '0';
      end if;

      if N2P_FIFO_write_pointer = N2P_FIFO_read_pointer-1 then
              N2P_full <= '1';
      else
              N2P_full <= '0';
      end if;
  end process;


process(N2P_read_en, N2P_Data_out, old_address, flag_register) begin
  if old_address = reserved_address and N2P_read_en = '1' then
    data_read <= N2P_Data_out;
  elsif old_address = flag_address then
    data_read <= flag_register;
  elsif old_address = counter_address then
  	data_read <= "000000000000000000000000000000" & counter_register;
  else
    data_read <= (others => 'U');
  end if;
end process;


process(N2P_write_en, N2P_read_en, RX, N2P_Data_out)begin
  counter_register_in <= counter_register;
  if N2P_write_en = '1' and RX(31 downto 29) = "001" and N2P_read_en = '1' and N2P_Data_out(31 downto 29) = "100" then
  	counter_register_in <= counter_register;
  elsif N2P_write_en = '1' and RX(31 downto 29) = "001" then
    counter_register_in <= counter_register +1;
  elsif N2P_read_en = '1' and N2P_Data_out(31 downto 29) = "100" then
  	counter_register_in <= counter_register -1;
  end if;
end process;

process(N2P_Data_out, depack_state, N2P_empty, depack_state, Rec_Source_Address,
        Rec_Destination_Address, Rec_MEM_Address, Rec_RightsAndOpCode,
        Rec_Packet_Lenght, Rec_Packet_ID, N2P_read_en)

        -- receiving variables
        variable receive_source_node, receive_destination_node, receive_packet_id, receive_counter, receive_packet_length: integer;
        variable RECEIVED_LINEVARIABLE : line;
        file RECEIVED_FILE : text;

  begin

  file_open(RECEIVED_FILE,"received.txt",APPEND_MODE);
  -- default states
  depack_state_in            <=  depack_state;
  Rec_Source_Address_in      <=  Rec_Source_Address;
  Rec_Destination_Address_in <= Rec_Destination_Address;
  Rec_MEM_Address_in         <= Rec_MEM_Address;
  Rec_RightsAndOpCode_in     <= Rec_RightsAndOpCode;
  Rec_Packet_Lenght_in       <= Rec_Packet_Lenght;
  Rec_Packet_ID_in           <= Rec_Packet_ID;
  depack_read <= '0';
  Rec_Valid_in<= Rec_Valid;
  -------------------------------------------------
  case depack_state is
    when IDLE_input =>
        if N2P_Data_out(31 downto 29) = "001" and N2P_empty = '0'  then
            depack_state_in <= Header;
            depack_read <= '1';
        end if;
    when Header =>
        if N2P_Data_out(31 downto 29) = "010" and N2P_empty = '0'  then
            depack_state_in <= Body_1;
            Rec_Source_Address_in <= N2P_Data_out(28 downto 21);
            Rec_Destination_Address_in <=  N2P_Data_out(20 downto 13);
            Rec_MEM_Address_in(11 downto 0) <=  N2P_Data_out(12 downto 1);
            receive_source_node := to_integer(unsigned(N2P_Data_out(28 downto 25)))* network_x+to_integer(unsigned(N2P_Data_out(24 downto 21)));
            receive_destination_node :=to_integer(unsigned(N2P_Data_out(20 downto 17)))* network_x+to_integer(unsigned(N2P_Data_out(16 downto 13)));
            depack_read <= '1';
        end if;
    when Body_1 =>
        if N2P_Data_out(31 downto 29) = "010" and N2P_empty = '0'  then
          depack_state_in <= Body_2;
          Rec_MEM_Address_in(31 downto 12) <=  N2P_Data_out(28 downto 9);
          Rec_RightsAndOpCode_in <=  N2P_Data_out(8 downto 1);
          depack_read <= '1';
        end if;
    when Body_2 =>
      if N2P_Data_out(31 downto 29) = "010" and N2P_empty = '0' then
        depack_state_in <= other_body;
        Rec_Packet_Lenght_in <=  N2P_Data_out(28 downto 15);
        Rec_Packet_ID_in <=  N2P_Data_out(14 downto 1);

        receive_packet_length := to_integer(unsigned(N2P_Data_out(28 downto 15)));
        receive_packet_id := to_integer(unsigned(N2P_Data_out(14 downto 1)));
        Rec_Valid_in <= '1';
      end if;
    when other_body =>
        -- here we have only payload!
        if N2P_Data_out(31 downto 29) = "100" and N2P_empty = '0' and N2P_read_en = '1'  then
          depack_state_in <= IDLE_input;
          Rec_Valid_in <= '0';

          write(RECEIVED_LINEVARIABLE, "Packet received at " & time'image(now) & " From: " & integer'image(receive_source_node) &
                                       " to: " & integer'image(receive_destination_node) & " length: "& integer'image(receive_packet_length) &
                                       " actual length: "& integer'image(0) &  " id: "& integer'image(receive_packet_id));
          writeline(RECEIVED_FILE, RECEIVED_LINEVARIABLE);
        end if;
    end case;
file_close(RECEIVED_FILE);
end process;

flag_register_in <= (not(Rec_Valid and not N2P_empty)) & P2N_full & "000000000000000000000000000000";

irq_out <= '0';
end; --architecture logic