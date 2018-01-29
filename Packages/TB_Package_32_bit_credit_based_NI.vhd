--Copyright (C) 2016 Siavoosh Payandeh Azad

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
 use ieee.math_real.all;
 use std.textio.all;
 use ieee.std_logic_misc.all;

package TB_Package is
  function CX_GEN(current_address, network_x, network_y : integer) return integer;

   procedure NI_control(network_x, network_y, frame_length, current_address, initial_delay, min_packet_size, max_packet_size: in integer;
                      finish_time: in time;
                      signal clk:                      in std_logic;
                      -- NI configuration
                      signal reserved_address :        in std_logic_vector(29 downto 0);
                      signal flag_address :            in std_logic_vector(29 downto 0) ; -- reserved address for the memory mapped I/O
                      signal counter_address :         in std_logic_vector(29 downto 0);
                      signal reconfiguration_address : in std_logic_vector(29 downto 0);  -- reserved address for reconfiguration register
                      -- NI signals
                      signal enable:                   out std_logic;
                      signal write_byte_enable:        out std_logic_vector(3 downto 0);
                      signal address:                  out std_logic_vector(31 downto 2);
                      signal data_write:               out std_logic_vector(31 downto 0);
                      signal data_read:                in std_logic_vector(31 downto 0);
                      signal test:                out std_logic_vector(31 downto 0));

end TB_Package;

package body TB_Package is
  constant Header_type : std_logic_vector := "001";
  constant Body_type : std_logic_vector := "010";
  constant Tail_type : std_logic_vector := "100";
  constant MaxMemoryAddress1 : integer := 4095; -- should fit in 12 bits (smaller than 4096)
  constant MaxMemoryAddress2 : integer := 1048575; -- should fit in 20 bits (smaller than 1048576)

  function CX_GEN(current_address, network_x, network_y: integer) return integer is
    variable X, Y : integer := 0;
    variable CN, CE, CW, CS : std_logic := '0';
    variable CX : std_logic_vector(3 downto 0);
  begin
    X :=  current_address mod  network_x;
    Y :=  current_address / network_x;

    if X /= 0 then
      CW := '1';
    end if;

    if X /= network_x-1 then
      CE := '1';
    end if;

    if Y /= 0 then
      CN := '1';
    end if;

    if Y /= network_y-1 then
     CS := '1';
    end if;
   CX := CS&CW&CE&CN;
   return to_integer(unsigned(CX));
  end CX_GEN;

  procedure NI_control(network_x, network_y, frame_length, current_address, initial_delay, min_packet_size, max_packet_size: in integer;
                      finish_time: in time;
                      signal clk:                      in std_logic;
                      -- NI configuration
                      signal reserved_address :        in std_logic_vector(29 downto 0);
                      signal flag_address :            in std_logic_vector(29 downto 0) ; -- reserved address for the memory mapped I/O
                      signal counter_address :         in std_logic_vector(29 downto 0);
                      signal reconfiguration_address : in std_logic_vector(29 downto 0);  -- reserved address for reconfiguration register
                      -- NI signals
                      signal enable:                   out std_logic;
                      signal write_byte_enable:        out std_logic_vector(3 downto 0);
                      signal address:                  out std_logic_vector(31 downto 2);
                      signal data_write:               out std_logic_vector(31 downto 0);
                      signal data_read:                in std_logic_vector(31 downto 0);
                      signal test:                out std_logic_vector(31 downto 0)) is
    -- variables for random functions
    constant DATA_WIDTH : integer := 32;
    variable seed1 :positive := current_address+1;
    variable seed2 :positive := current_address+1;
    variable rand : real ;
    --file handling variables
    variable SEND_LINEVARIABLE : line;
    file SEND_FILE : text;





    -- sending variables
    variable send_destination_node, send_counter, send_id_counter: integer:= 0;
    variable send_packet_length: integer:= 8;
    variable Mem_address_1, Mem_address2, RW, DI, ROLE, OPCODE: integer := 0;
    type state_type is (Idle, Header_flit, Body_flit, Body_flit_1, Tail_flit);
    variable  state : state_type;

    variable  frame_starting_delay : integer:= 0;
    variable frame_counter: integer:= 0;
    variable first_packet : boolean := True;
    variable packet_gen_time: time;
    begin


    file_open(SEND_FILE,"sent.txt",WRITE_MODE);

    enable <= '1';
    state :=  Idle;
    send_packet_length := min_packet_size;
    uniform(seed1, seed2, rand);
    frame_starting_delay := integer(((integer(rand*100.0)*(frame_length - max_packet_size-1)))/100);

    wait until clk'event and clk ='0';
    address <= reconfiguration_address;
    wait until clk'event and clk ='0';
    write_byte_enable <= "1111";

    data_write <= "00000000000000000000" & std_logic_vector(to_unsigned(CX_GEN(current_address, network_x, network_y), 4)) & std_logic_vector(to_unsigned(60, 8));

    wait until clk'event and clk ='0';
    write_byte_enable <= "0000";
    data_write <= (others =>'0');

    while true loop
      -- read the flag status
      address <= flag_address;
      write_byte_enable <= "0000";
      wait until clk'event and clk ='0';

      --flag register is organized like this:
      --       .-------------------------------------------------.
      --       | N2P_empty | P2N_full |                       ...|
      --       '-------------------------------------------------'
      if data_read(31) = '0' then  -- N2P is not empty, can receive flit
          -- read the received data status
          address <= counter_address;
          write_byte_enable <= "0000";
          wait until clk'event and clk ='0';


          -- read the received data status
          address <= reserved_address;
          write_byte_enable <= "0000";
          wait until clk'event and clk ='0';

      elsif data_read(30) = '0' then -- P2N is not full, can send flit
          if frame_counter >= frame_starting_delay  then

              if state = Idle and now  < finish_time then
                  if frame_counter < frame_starting_delay+1 then

                    state :=  Header_flit;
                    send_counter := send_counter+1;
                    -- generating the destination address
                    uniform(seed1, seed2, rand);
                    send_destination_node := integer(rand*real((network_x*network_y)-1));
                    while (send_destination_node = current_address) loop
                        uniform(seed1, seed2, rand);
                        send_destination_node := integer(rand*real((network_x*network_y)-1));
                    end loop;
                    --generating the packet length
                    uniform(seed1, seed2, rand);
                    send_packet_length := integer((integer(rand*100.0)*frame_length)/300);
                    if (send_packet_length < min_packet_size) then
                        send_packet_length:=min_packet_size;
                    end if;
                    if (send_packet_length > max_packet_size) then
                        send_packet_length:=max_packet_size;
                    end if;
                    uniform(seed1, seed2, rand);
                    Mem_address_1:= integer(rand*real(MaxMemoryAddress1));
                    -- this is the header flit
                    address <= reserved_address;
                    write_byte_enable <= "1111";
                    packet_gen_time :=  now;
                    data_write <= "0000" &  std_logic_vector(to_unsigned(current_address/network_x, 4)) & std_logic_vector(to_unsigned(current_address mod network_x, 4)) & std_logic_vector(to_unsigned(send_destination_node/network_x, 4)) & std_logic_vector(to_unsigned(send_destination_node mod network_x, 4))&std_logic_vector(to_unsigned(Mem_address_1, 12));

                  else
                    state :=  Idle;
                  end if;
              elsif state = Header_flit then
                  -- first body flit
                  address <= reserved_address;
                  write_byte_enable <= "1111";
                  -- this is body 1
                  uniform(seed1, seed2, rand);
                  RW := integer(rand*real(2));
                  if RW > 1 then
                    RW := 1;
                  end if;
                  uniform(seed1, seed2, rand);
                  DI := integer(rand*real(2));
                  if DI > 1 then
                    DI := 1;
                  end if;
                  uniform(seed1, seed2, rand);
                  ROLE := integer(rand*real(2));
                  if ROLE > 1 then
                    ROLE := 1;
                  end if;
                  uniform(seed1, seed2, rand);
                  Mem_address2 := integer(rand*real(MaxMemoryAddress2));
                  data_write <= "0000" &  std_logic_vector(to_unsigned(Mem_address2, 20)) & std_logic_vector(to_unsigned(RW,1)) & std_logic_vector(to_unsigned(DI,1)) & std_logic_vector(to_unsigned(ROLE,1)) & std_logic_vector(to_unsigned(OPCODE, 5));
                  write(SEND_LINEVARIABLE, "Packet generated at " & time'image(packet_gen_time) & " From " & integer'image(current_address) & " to " & integer'image(send_destination_node) &
                        " with length: "& integer'image(send_packet_length)  & " id: " & integer'image(send_id_counter) & " Mem_address_1: " & integer'image(Mem_address_1)&
                        " Mem_address_2: " & integer'image(Mem_address2) & " RW: " & integer'image(RW) & " DI: " & integer'image(DI) & " ROLE: " & integer'image(ROLE));
                  writeline(SEND_FILE, SEND_LINEVARIABLE);
                  send_counter := send_counter+1;
                  state :=  Body_flit_1;

              elsif state = Body_flit_1 then
                  -- the 2nd body flit
                  address <= reserved_address;
                  write_byte_enable <= "1111";
                  uniform(seed1, seed2, rand);
                  data_write <= "0000" &  std_logic_vector(to_unsigned(send_packet_length, 14)) & std_logic_vector(to_unsigned(send_id_counter, 14));
                  send_counter := send_counter+1;
                  if send_counter = send_packet_length-1 then
                      state :=  Tail_flit;
                  else
                      state :=  Body_flit;
                  end if;
              elsif state = Body_flit then
                  -- rest of body flits
                  address <= reserved_address;
                  write_byte_enable <= "1111";
                  uniform(seed1, seed2, rand);
                  data_write <= "0000" & std_logic_vector(to_unsigned(integer(rand*1000.0), 28));
                  send_counter := send_counter+1;
                  if send_counter = send_packet_length-1 then
                      state :=  Tail_flit;
                  else
                      state :=  Body_flit;
                  end if;
              elsif state = Tail_flit then
                  -- tail flit
                  address <= reserved_address;
                  write_byte_enable <= "1111";
                  if first_packet = True then
                    data_write <= "0000" & "0000000000000000000000000000";
                    first_packet := False;
                  else
                    uniform(seed1, seed2, rand);
                    data_write <= "0000" & std_logic_vector(to_unsigned(integer(rand*1000.0), 28));
                  end if;
                  send_counter := 0;
                  state :=  Idle;
                  send_id_counter := send_id_counter + 1;
                  if send_id_counter = 16384 then
                    send_id_counter := 0;
                  end if;
              end if;
            end if;

            frame_counter := frame_counter + 1;
            if frame_counter = frame_length then
                frame_counter := 0;
                uniform(seed1, seed2, rand);
                frame_starting_delay := integer(((integer(rand*100.0)*(frame_length - max_packet_size)))/100);
            end if;

            wait until clk'event and clk ='0';

      end if;


    end loop;
    file_close(SEND_FILE);
  end NI_control;


end TB_Package;
