--Copyright (C) 2016 Siavoosh Payandeh Azad

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
 use ieee.math_real.all;
 use std.textio.all;
 use ieee.std_logic_misc.all;

package TB_Package is

  --function log2(i : integer) return integer;

  function Header_gen(network_size_x, source, destination, Mem_address: integer)return std_logic_vector;
  function Body_1_gen(Mem_address,OPCODE: integer; RW, DI, ROLE: std_logic) return std_logic_vector;
  function Body_2_gen(Packet_length, packet_id: integer ) return std_logic_vector ;
  function Body_gen(Data: integer) return std_logic_vector;
  function Tail_gen(Data: integer) return std_logic_vector;

  procedure credit_counter_control(signal clk: in std_logic;
                                 signal credit_in: in std_logic; signal valid_out: in std_logic;
                                 signal credit_counter_out: out std_logic_vector(1 downto 0));

  procedure gen_random_packet(network_size_x, network_size_y, frame_length, source, initial_delay, min_packet_size, max_packet_size: in integer;
                      finish_time: in time; signal clk: in std_logic;
                      signal credit_counter_in: in std_logic_vector(1 downto 0); signal valid_out: out std_logic;
                      signal port_in: out std_logic_vector);

   procedure get_packet(network_size_x, DATA_WIDTH, initial_delay, Node_ID: in integer; signal clk: in std_logic;
                     signal credit_out: out std_logic; signal valid_in: in std_logic; signal port_in: in std_logic_vector);
end TB_Package;

package body TB_Package is

  constant Header_type : std_logic_vector := "001";
  constant Body_type   : std_logic_vector := "010";
  constant Tail_type   : std_logic_vector := "100";

  function Header_gen(network_size_x, source, destination, Mem_address: integer)
              return std_logic_vector is
    	variable Header_flit: std_logic_vector (31 downto 0);
      variable source_x, source_y, destination_x, destination_y: integer;

    	begin

      -- We only need network_size_x for calculation of X and Y coordinates of a node!
      source_x      := source       mod  network_size_x;
      source_y      := source       /    network_size_x;
      destination_x := destination  mod  network_size_x;
      destination_y := destination  /    network_size_x;

      Header_flit := Header_type &  std_logic_vector(to_unsigned(source_y,4)) & std_logic_vector(to_unsigned(source_x,4)) &
                     std_logic_vector(to_unsigned(destination_y,4)) & std_logic_vector(to_unsigned(destination_x,4)) & std_logic_vector(to_unsigned(Mem_address,12)) &
                     XOR_REDUCE(Header_type &  std_logic_vector(to_unsigned(source_y,4)) & std_logic_vector(to_unsigned(source_x,4)) &
                     std_logic_vector(to_unsigned(destination_y,4)) & std_logic_vector(to_unsigned(destination_x,4)) & std_logic_vector(to_unsigned(Mem_address,12)));

    return Header_flit;
  end Header_gen;

  function Body_1_gen(Mem_address,OPCODE: integer;
                       RW, DI, ROLE: std_logic)
                return std_logic_vector is
    variable Body_flit: std_logic_vector (31 downto 0);
    begin
    Body_flit := Body_type &  std_logic_vector(to_unsigned(Mem_address, 20))&  RW & DI & ROLE & std_logic_vector(to_unsigned(OPCODE, 5))&
                 XOR_REDUCE(Body_type &  std_logic_vector(to_unsigned(Mem_address, 20))&  RW & DI & ROLE & std_logic_vector(to_unsigned(OPCODE, 5)));
    return Body_flit;
  end Body_1_gen;

  function Body_2_gen(Packet_length, packet_id: integer)
                return std_logic_vector is
    variable Body_flit: std_logic_vector (31 downto 0);
    begin
    Body_flit := Body_type &  std_logic_vector(to_unsigned(Packet_length, 14))&  std_logic_vector(to_unsigned(packet_id, 14)) &
                 XOR_REDUCE(Body_type &  std_logic_vector(to_unsigned(Packet_length, 14))&  std_logic_vector(to_unsigned(packet_id, 14)));
    return Body_flit;
  end Body_2_gen;

  function Body_gen(Data: integer)
                return std_logic_vector is
    variable Body_flit: std_logic_vector (31 downto 0);
    begin
    Body_flit := Body_type &  std_logic_vector(to_unsigned(Data, 28)) & XOR_REDUCE(Body_type & std_logic_vector(to_unsigned(Data, 28)));
    return Body_flit;
  end Body_gen;


  function Tail_gen(Data: integer)
                return std_logic_vector is
    variable Tail_flit: std_logic_vector (31 downto 0);
    begin
    Tail_flit := Tail_type &  std_logic_vector(to_unsigned(Data, 28)) & XOR_REDUCE(Tail_type & std_logic_vector(to_unsigned(Data, 28)));
    return Tail_flit;
  end Tail_gen;

  procedure credit_counter_control(signal clk: in std_logic;
                                   signal credit_in: in std_logic; signal valid_out: in std_logic;
                                   signal credit_counter_out: out std_logic_vector(1 downto 0)) is

    variable credit_counter: std_logic_vector (1 downto 0);

    begin
    credit_counter := "11";

    while true loop
      credit_counter_out<= credit_counter;
      wait until clk'event and clk ='1';
      if valid_out = '1' and credit_in ='1' then
        credit_counter := credit_counter;
      elsif credit_in = '1' then
        credit_counter := credit_counter + 1;
      elsif valid_out = '1' and  credit_counter > 0 then
        credit_counter := credit_counter - 1;
      else
        credit_counter := credit_counter;
      end if;
    end loop;
  end credit_counter_control;

  procedure gen_random_packet(network_size_x, network_size_y, frame_length, source, initial_delay, min_packet_size, max_packet_size: in integer;
                      finish_time: in time; signal clk: in std_logic;
                      signal credit_counter_in: in std_logic_vector(1 downto 0); signal valid_out: out std_logic;
                      signal port_in: out std_logic_vector) is
    variable seed1 :positive := source+1;
    variable seed2 :positive := source+1;
    variable LINEVARIABLE : line;
    file VEC_FILE : text is out "sent.txt";
    variable rand : real ;
    variable destination_id: integer;
    variable Mem_address1, Mem_address2, OPCODE: integer := 0;
    variable id_counter, frame_starting_delay, Packet_length, frame_ending_delay : integer:= 0;
    variable credit_counter: std_logic_vector (1 downto 0);
    begin

    Packet_length := integer((integer(rand*100.0)*frame_length)/100);
    valid_out <= '0';
    port_in <= "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" ;
    wait until clk'event and clk ='1';
    for i in 0 to initial_delay loop
      wait until clk'event and clk ='1';
    end loop;
    port_in <= "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" ;

    while true loop

      --generating the frame initial delay
      uniform(seed1, seed2, rand);
      frame_starting_delay := integer(((integer(rand*100.0)*(frame_length - Packet_length-1)))/100);
      --generating the frame ending delay
      frame_ending_delay := frame_length - (Packet_length+frame_starting_delay);

      for k in 0 to frame_starting_delay-1 loop
          wait until clk'event and clk ='0';
      end loop;

      valid_out <= '0';
      while credit_counter_in = 0 loop
        wait until clk'event and clk ='0';
      end loop;

      -- generating the packet
      id_counter := id_counter + 1;
      if id_counter = 16384 then
          id_counter := 0;
      end if;
      --------------------------------------
      uniform(seed1, seed2, rand);
      Packet_length := integer((integer(rand*100.0)*frame_length)/100);
      if (Packet_length < min_packet_size) then
          Packet_length:=min_packet_size;
      end if;
      if (Packet_length > max_packet_size) then
          Packet_length:=max_packet_size;
      end if;
      --------------------------------------
      uniform(seed1, seed2, rand);
      destination_id := integer(rand*real((network_size_x*network_size_y)-1));
      while (destination_id = source) loop
          uniform(seed1, seed2, rand);
          destination_id := integer(rand*real((network_size_x*network_size_y)-1));
      end loop;
      --------------------------------------
      write(LINEVARIABLE, "Packet generated at " & time'image(now) & " From " & integer'image(source) & " to " & integer'image(destination_id) & " with length: " & integer'image(Packet_length) & " id: " & integer'image(id_counter));
      writeline(VEC_FILE, LINEVARIABLE);
      wait until clk'event and clk ='0'; -- On negative edge of clk (for syncing purposes)
      port_in <= Header_gen(network_size_x, source, destination_id,Mem_address1); -- Generating the header flit of the packet (All packets have a header flit)!
      valid_out <= '1';
      wait until clk'event and clk ='0';

      for I in 0 to Packet_length-3 loop
            -- The reason for -3 is that we have packet length of Packet_length, now if you exclude header and tail
            -- it would be Packet_length-2 to enumerate them, you can count from 0 to Packet_length-3.
            if credit_counter_in = "00" then
             valid_out <= '0';
             -- Wait until next router/NI has at least enough space for one flit in its input FIFO
             wait until credit_counter_in'event and credit_counter_in > 0;
             wait until clk'event and clk ='0';
            end if;

            uniform(seed1, seed2, rand);
            -- Each packet can have no body flits or one or more than body flits.
            if I = 0 then
              port_in <= Body_1_gen(Mem_address2,OPCODE, '0', '0', '0');
            elsif I = 1 then
              port_in <= Body_2_gen(Packet_length, id_counter);
            else
              port_in <= Body_gen(integer(rand*1000.0));
            end if;
             valid_out <= '1';
             wait until clk'event and clk ='0';
      end loop;

      if credit_counter_in = "00" then
             valid_out <= '0';
             -- Wait until next router/NI has at least enough space for one flit in its input FIFO
             wait until credit_counter_in'event and credit_counter_in > 0;
             wait until clk'event and clk ='0';
      end if;


      uniform(seed1, seed2, rand);
      -- Close the packet with a tail flit (All packets have one tail flit)!
      port_in <= Tail_gen(integer(rand*1000.0));
      valid_out <= '1';
      wait until clk'event and clk ='0';

      valid_out <= '0';
      port_in <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" ;

      for l in 0 to frame_ending_delay-1 loop
         wait until clk'event and clk ='0';
      end loop;
      port_in <= "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU" ;

      if now > finish_time then
          wait;
      end if;
    end loop;
  end gen_random_packet;



  procedure get_packet(network_size_x, DATA_WIDTH, initial_delay, Node_ID: in integer; signal clk: in std_logic;
                       signal credit_out: out std_logic; signal valid_in: in std_logic; signal port_in: in std_logic_vector) is
  -- initial_delay: waits for this number of clock cycles before sending the packet!
    variable source_node_x, source_node_y, destination_node_x, destination_node_y, source_node, destination_node, Mem_address_1:  integer; -- everything in header
    variable Mem_address_2, RW, DI, ROLE, OPCODE: integer; -- Everything in Body 1
    variable P_length, packet_id: integer; -- everything in Body 2
    variable counter: integer;
    variable LINEVARIABLE : line;
     file VEC_FILE : text is out "received.txt";
     begin
     credit_out <= '1';
     counter := 0;
     while true loop

         wait until clk'event and clk ='1';

         if valid_in = '1' then
              if (port_in(DATA_WIDTH-1 downto DATA_WIDTH-3) = "001") then
                counter := 1;

                source_node_y := to_integer(unsigned(port_in(28 downto 25)));
                source_node_x := to_integer(unsigned(port_in(24 downto 21)));
                destination_node_y := to_integer(unsigned(port_in(20 downto 17)));
                destination_node_x := to_integer(unsigned(port_in(16 downto 13)));
                Mem_address_1 := to_integer(unsigned(port_in(12 downto 1)));
                -- We only needs network_size_x for computing the node ID (convert from (X,Y) coordinate to Node ID)!
                source_node := (source_node_y * network_size_x) + source_node_x;
                destination_node := (destination_node_y * network_size_x) + destination_node_x;

            end if;
            if  (port_in(DATA_WIDTH-1 downto DATA_WIDTH-3) = "010")   then
               if counter = 1 then
                  Mem_address_2 := to_integer(unsigned(port_in(28 downto 9)));
                  OPCODE := to_integer(unsigned(port_in(5 downto 1)));
                  RW := 0;
                  DI := 0;
                  ROLE := 0;
                  if port_in(8) = '1' then
                    RW := 1;
                  end if;
                  if port_in(7) = '1' then
                    DI := 1;
                  end if;
                  if port_in(6) = '1' then
                    ROLE := 1;
                  end if;
               elsif counter = 2 then
                  P_length := to_integer(unsigned(port_in(28 downto 15)));
                  packet_id := to_integer(unsigned(port_in(15 downto 1)));
               end if;
               counter := counter+1;

            end if;
            if (port_in(DATA_WIDTH-1 downto DATA_WIDTH-3) = "100") then
                counter := counter+1;
              report "Node: " & integer'image(Node_ID) & "    Packet received at " & time'image(now) & " From " & integer'image(source_node) & " to " & integer'image(destination_node) & " with length: "& integer'image(P_length) & " counter: "& integer'image(counter);
              assert (P_length=counter) report "wrong packet size" severity warning;
              assert (Node_ID=destination_node) report "wrong packet destination " severity warning;

              write(LINEVARIABLE, "Packet received at " & time'image(now) & " From: " & integer'image(source_node) & " to: " & integer'image(destination_node) &
                                  " length: "& integer'image(P_length) & " actual length: "& integer'image(counter)  & " id: "& integer'image(packet_id) &
                                  " MEM_address_1: "& integer'image(Mem_address_1) & " MEM_address_2: "& integer'image(Mem_address_2) & " RW: "& integer'image(RW) &
                                  " DI: "& integer'image(DI) &" ROLE: "& integer'image(ROLE) &" OPCODE: "& integer'image(OPCODE));
              writeline(VEC_FILE, LINEVARIABLE);
               counter := 0;
            end if;
         end if;

     end loop;
  end get_packet;

end TB_Package;
