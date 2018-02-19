# Copyright (C) 2016 Siavoosh Payandeh Azad
from math import ceil, log



class CreditBasedPackage():
    """
    This class handles all the program arguments.
    sort_out_parameters: function for setting up the argument list and also printing the manual if needed!
    parameters_sanity_check: TODO
    generate_file_name: handles generating the file name for output file
    """

    def __init__(self):
        # self.network_dime = None
        self.data_width = 32
        self.fifo_depth = 4
        self.network_dime_x = 4
        self.network_dime_y = 4
        self.add_tracker = False
        self.vc = False
        self.routing = 'xy'

    def sort_out_parameters(self, arguments_list):

        if '--help' in arguments_list:
            print "\t-D [network size]: it makes a network of [size]X[size]. Size can be only multiples of two. " \
                  "default value is 4."
            print "\t-DW [data_width]: sets the data width of the network."
            print "\t-FIFOD [fifo_depth]: sets the depth of the FIFO in terms of the number flit slots."
            print "\t-routing [routing_algorithm]: sets the routing algorithm (default value is xy). It can be set to xy, yx, wf, nl, nf and sr."
            print "\t-o: specifies the name and path of the output file. default path is current folder."
            print "\t**Example: python network_gen_parameterized.py -D 2 -o ../output.vhd"
            print "\t           generates a 2X2 network that has network interface and parity checker and fault " \
                  "injectors into ../output.vhd"
            return 1
            
        if '-D' in arguments_list:
            self.network_dime_x = int(arguments_list[arguments_list.index('-D')+1])
            self.network_dime_y = int(arguments_list[arguments_list.index('-D')+2])

        if '-DW' in arguments_list:
            self.data_width = int(arguments_list[arguments_list.index('-DW')+1])
            if self.data_width % 2 != 0:
                raise ValueError("wrong data width. please choose powers of 2. for example 32!")

        if '-FIFOD' in arguments_list:
            self.fifo_depth = int(arguments_list[arguments_list.index('-FIFOD')+1])
            if self.fifo_depth <= 1:
                raise ValueError("wrong FIFO depth. please choose valid value (at least 2 FIFO slots)!")

        if '-routing' in arguments_list:
            self.routing = str(arguments_list[arguments_list.index('-routing')+1])
            if self.routing != 'xy' and self.routing != 'yx' and self.routing != 'wf' and self.routing != 'nl' and self.routing != 'nf' and self.routing != 'sr':
                raise ValueError("Invalid routing algorithm, or not supported by Bonfire yet.")

        if "-VC" in arguments_list:
            self.vc = True

        if "-trace" in arguments_list:
            self.add_tracker = True
        return 0

    def parameters_sanity_check(self):

        pass

    def generate_file_name(self, arguments_list):
        file_name= 'network'

        if '-o'  in arguments_list:
            file_path = arguments_list[arguments_list.index('-o')+1]
            if ".vhd" not in file_path:
                raise ValueError("wrong file extension. only vhdl files are accepted!")
        else:
            file_path = file_name+'_'+str(self.network_dime_x)+"x"+str(self.network_dime_y)+'.vhd'
        return file_path
