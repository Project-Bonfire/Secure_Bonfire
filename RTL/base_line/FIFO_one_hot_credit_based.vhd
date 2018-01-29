--Copyright (C) 2016 Siavoosh Payandeh Azad

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
  
entity FIFO_credit_based is
    generic (
        DATA_WIDTH: integer := 32; 
        FIFO_DEPTH : integer := 4 -- FIFO counter size for read and write pointers would also be the same as FIFO depth, because of one-hot encoding of them!
    );
    port (  reset: in  std_logic;
            clk: in  std_logic;
            RX: in std_logic_vector(DATA_WIDTH-1 downto 0); 
            valid_in: in std_logic;  
            read_en_N : in std_logic;
            read_en_E : in std_logic;
            read_en_W : in std_logic;
            read_en_S : in std_logic;
            read_en_L : in std_logic;
            credit_out: out std_logic; 
            empty_out: out std_logic; 
            Data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end FIFO_credit_based;

architecture behavior of FIFO_credit_based is
   signal read_pointer, read_pointer_in,  write_pointer, write_pointer_in: std_logic_vector(FIFO_DEPTH-1 downto 0);
   signal full, empty: std_logic;
   signal read_en, write_en: std_logic;

   type MEM is array (0 to FIFO_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);

   signal FIFO_MEM, FIFO_MEM_in : MEM;

   function one_hot_to_binary (
                                 One_Hot : std_logic_vector ;
                                 size    : natural
                                ) return std_logic_vector is

      variable Bin_Vec_Var : std_logic_vector(size-1 downto 0);
    begin
      Bin_Vec_Var := (others => '0');
      for I in One_Hot'range loop
        if One_Hot(I) = '1' then
          Bin_Vec_Var := Bin_Vec_Var or std_logic_vector(to_unsigned(I,size));
        end if;
      end loop;
      return Bin_Vec_Var;
    end function;

    function log2( i : integer) return integer is 
        variable temp    : integer := i; 
        variable ret_val : integer := 1; --log2 of 0 should equal 1 because you still need 1 bit to represent 0 
      begin                  
        while temp > 1 loop 
          ret_val := ret_val + 1; 
          temp    := temp / 2;      
        end loop; 
         
        return ret_val; 
    end function; 

begin

 --------------------------------------------------------------------------------------------
--                           block diagram of the FIFO!


 --------------------------------------------------------------------------------------------
--  circular buffer structure
--                                   <--- WriteP    
--              ---------------------------------
--              |   3   |   2   |   1   |   0   |
--              ---------------------------------
--                                   <--- readP   
 --------------------------------------------------------------------------------------------

   process (clk, reset)begin
        if reset = '0' then
            read_pointer  <= (others=>'0');
            write_pointer <= (others=>'0');
            read_pointer (0) <= '1';
            write_pointer(0) <= '1';

            FIFO_MEM  <= (others => (others=>'0'));

            credit_out <= '0';

        elsif clk'event and clk = '1' then
            write_pointer <= write_pointer_in;
            read_pointer  <=  read_pointer_in;
            credit_out <= '0';
            if write_en = '1' then 
                --write into the memory
                FIFO_MEM<= FIFO_MEM_in;                   
            end if;
            if read_en = '1' then 
              credit_out <= '1';
            end if;
        end if;
    end process;

 -- anything below here is pure combinational
 
  -- combinatorial part

  -- Writing to FIFO
  process(FIFO_MEM, write_pointer, RX) begin
    FIFO_MEM_in <= FIFO_MEM;
    FIFO_MEM_in(to_integer(unsigned(one_hot_to_binary(write_pointer,log2(FIFO_DEPTH))))) <= RX;
  end process;

  -- Reading from FIFO
  Data_out <= FIFO_MEM(to_integer(unsigned(one_hot_to_binary(read_pointer,log2(FIFO_DEPTH)))));

  read_en <= (read_en_N or read_en_E or read_en_W or read_en_S or read_en_L) and not empty; 
  empty_out <= empty;
  

  process(write_en, write_pointer) begin
    if write_en = '1'then
       write_pointer_in <= write_pointer(FIFO_DEPTH - 2 downto 0) & write_pointer(FIFO_DEPTH - 1); 
    else
       write_pointer_in <= write_pointer; 
    end if;
  end process;

  process(read_en, empty, read_pointer)begin
       if (read_en = '1' and empty = '0') then
           read_pointer_in <= read_pointer(FIFO_DEPTH - 2 downto 0) & read_pointer(FIFO_DEPTH - 1); 
       else 
           read_pointer_in <= read_pointer; 
       end if;
  end process;

  process(full, valid_in) begin
     if valid_in = '1' and full ='0' then
         write_en <= '1';
     else
         write_en <= '0';
     end if;        
  end process;
                        
  process(write_pointer, read_pointer) begin
      if read_pointer = write_pointer  then
              empty <= '1';
      else
              empty <= '0';
      end if;

      if write_pointer = read_pointer(0) & read_pointer(FIFO_DEPTH - 1 downto 1) then
              full <= '1';
      else
              full <= '0'; 
      end if; 
  end process;

end;
