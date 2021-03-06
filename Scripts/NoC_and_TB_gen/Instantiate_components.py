# Copyright (C) 2016 Siavoosh Payandeh Azad
from CB_functions import rxy_rst_calculator, cx_rst_calculator
import math


def instantiate_routers(noc_file, network_dime_x, network_dime_y, fifo_depth, routing):
    """
    Instantiates the different routers based on the specified configuration!
    noc_file:      string   : destination file
    network_dime_x:  integer  : No. of nodes alone X axis
    network_dime_y:  integer  : No. of nodes alone Y axis
    """
    noc_file.write("-- instantiating the routers\n")
    for i in range(0, network_dime_x*network_dime_y):

        noc_file.write("R_"+str(i)+": router_credit_based generic map (DATA_WIDTH  => DATA_WIDTH, FIFO_DEPTH => FIFO_DEPTH, CREDIT_COUNTER_LENGTH => CREDIT_COUNTER_LENGTH, "+
                                      "CREDIT_COUNTER_LENGTH_LOCAL=> CREDIT_COUNTER_LENGTH_LOCAL, ")

        # Uses deadlock-free routing algorithms/turn models (uniform turn model for all nodes).
        if routing == 'xy':
          noc_file.write("current_address=>"+str(i)+", " + "Cx_rst => "+str(cx_rst_calculator(i, network_dime_x, network_dime_y))+",Rxy_rst => 60, NoC_size_x => "+str(network_dime_x)+")\n")
        elif routing == 'yx':
          noc_file.write("current_address=>"+str(i)+", " + "Cx_rst => "+str(cx_rst_calculator(i, network_dime_x, network_dime_y))+",Rxy_rst => 195, NoC_size_x => "+str(network_dime_x)+")\n")
        elif routing == 'wf':
          noc_file.write("current_address=>"+str(i)+", " + "Cx_rst => "+str(cx_rst_calculator(i, network_dime_x, network_dime_y))+",Rxy_rst => 125, NoC_size_x => "+str(network_dime_x)+")\n")
        elif routing == 'nl':
          noc_file.write("current_address=>"+str(i)+", " + "Cx_rst => "+str(cx_rst_calculator(i, network_dime_x, network_dime_y))+",Rxy_rst => 252, NoC_size_x => "+str(network_dime_x)+")\n")
        elif routing == 'nf':
          noc_file.write("current_address=>"+str(i)+", " + "Cx_rst => "+str(cx_rst_calculator(i, network_dime_x, network_dime_y))+",Rxy_rst => 245, NoC_size_x => "+str(network_dime_x)+")\n")
        elif routing == 'sr': # To be fixed!
          noc_file.write("current_address=>"+str(i)+", " + "Cx_rst => "+str(cx_rst_calculator(i, network_dime_x, network_dime_y))+",Rxy_rst => 215, NoC_size_x => "+str(network_dime_x)+")\n")

        noc_file.write("PORT MAP (reset, clk, \n")
        noc_file.write("\tRX_N_"+str(i)+", RX_E_"+str(i)+", RX_W_"+str(i)+", RX_S_"+str(i)+", RX_L_"+str(i)+",\n")
        noc_file.write("\tcredit_in_N_"+str(i)+", credit_in_E_"+str(i)+", credit_in_W_"+str(i) +
                       ", credit_in_S_"+str(i)+", credit_in_L_"+str(i)+",\n")
        noc_file.write("\tvalid_in_N_"+str(i)+", valid_in_E_"+str(i)+", valid_in_W_"+str(i) +
                       ", valid_in_S_"+str(i)+", valid_in_L_"+str(i)+",\n")
        noc_file.write("\tvalid_out_N_"+str(i)+", valid_out_E_"+str(i)+", valid_out_W_"+str(i) +
                       ", valid_out_S_"+str(i)+", valid_out_L_"+str(i)+",\n")
        noc_file.write("\tcredit_out_N_"+str(i)+", credit_out_E_"+str(i)+", credit_out_W_"+str(i) +
                       ", credit_out_S_"+str(i)+", credit_out_L_"+str(i)+",\n")

        noc_file.write("\tTX_N_"+str(i)+", TX_E_"+str(i)+", TX_W_"+str(i)+", TX_S_"+str(i)+", TX_L_"+str(i))
        noc_file.write("); \n\n")
    noc_file.write("\n")
