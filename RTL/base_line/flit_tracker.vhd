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
    G_NET_SIZE_X   : integer := 4;
    G_NET_SIZE_Y   : integer := 4;
    G_DATA_WIDTH   : integer := 32;    
    G_TRACKER_FILE : string  := "track.txt"
    );
  port (
    clk      : in std_logic;
    reset    : in std_logic;
    rx_in    : in std_logic_vector (G_DATA_WIDTH-1 downto 0);
    valid_in : in std_logic
    );
end;

architecture behavior of flit_tracker is

  signal main_counter : unsigned(27 downto 0);

begin

  --==========================================================================
  -- process main_counter_seq is Sequential
  -- Description: Updates main counter
  -- Read: 
  -- Write: main_counter
  --==========================================================================
  main_counter_seq : process (clk, reset)
  begin

    if reset = '0' then
      main_counter <= (others => '0');
    elsif clk'event and clk = '1' then
      if main_counter /= "1111111111111111111111111111" then
        main_counter <= main_counter + 1;
      else
        main_counter <= (others => '0');
      end if;
    end if;

  end process;


  process(clk)
    variable source_y, source_x, destination_y, destination_x : integer := 0;
    variable src_router, dest_router                          : integer := 0;
    variable Mem_address1, Mem_address2, opcode               : integer := 0;
    variable Packet_length, packet_id                         : integer := 0;
    variable packet_timestamp                                 : unsigned(27 downto 0);
    variable clock_value_upon_arrival                         : unsigned(27 downto 0);
    variable packet_transmission_latency                      : unsigned(27 downto 0);
    variable max_latency, max_router                          : integer;
    variable comp_requests, comp_grants                       : unsigned(4 downto 0);
    variable xor_check                                        : std_logic;
    variable body_flit_number                                 : integer := 0;
    -- file handeling
    file trace_file                                           : text is out G_TRACKER_FILE;
    variable LINEVARIABLE                                     : line;
  begin
    --Packet_length := 0;

--    Mem_address1 := 0;
--    Mem_address2 := 0;
--    opcode       := 0;
--    packet_id    := 0;
--    max_latency  := 0;
--    max_router   := 0;

    if clk'event and clk = '1' then  -- checks the link status on the rising edge of the clock!
      if unsigned(rx_in) /= to_unsigned(0, rx_in'length) and valid_in = '1' then

        -- =====================================================================
        -- If it is a header Flit
        -- =====================================================================
        if rx_in(G_DATA_WIDTH-1 downto G_DATA_WIDTH-3) = "001" then  -- header received!

          clock_value_upon_arrival := main_counter;
          source_y                 := to_integer(unsigned(rx_in(28 downto 25)));
          source_x                 := to_integer(unsigned(rx_in(24 downto 21)));
          destination_y            := to_integer(unsigned(rx_in(20 downto 17)));
          destination_x            := to_integer(unsigned(rx_in(16 downto 13)));
          Mem_address1             := to_integer(unsigned(rx_in(12 downto 1)));
          xor_check                := XOR_REDUCE(rx_in(G_DATA_WIDTH-1 downto 1));
          src_router               := source_x + source_y * G_NET_SIZE_Y;
          dest_router              := destination_x + destination_y * G_NET_SIZE_Y;

          if xor_check = rx_in(0) then     -- the flit is healthy
            write(LINEVARIABLE,
                  "H " & time'image(now) & " " &
                  integer'image(src_router) & " " &integer'image(dest_router) & " " &
                  integer'image(source_x) & " " &integer'image(source_y) & " " &
                  integer'image(destination_x) & " " &integer'image(destination_y) & " " &
                  integer'image(Mem_address1));
          else
            write(LINEVARIABLE,
                  "H " & time'image(now) & " " &
                  integer'image(src_router) & " " &integer'image(dest_router) & " " &
                  integer'image(source_x) & " " &integer'image(source_y) & " " &
                  integer'image(destination_x) & " " &integer'image(destination_y) & " " &
                  integer'image(Mem_address1) & " FAULTY ");
          end if;
          writeline(trace_file, LINEVARIABLE);
          body_flit_number := 1;

          -- =====================================================================
          -- If it is a body Flit
          -- =====================================================================
        elsif rx_in(G_DATA_WIDTH-1 downto G_DATA_WIDTH-3) = "010" then
          xor_check := XOR_REDUCE(rx_in(G_DATA_WIDTH-1 downto 1));

          -- First Body Flit
          if body_flit_number = 1 then
            Mem_address2 := to_integer(unsigned(rx_in(28 downto 9)));
            opcode       := to_integer(unsigned(rx_in(5 downto 1)));

            if xor_check = rx_in(0) then   -- the flit is healthy
              write(LINEVARIABLE, "B1 " & time'image(now) & " " &
                    integer'image(Mem_address2) & " " &
                    integer'image(to_integer(unsigned(rx_in(8 downto 8)))) & " " &
                    integer'image(to_integer(unsigned(rx_in(7 downto 7)))) & " " &
                    integer'image(to_integer(unsigned(rx_in(6 downto 6)))) & " " &
                    integer'image(opcode));
            else
              write(LINEVARIABLE, "B1 " & time'image(now) & " " &
                    integer'image(Mem_address2) & " " &
                    integer'image(to_integer(unsigned(rx_in(8 downto 8)))) & " " &
                    integer'image(to_integer(unsigned(rx_in(7 downto 7)))) & " " &
                    integer'image(to_integer(unsigned(rx_in(6 downto 6)))) & " " &
                    integer'image(opcode) & " FAULTY ");
            end if;

            -- Second Body Flit
          elsif body_flit_number = 2 then

            Packet_length := to_integer(unsigned(rx_in(28 downto 15)));
            packet_id     := to_integer(unsigned(rx_in(14 downto 1)));

            if xor_check = rx_in(0) then   -- the flit is healthy
              write(LINEVARIABLE, "B2 " & time'image(now) & " " &
                    integer'image(Packet_length) & " " &
                    integer'image(packet_id)); 
            else
              write(LINEVARIABLE, "B2 " & time'image(now) & " " &
                    integer'image(Packet_length) & " " &
                    integer'image(packet_id) & " FAULTY ");
            end if;

            -- Last Body Flit
          elsif (body_flit_number - packet_length) = 3 then

            packet_timestamp := unsigned(rx_in(28 downto 1));

            if xor_check = rx_in(0) then   -- the flit is healthy

              if (packet_timestamp <= clock_value_upon_arrival) then
                packet_transmission_latency := clock_value_upon_arrival - packet_timestamp;
              else
                packet_transmission_latency := clock_value_upon_arrival + (268435455 - packet_timestamp);
              end if;

              write(LINEVARIABLE, "BL " & time'image(now) & " " & 
                    integer'image(to_integer(packet_timestamp)));
            else
              write(LINEVARIABLE, "BL " & time'image(now) & " " &
                    integer'image(to_integer(packet_timestamp)) & " FAULTY ");
            end if;

          else

            if xor_check = rx_in(0) then   -- the flit is healthy
              write(LINEVARIABLE, "B " & time'image(now) & " " & integer'image(to_integer(unsigned(rx_in(28 downto 1)))));
            else
              write(LINEVARIABLE, "B " & time'image(now) & " " & integer'image(to_integer(unsigned(rx_in(28 downto 1)))) & " FAULTY ");
            end if;

          end if;
          writeline(trace_file, LINEVARIABLE);
          body_flit_number := body_flit_number +1;

          -- =====================================================================
          -- If it is a tail Flit
          -- =====================================================================
        elsif rx_in(G_DATA_WIDTH-1 downto G_DATA_WIDTH-3) = "100" then
          xor_check   := XOR_REDUCE(rx_in(G_DATA_WIDTH-1 downto 1));
          max_router  := to_integer(unsigned(rx_in(G_DATA_WIDTH-4 downto G_DATA_WIDTH-11)));
          max_latency := to_integer(unsigned(rx_in(G_DATA_WIDTH-12 downto G_DATA_WIDTH-21)));

          -- If the parity check passes
          if xor_check = rx_in(0) then
            
            write(LINEVARIABLE,
                  "T " & time'image(now) & " " &
                  integer'image(max_router) & " " &
                  integer'image(max_latency));  --& " " &
            writeline(trace_file, LINEVARIABLE);

            write(LINEVARIABLE,
                  "R " & time'image(now) & " " &
                  integer'image(src_router) & " " &integer'image(dest_router) & " " &
                  integer'image(source_x) & " " &integer'image(source_y) & " " &
                  integer'image(destination_x) & " " &integer'image(destination_y) & " " &
                  integer'image(packet_id) & " " &
                  integer'image(packet_length) & " " &
                  integer'image(to_integer(packet_transmission_latency)) & " " & 
                  integer'image(max_router) & " " &
                  integer'image(max_latency) & " " &
                  --integer'image(to_integer(clock_value_upon_arrival)) & " " &
                  --integer'image(to_integer(packet_timestamp)) );
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-22 downto G_DATA_WIDTH-22)))) &
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-23 downto G_DATA_WIDTH-23)))) &
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-24 downto G_DATA_WIDTH-24)))) &
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-25 downto G_DATA_WIDTH-25)))) &
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-26 downto G_DATA_WIDTH-26)))) &
                  " " &
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-27 downto G_DATA_WIDTH-27)))) &
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-28 downto G_DATA_WIDTH-28)))) &
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-29 downto G_DATA_WIDTH-29)))) &
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-30 downto G_DATA_WIDTH-30)))) &
                  integer'image(to_integer(unsigned(rx_in(G_DATA_WIDTH-31 downto G_DATA_WIDTH-31)))));

            -- If the parity check doesn't pass
          else
            write(LINEVARIABLE,
                  "T " & time'image(now) & " " &
                  integer'image(max_router) & " " &
                  integer'image(max_latency) & " FAULTY ");
            writeline(trace_file, LINEVARIABLE);
            write(LINEVARIABLE,
                  "R " & time'image(now) & " " &
                  integer'image(source_x) & " " &integer'image(source_y) & " " &
                  integer'image(destination_x) & " " &integer'image(destination_y) & " " &
                  integer'image(packet_id) & " " &
                  integer'image(packet_length) & " " &
                  integer'image(to_integer(packet_transmission_latency)) & " " & " FAULTY "); 
          end if;
          writeline(trace_file, LINEVARIABLE);

          src_router                  := 0;
          dest_router                 := 0;
          source_x                    := 0;
          source_y                    := 0;
          destination_x               := 0;
          destination_y               := 0;
          Packet_length               := 0;
          clock_value_upon_arrival    := (others => '0');
          packet_transmission_latency := (others => '0');
        end if;

      end if;
    end if;
  end process;
end;
