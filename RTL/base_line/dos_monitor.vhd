
--------------------------------------------------------------------------------
--
-- File name: dos_monitor.vhd
--
-- Copyright (C) 2018
-- Cesar Giovanni Chaves Arroyave (cesar.chaves@stud.fra-uas.de)
-- Siavoosh Payandeh Azad (siavoosh@ati.ttu.ee)
--
-- Creation date: 04 Jul 2018
-- Description: This code describes the DoS Monitor block.
--
--------------------------------------------------------------------------------

--==============================================================================
-- Libraries
--==============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.router_pack.all;
use ieee.std_logic_misc.all;

--==============================================================================
-- Entity Declaration of the DoS Monitor
--==============================================================================
entity dos_monitor is
  generic (
    G_DATA_WIDTH      : integer := 32;
    G_ROUTER_ADDRESS  : integer := 0;
    G_MONITORED_INPUT : std_logic_vector (4 downto 0)
    );
  port (
    -- Control signals
    reset, clk : in std_logic;

    -- Input signals
    valid_in                                                                       : in std_logic;
    rx_in                                                                          : in std_logic_vector (G_DATA_WIDTH-1 downto 0);
    fifo_data_in                                                                   : in std_logic_vector (G_DATA_WIDTH-1 downto 0);
    req_from_n_in, req_from_e_in, req_from_w_in, req_from_s_in, req_from_l_in      : in std_logic_vector (4 downto 0);
    grant_for_n_in, grant_for_e_in, grant_for_w_in, grant_for_s_in, grant_for_l_in : in std_logic_vector (4 downto 0);

    -- Output signal
    tx_out : out std_logic_vector (G_DATA_WIDTH-1 downto 0)
    );
end dos_monitor;

--==============================================================================
-- RTL architecture declaration
--==============================================================================
architecture behavior of dos_monitor is

  --==========================================================================
  -- Declaration of internal signals
  --==========================================================================
  signal my_requests           : std_logic_vector (4 downto 0);
  signal my_grants             : std_logic_vector (4 downto 0);
  signal my_competitors_grants : std_logic_vector (4 downto 0);
  signal pres_delay_counter    : unsigned(9 downto 0);
  signal next_delay_counter    : unsigned(9 downto 0);

begin

  --==========================================================================
  -- Process dos_monitor_seq is Sequential
  -- Description: Updates the registers of the DoS Monitor
  -- Read: clk, reset, next_delay_counter
  -- Write: pres_delay_counter
  --==========================================================================
  dos_monitor_seq : process (clk, reset)
  begin
    if reset = '0' then
      pres_delay_counter <= (others => '0');
    elsif clk'event and clk = '1' then
      pres_delay_counter <= next_delay_counter;
    end if;
  end process;

  --==========================================================================
  -- process dos_monitor_comb is Combinational
  -- Description: Updates tx_out
  -- Read: rx_in, valid_in, pres_delay_counter
  -- Write: tx_out
  --==========================================================================
  dos_monitor_comb : process (pres_delay_counter, rx_in, valid_in)
    variable v_tx : std_logic_vector (G_DATA_WIDTH-1 downto 0);
  begin
    tx_out <= rx_in;
    v_tx   := (others => '0');
    if valid_in = '1' and rx_in(G_DATA_WIDTH-1 downto G_DATA_WIDTH-3) = "100" then
      if to_integer(pres_delay_counter) > to_integer(unsigned(rx_in(G_DATA_WIDTH-12 downto G_DATA_WIDTH-21))) then
        v_tx                                          := (others => '0');
        v_tx (G_DATA_WIDTH-1)                         := '1';
        v_tx (G_DATA_WIDTH-4 downto G_DATA_WIDTH-11)  := std_logic_vector(to_unsigned(G_ROUTER_ADDRESS, 8));
        v_tx (G_DATA_WIDTH-12 downto G_DATA_WIDTH-21) := std_logic_vector(pres_delay_counter);
        v_tx (0)                                      := XOR_REDUCE(v_tx);
        tx_out                                        <= v_tx;
      end if;
    end if;
  end process;

  --==========================================================================
  -- process counter_ctrl_comb is Combinational
  -- Description: Updates counter related combinational logic
  -- Read: pres_delay_counter, valid_in, rx_in, my_competitors_grants
  -- Write: next_delay_counter
  --==========================================================================
  counter_ctrl_comb : process (my_competitors_grants, pres_delay_counter,
                               rx_in(G_DATA_WIDTH-1 downto G_DATA_WIDTH-3),
                               valid_in)
  begin

    next_delay_counter <= pres_delay_counter;

    if valid_in = '1' and rx_in(G_DATA_WIDTH-1 downto G_DATA_WIDTH-3) = "001" then
      next_delay_counter <= (others => '0');
    elsif (my_competitors_grants /= "00000") and pres_delay_counter /= "1111111111" then
      next_delay_counter <= pres_delay_counter + 1;
    end if;

  end process;

  --==========================================================================
  -- process my_reques_comb is Combinational
  -- Description: Reports which output the monitored FIFO requested
  -- Read: req_from_n_in, req_from_e_in, req_from_w_in, req_from_s_in, req_from_l_in
  -- Write: my_requests
  --==========================================================================
  my_requests_comb : process (req_from_e_in, req_from_l_in, req_from_n_in,
                              req_from_s_in, req_from_w_in)
  begin
    case (G_MONITORED_INPUT) is  -- To which FIFO is the DoS monitor connected?
      when "10000" => my_requests <= req_from_n_in;  -- North
      when "01000" => my_requests <= req_from_e_in;  -- East
      when "00100" => my_requests <= req_from_w_in;  -- West
      when "00010" => my_requests <= req_from_s_in;  -- South
      when others  => my_requests <= req_from_l_in;  -- Local
    end case;
  end process;

  --==========================================================================
  -- process my_grants_comb is Combinational
  -- Description: Reports which output grants the monitored FIFO received
  -- Read: grant_for_n_in, grant_for_e_in, grant_for_w_in, grant_for_s_in, 
  --       grant_for_l_in
  -- Write: my_grants
  --==========================================================================
  my_grants_comb : process (grant_for_n_in, grant_for_e_in, grant_for_w_in, 
                            grant_for_s_in, grant_for_l_in)

  begin
    case (G_MONITORED_INPUT) is  -- To which FIFO is the DoS monitor connected?
      when "10000" =>                   -- North
        my_grants <= grant_for_n_in(4) & grant_for_e_in(4) & grant_for_w_in(4)
                     & grant_for_s_in(4) & grant_for_l_in(4);
      when "01000" =>                   -- East
        my_grants <= grant_for_n_in(3) & grant_for_e_in(3) & grant_for_w_in(3)
                     & grant_for_s_in(3) & grant_for_l_in(3);
      when "00100" =>                   -- West
        my_grants <= grant_for_n_in(2) & grant_for_e_in(2) & grant_for_w_in(2)
                     & grant_for_s_in(2) & grant_for_l_in(2);
      when "00010" =>                   -- South
        my_grants <= grant_for_n_in(1) & grant_for_e_in(1) & grant_for_w_in(1)
                     & grant_for_s_in(1) & grant_for_l_in(1);
      when others =>                    -- Local
        my_grants <= grant_for_n_in(0) & grant_for_e_in(0) & grant_for_w_in(0)
                     & grant_for_s_in(0) & grant_for_l_in(0);
    end case;
  end process;

  --==========================================================================
  -- process my_competitors_comb is Combinational
  -- Description: Reports who is requesting a grant for my desired output
  --              and who has been granted access
  -- Read: my_requests, grant_for_n_in, grant_for_e_in, grant_for_w_in, 
  --       grant_for_s_in, grant_for_l_in
  -- Write: my_competitors_requests, my_competitors_grants
  --==========================================================================
  my_competitors_comb : process(grant_for_n_in, grant_for_e_in, grant_for_w_in,
                                grant_for_s_in, grant_for_l_in, my_requests)
    variable v_my_competitors_grants : std_logic_vector (4 downto 0);
  begin
    case (my_requests) is
      when "10000" => v_my_competitors_grants := grant_for_n_in;
      when "01000" => v_my_competitors_grants := grant_for_e_in;
      when "00100" => v_my_competitors_grants := grant_for_w_in;
      when "00010" => v_my_competitors_grants := grant_for_s_in;
      when others  => v_my_competitors_grants := grant_for_l_in;
    end case;
    my_competitors_grants <= v_my_competitors_grants and not G_MONITORED_INPUT;
  end process;
end;
