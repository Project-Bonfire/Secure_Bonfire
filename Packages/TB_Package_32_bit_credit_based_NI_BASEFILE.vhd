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
                      APP_FILE_NAME: in string;
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
                      APP_FILE_NAME: in string;
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
                      signal test:                     out std_logic_vector(31 downto 0)) is
    -- variables for random functions
    constant DATA_WIDTH : integer := 32;
    variable seed1 :positive := current_address+1;
    variable seed2 :positive := current_address+1;
    variable rand : real ;
    --file handling variables
    variable SEND_LINEVARIABLE : line;
    file SEND_FILE : text;

    variable APP_LINEVARIABLE : line;
    file APP_FILE : text;
    variable packet_info : integer;
    variable gen_time: time;

    -- sending variables
    variable send_destination_node, send_counter, send_id_counter: integer:= 0;
    variable send_packet_length: integer:= 8;
    variable Mem_address_1, Mem_address_2, RW, DI, ROLE, OPCODE: integer := 0;
    type state_type is (Idle, Header_flit, Body_flit, Body_flit_1, Tail_flit);
    variable  state : state_type;

    variable  frame_starting_delay : integer:= 0;
    variable  frame_length_mod : integer:= 0;
    variable frame_counter: integer:= 0;
    variable packet_gen_time: time;
    variable sent: boolean := True;
    variable packet_sent: boolean := False;

    begin

    file_open(SEND_FILE,"sent.txt",WRITE_MODE);

    if APP_FILE_NAME = "NONE" then
      report "no app file given!";
    else
      file_open(APP_FILE, APP_FILE_NAME, READ_MODE);
    end if;

FRAME_LENGTH_IF

    enable <= '1';
    state :=  Idle;
    send_packet_length := min_packet_size;
    uniform(seed1, seed2, rand);
    --frame_starting_delay := integer(((integer(rand*100.0)*(frame_length_mod - max_packet_size-1)))/100);

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
      frame_counter := frame_counter + 1;
      if frame_counter = frame_length_mod then
          frame_counter := 0;
          packet_sent := False;
          uniform(seed1, seed2, rand);
          --frame_starting_delay := integer(((integer(rand*100.0)*(frame_length_mod - max_packet_size)))/100);
      end if;

      --flag register is organized like this:
      --       .-------------------------------------------------.
      --       | N2P_empty | P2N_full |                       ...|
      --       '-------------------------------------------------'

      if data_read(31) = '0' then  -- N2P is not empty, can receive flit
          -- read the received data status
          address <= reserved_address;
          write_byte_enable <= "0000";
          wait until clk'event and clk ='0';
          frame_counter := frame_counter + 1;
          if frame_counter = frame_length_mod then
              frame_counter := 0;
              packet_sent := False;
              uniform(seed1, seed2, rand);
              --frame_starting_delay := integer(((integer(rand*100.0)*(frame_length_mod - max_packet_size)))/100);
          end if;

TRAFFIC_IF

          if APP_FILE_NAME = "NONE" then
            if frame_counter >= frame_starting_delay  then
                if state = Idle and now  < finish_time and packet_sent = False then
                      packet_sent := True;
                      state :=  Header_flit;
                      --send_counter := send_counter+1;
                        --generating the packet length
                        uniform(seed1, seed2, rand);
                        send_packet_length := integer((integer(rand*100.0)*frame_length_mod)/300);
                        if (send_packet_length < min_packet_size) then
                            send_packet_length:=min_packet_size;
                        end if;
                        if (send_packet_length > max_packet_size) then
                            send_packet_length:=max_packet_size;
                        end if;
                        -- generating the destination address
                        if current_address = 12 then    -- Fixes the destinantion of 12's out going traffic
                            send_destination_node := 3;
ATTACK_DATA
                        else
                          uniform(seed1, seed2, rand);
                          send_destination_node := integer(rand*real((network_x*network_y)-1));
                          while (send_destination_node = current_address) loop
                              uniform(seed1, seed2, rand);
                              send_destination_node := integer(rand*real((network_x*network_y)-1));
                          end loop;
                        end if;
                        uniform(seed1, seed2, rand);
                        Mem_address_1:= integer(rand*real(MaxMemoryAddress1));
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
                          Mem_address_2 := integer(rand*real(MaxMemoryAddress2));

                        -- this is the header flit
                        packet_gen_time :=  now;
                        address <= reserved_address;
                        write_byte_enable <= "1111";
                        data_write <= "0010" &  std_logic_vector(to_unsigned(current_address/network_x, 4)) & std_logic_vector(to_unsigned(current_address mod network_x, 4)) & std_logic_vector(to_unsigned(send_destination_node/network_x, 4)) & std_logic_vector(to_unsigned(send_destination_node mod network_x, 4))&std_logic_vector(to_unsigned(Mem_address_1, 12));
                        write(SEND_LINEVARIABLE, "Packet generated at " & time'image(packet_gen_time) & " From " & integer'image(current_address) & " to " & integer'image(send_destination_node) &
                              " with length: "& integer'image(send_packet_length)  & " id: " & integer'image(send_id_counter) & " Mem_address_1: " & integer'image(Mem_address_1)&
                              " Mem_address_2: " & integer'image(Mem_address_2) & " RW: " & integer'image(RW) & " DI: " & integer'image(DI) & " ROLE: " & integer'image(ROLE));
                        writeline(SEND_FILE, SEND_LINEVARIABLE);
                  elsif state = Header_flit then
                      -- first body flit
                      address <= reserved_address;
                      write_byte_enable <= "1111";
                      data_write <= "0100" &  std_logic_vector(to_unsigned(Mem_address_2, 20)) & std_logic_vector(to_unsigned(RW,1)) & std_logic_vector(to_unsigned(DI,1)) & std_logic_vector(to_unsigned(ROLE,1)) & std_logic_vector(to_unsigned(OPCODE, 5));
                      --send_counter := send_counter+1;
                      state :=  Body_flit_1;

                  elsif state = Body_flit_1 then
                      -- the 2nd body flit
                      address <= reserved_address;
                      write_byte_enable <= "1111";
                      data_write <= "0100" &  std_logic_vector(to_unsigned(send_packet_length, 14)) & std_logic_vector(to_unsigned(send_id_counter, 14));
                      --send_counter := send_counter+1;
                      --if send_counter = send_packet_length-1 then
                      --    state :=  Tail_flit;
                      --else
                      state :=  Body_flit;
                      --end if;
                  elsif state = Body_flit then
                      -- rest of body flits
                      address <= reserved_address;
                      write_byte_enable <= "1111";

                      send_counter := send_counter+1;
                      if send_counter = send_packet_length+1 then
                          data_write <= "0100" & "0000010101000101010001010100";
                          state :=  Tail_flit;
                      else
                          data_write <= "0100" & std_logic_vector(to_unsigned(integer(rand*1000.0), 28));
                          state :=  Body_flit;
                      end if;
                  elsif state = Tail_flit then
                      -- tail flit
                      address <= reserved_address;
                      write_byte_enable <= "1111";
                      --data_write <= "0000" & std_logic_vector(to_unsigned(integer(rand*1000.0), 28));
                      data_write <=  "1000" & "0000000000000000000000000000";
                      send_counter := 0;
                      state :=  Idle;
                      send_id_counter := send_id_counter + 1;
                      if send_id_counter = 16384 then
                        send_id_counter := 0;
                      end if;
                  end if;
                end if;

              frame_counter := frame_counter + 1;
              if frame_counter = frame_length_mod then
                  frame_counter := 0;
                  packet_sent := False;
                  uniform(seed1, seed2, rand);
                  --frame_starting_delay := integer(((integer(rand*100.0)*(frame_length_mod - max_packet_size)))/100);
              end if;
          ----------------------------------------------------------------------------
          -- Reading from file
          else
            if sent = True and not endfile(APP_FILE) then
              readline (APP_FILE, APP_LINEVARIABLE);
              read (APP_LINEVARIABLE, gen_time);
              read (APP_LINEVARIABLE, packet_info);
              send_destination_node := integer(packet_info);
              read (APP_LINEVARIABLE, packet_info);
              send_packet_length := integer(packet_info);
              read (APP_LINEVARIABLE, packet_info);
              Mem_address_1 := integer(packet_info);
              read (APP_LINEVARIABLE, packet_info);
              Mem_address_2 := integer(packet_info);
              read (APP_LINEVARIABLE, packet_info);
              RW := integer(packet_info);
              read (APP_LINEVARIABLE, packet_info);
              DI := integer(packet_info);
              read (APP_LINEVARIABLE, packet_info);
              ROLE := integer(packet_info);
              sent := False;
            end if;

            --if state = Idle and now  < finish_time and sent = False then
            if state = Idle and now >= gen_time and sent = False then
                send_counter := send_counter+1;
                state :=  Header_flit;
                address <= reserved_address;
                write_byte_enable <= "1111";
                packet_gen_time :=  now;
                data_write <= "0000" &  std_logic_vector(to_unsigned(current_address/network_x, 4)) & std_logic_vector(to_unsigned(current_address mod network_x, 4)) & std_logic_vector(to_unsigned(send_destination_node/network_x, 4)) & std_logic_vector(to_unsigned(send_destination_node mod network_x, 4))&std_logic_vector(to_unsigned(Mem_address_1, 12));
                write(SEND_LINEVARIABLE, "Packet generated at " & time'image(packet_gen_time) & " From " & integer'image(current_address) & " to " & integer'image(send_destination_node) &
                      " with length: "& integer'image(send_packet_length)  & " id: " & integer'image(send_id_counter) & " Mem_address_1: " & integer'image(Mem_address_1)&
                      " Mem_address_2: " & integer'image(Mem_address_2) & " RW: " & integer'image(RW) & " DI: " & integer'image(DI) & " ROLE: " & integer'image(ROLE));
                writeline(SEND_FILE, SEND_LINEVARIABLE);
            elsif state = Header_flit then
                address <= reserved_address;
                write_byte_enable <= "1111";
                data_write <= "0000" &  std_logic_vector(to_unsigned(Mem_address_2, 20)) & std_logic_vector(to_unsigned(RW,1)) & std_logic_vector(to_unsigned(DI,1)) & std_logic_vector(to_unsigned(ROLE,1)) & std_logic_vector(to_unsigned(OPCODE, 5));
                send_counter := send_counter+1;
                state :=  Body_flit_1;
            elsif state = Body_flit_1 then
                address <= reserved_address;
                write_byte_enable <= "1111";
                data_write <= "0000" &  std_logic_vector(to_unsigned(send_packet_length, 14)) & std_logic_vector(to_unsigned(send_id_counter, 14));
                send_counter := send_counter+1;
                if send_counter = send_packet_length-1 then
                    state :=  Tail_flit;
                else
                    state :=  Body_flit;
                end if;
            elsif state = Body_flit then
              address <= reserved_address;
              write_byte_enable <= "1111";
              data_write <= "0000" & std_logic_vector(to_unsigned(integer(rand*1000.0), 28));
              send_counter := send_counter+1;
              if send_counter = send_packet_length-1 then
                  state :=  Tail_flit;
              else
                  state :=  Body_flit;
              end if;
            elsif state = Tail_flit then
              send_counter := 0;
              sent := True;
              state :=  Idle;
              address <= reserved_address;
              write_byte_enable <= "1111";
              data_write <= (others =>'0');
              --data_write <= "0000" & std_logic_vector(to_unsigned(integer(rand*1000.0), 28));
              send_id_counter := send_id_counter + 1;
              if send_id_counter = 16384 then
                send_id_counter := 0;
              end if;
            end if;

          end if;

          wait until clk'event and clk ='0';

      end if;


    end loop;
    file_close(SEND_FILE);
  end NI_control;


end TB_Package;
