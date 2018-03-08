---------------------------------------------------------------------
-- TITLE: Plasma Misc. Package
-- Main AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 2/15/01
-- FILENAME: mlite_pack.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    Data types, constants, and add functions needed for the Plasma CPU.

-- modified by: Siavoosh Payandeh Azad
-- Change logs:
--            * An NI has been added to the file as a new module
--            * some changes has been applied to the ports of the older modules
--              to facilitate the new module!
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package router_pack is

  COMPONENT FIFO_credit_based is
    generic (
        DATA_WIDTH: integer := 32;
        FIFO_DEPTH : integer := 4 -- FIFO counter size for read and write pointers would also be the same as FIFO depth, because of one-hot encoding of them!
    );
    port (  reset: in  std_logic;
            clk: in  std_logic;
            RX: in std_logic_vector(DATA_WIDTH-1 downto 0);

            valid_in: in std_logic;
            valid_in_vc: in std_logic;

            read_en : in std_logic;
            read_en_vc : in std_logic;

            credit_out: out std_logic;
            credit_out_vc: out std_logic;

            empty_out: out std_logic;
            empty_out_vc: out std_logic;

            Data_out: out std_logic_vector(DATA_WIDTH-1 downto 0);
            Data_out_vc: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end COMPONENT;

  COMPONENT arbiter_in is
      generic (
          CREDIT_COUNTER_LENGTH: integer := 2
      );
      port (  reset: in  std_logic;
              clk: in  std_logic;
              Req_X_N, Req_X_E, Req_X_W, Req_X_S, Req_X_L:in std_logic; -- From LBDR modules
              credit_counter_N, credit_counter_E, credit_counter_W, credit_counter_S: in std_logic_vector (CREDIT_COUNTER_LENGTH-1 downto 0);
              X_N, X_E, X_W, X_S, X_L:out std_logic -- Grants given to LBDR requests (encoded as one-hot)
              );
  end COMPONENT;

  COMPONENT arbiter_out is
      generic (
          CREDIT_COUNTER_LENGTH: integer := 2
      );
      port (  reset: in  std_logic;
              clk: in  std_logic;
              X_N_Y, X_E_Y, X_W_Y, X_S_Y, X_L_Y:in std_logic; -- From LBDR modules
              credit: in std_logic_vector(CREDIT_COUNTER_LENGTH-1 downto 0);
              grant_Y_N, grant_Y_E, grant_Y_W, grant_Y_S, grant_Y_L :out std_logic -- Grants given to LBDR requests (encoded as one-hot)
              );
  end COMPONENT;

  COMPONENT allocator is
    generic (
      FIFO_DEPTH : integer := 4; -- FIFO counter size for read and write pointers would also be the same as FIFO depth, because of one-hot encoding of them!
      CREDIT_COUNTER_LENGTH : integer := 2
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
end COMPONENT;

 COMPONENT LBDR is
   generic (
       cur_addr_rst: integer := 8;
       Rxy_rst: integer := 8;
       Cx_rst: integer := 8
   );
   port (  reset: in  std_logic;
           clk: in  std_logic;
           empty: in  std_logic;
           flit_type: in std_logic_vector(2 downto 0);
           cur_addr_y, cur_addr_x: in std_logic_vector(3 downto 0);
           dst_addr_y, dst_addr_x: in std_logic_vector(3 downto 0);
           grants: in std_logic;
           Req_N, Req_E, Req_W, Req_S, Req_L:out std_logic
           );
  end COMPONENT;

  COMPONENT XBAR is
    generic (
        DATA_WIDTH: integer := 32
    );
    port (
        North_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        East_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        West_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        South_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        Local_in: in std_logic_vector(DATA_WIDTH-1 downto 0);

        North_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        East_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        West_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        South_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
        Local_vc_in: in std_logic_vector(DATA_WIDTH-1 downto 0);

        sel: in std_logic_vector (9 downto 0);
        Data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end COMPONENT;

  COMPONENT NI_vc is
     generic(FIFO_DEPTH: in integer := 4;
             CREDIT_COUNTER_LENGTH: in integer := 2;
             current_x : integer := 10; 	-- the current node's x
             current_y : integer := 10; 	-- the current node's y
             network_x : integer := 4;    -- the number of nodes along x direction in the NoC
             NI_depth : integer := 32;    -- The depth of NI's FIFO in terms of flit slots
             NI_couter_size: integer:= 5; -- should be set to log2 of NI_depth
             reserved_address : std_logic_vector(29 downto 0)    := "000000000000000001111111111110"; -- NI's memory mapped reserved VC_0
             reserved_address_vc : std_logic_vector(29 downto 0) := "000000000000000001111111111111"; -- NI's memory mapped reserved for VC_1
             flag_address : std_logic_vector(29 downto 0)        := "000000000000000010000000000000";  -- reserved address for the flag register
             counter_address : std_logic_vector(29 downto 0)     := "000000000000000010000000000001");  -- packet counter register address!
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
          credit_in_vc: in std_logic;
          valid_out_vc: out std_logic;
          TX: out std_logic_vector(31 downto 0);	-- data sent to the NoC

          -- signals for reciving packets from the network
          credit_out : out std_logic;
          valid_in: in std_logic;
          credit_out_vc: out std_logic;
          valid_in_vc: in std_logic;
          RX: in std_logic_vector(31 downto 0)	-- data recieved form the NoC

  	);
  end COMPONENT; --entity NI_vc

end; --package body
