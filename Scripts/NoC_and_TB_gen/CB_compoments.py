# Copyright (C) 2016 Siavoosh Payandeh Azad

def declare_components(noc_file):
    """
    writes component deceleration into noc_file
    """
    noc_file.write("component router_credit_based is\n")
    noc_file.write("  generic (\n")
    noc_file.write("        DATA_WIDTH: integer := 32; \n")
    noc_file.write("        FIFO_DEPTH: integer := 4;  \n")
    noc_file.write("        CREDIT_COUNTER_LENGTH: integer := 2;  \n")
    noc_file.write("        CREDIT_COUNTER_LENGTH_LOCAL: integer := 2;  \n")
    noc_file.write("        current_address : integer := 0;\n")
    noc_file.write("        Rxy_rst : integer := 60;\n")
    noc_file.write("        Cx_rst : integer := 10;\n")
    noc_file.write("        NoC_size_x: integer := 4\n")
    noc_file.write("    );\n")
    noc_file.write("    port (\n")
    noc_file.write("    reset, clk: in std_logic; \n\n")
    noc_file.write("    RX_N, RX_E, RX_W, RX_S, RX_L : in std_logic_vector (DATA_WIDTH-1 downto 0); \n")
    noc_file.write("    credit_in_N, credit_in_E, credit_in_W, credit_in_S, credit_in_L: in std_logic;\n")
    noc_file.write("    valid_in_N, valid_in_E, valid_in_W, valid_in_S, valid_in_L : in std_logic;\n\n")
    noc_file.write("    valid_out_N, valid_out_E, valid_out_W, valid_out_S, valid_out_L : out std_logic;\n")
    noc_file.write("    credit_out_N, credit_out_E, credit_out_W, credit_out_S, credit_out_L: out std_logic;\n\n")

    noc_file.write("    TX_N, TX_E, TX_W, TX_S, TX_L: out std_logic_vector (DATA_WIDTH-1 downto 0)\n")
    noc_file.write("    ); \n")
    noc_file.write("end component; \n")

    noc_file.write("\n\n")

    # this for tracking packets in the network
    noc_file.write("component flit_tracker is\n")
    noc_file.write("    generic (\n")
    noc_file.write("        G_DATA_WIDTH   : integer := 32;\n")
    noc_file.write("        G_NET_SIZE_X   : integer := 4;\n")
    noc_file.write("        G_NET_SIZE_Y   : integer := 4;\n")
    noc_file.write("        G_TRACKER_FILE : string :=\"track.txt\"\n")
    noc_file.write("    );\n")
    noc_file.write("    port (\n")
    noc_file.write("        clk: in std_logic;\n")
    noc_file.write("        reset: in std_logic;\n")
    noc_file.write("        rx_in: in std_logic_vector (G_DATA_WIDTH-1 downto 0); \n")
    noc_file.write("        valid_in : in std_logic \n")
    noc_file.write("    );\n")
    noc_file.write("end component;\n")
