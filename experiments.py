import generate_tb_package
import os
import sys
import subprocess

# Execution command: 
# /usr/bin/time -f "Elapsed Time = %E, Inputs %I, Outputs %O" python experiments.py

################################################################################
# Configuration of the experiments #############################################
################################################################################
results_dir = "results"

# Network map for network_size = 4
#  0 -  1 -  2 -  3
#  4 -  5 -  6 -  7
#  8 -  9 - 10 - 11
# 12 - 13 - 14 - 15

# Configuration of the Network
network_size = 4
network_packet_length = 10
traffic_list = [False, True]
pir_list = [0.01] # [0.003, 0.01, 0.03]
max_seed = 1 # Amount of executions with different traffic generation seeds 


# Configuration of the Sensitive transmission
sensitive_data_source = 12
sensitive_data_destination = 3
sensitive_pir_list = [0.01] # [0.003, 0.01, 0.03]


# Configuration of the DoS attack
attack_list = [False, True]
attacker_source_list = [13] # [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
attacker_destination_list = [3] # [14, 15, 11, 7, 3]
attacker_packet_length_list = [30] # [10, 30, 50]
attacker_pir_list = [0.03] # [0.003, 0.01, 0.03]


# List the input ports that will be monitored 
# Format   : ROUTER_PORT, 
# Example  : monitor_port_list = ['12_L', '15_L', '11_S',  '3_T']
monitor_port_list = []


# Configuration Notes: 
# 1. The sensitive_data_source and the sensitive_data_destination will be 
#    removed from the attacker_source_list 
# 2. Source of the attack and of the secure traffic, as well as the secure 
#    destination are monitored by default!

################################################################################
# Declaration of functions #####################################################
################################################################################
def report_detection_in_file(file_name, string, location, attacker_source):
    target_file = open(file_name, "r")
    counter = 0
    detection = 0
    for line in target_file:
        if string in line:
            if int(line.split(" ")[location]) == attacker_source:
                detection +=1
            counter += 1
    target_file.close()
    if counter == 0:
        raise ValueError("division by zero in average calculation!")
    return detection/float(counter)

def find_average_in_file(file_name, string, location):
    target_file = open(file_name, "r")
    counter = 0
    value = 0
    for line in target_file:
        if string in line:
            value += float(line.split(" ")[location])
            counter += 1
    target_file.close()
    if counter == 0:
        raise ValueError("division by zero in average calculation!")
    return value/counter

def find_distance(source, destination, network_size):
    dest_x = destination%network_size
    dest_y = destination/network_size
    source_x = source%network_size
    source_y = source/network_size
    return abs(dest_x - source_x) + abs(dest_y - source_y)

def calc_effective_pir_traffic_generator(source, destination):
    initial_time = 0
    end_time = 0
    total_packets = 0
    with open('tmp/simul_temp/sent.txt') as sent_file:
        file_line = sent_file.readline()
        while file_line:
            line_elements = file_line.split(" ")
            if (int(line_elements[6]) == source and int(line_elements[8]) == destination): 
                total_packets += 1
                if (initial_time == 0):
                    initial_time = int(line_elements[3])
                end_time = int(line_elements[3])
            file_line = sent_file.readline()
    effective_PIR = float(total_packets * 10000) / float(end_time - initial_time)
    return round(effective_PIR, 4)

def calc_effective_pir_NI(source, destination):
    initial_time = 0
    end_time = 0
    total_packets = 0
    with open('tmp/simul_temp/traces/track' + str(source) + '_L.txt') as sent_file:
        file_line = sent_file.readline()
        while file_line:
            line_elements = file_line.split(" ")
            if (line_elements[0] == 'H' and int(line_elements[3]) == source and int(line_elements[4]) == destination):
                total_packets += 1
                if (initial_time == 0):
                    initial_time = int(line_elements[1])
                end_time = int(line_elements[1])
            file_line = sent_file.readline()
    effective_PIR = float(total_packets * 10000) / float(end_time - initial_time)
    return round(effective_PIR, 4)

#def monitor_port(port, results_log_file, seed,
#                 sensitive_pir, sensitive_data_source, sensitive_data_destination, pir, epir_tg, epir_ni, 
#                 attack, attacker_source, attacker_destination, attacker_pir, eapir_tg, eapir_ni):
#
#    log_file = 'tmp/simul_temp/traces/track' + port + '.txt'
#
#    awk_code = 'awk \'{' +\
#        'if ($1=="BL") {' +\
#        '    initial_timestamp = $4' +\
#        '}' +\
#        'if (($4=="' + str(sensitive_data_source) + '" && $5=="' + str(sensitive_data_destination) + '") ' #+\
#
#    if attack == True:
#        awk_code = awk_code + ' || ($4=="' + str(attacker_source) + '" && $5=="' + str(attacker_destination) + '")' #+\
#
#    awk_code = awk_code +\
#        '){' +\
#        '    if ($1=="H") {' +\
#        '        header_arriving_time = $2' +\
#        '    }' +\
#        '    else if ($1=="R") {' #+\
#
#    if attack == True:
#        awk_code = awk_code +\
#            'if ($4==' + str(attacker_source) + ')' +\
#            '    {printf "A "}' +\
#            'else '
#
#    awk_code = awk_code +\
#        '        {printf "S "}' +\
#        '        print ' + str(sensitive_pir) + ', ' + str(epir_tg) + ', ' + str(epir_ni) +\
#                     ', ' + str(attacker_pir) + ', ' + str(eapir_tg) + ', ' + str(eapir_ni) + ', "-"' +\
#                     ', ' + str(seed) + ', $10, $11, "-"' +\
#                     ', header_arriving_time, $2, $2-header_arriving_time, "-"' +\
#                     ', $12, $13, $14, "-"' +\
#                     ', ' + str(pir) + ', $15, $16' +\
#        '    }' +\
#        '}' +\
#    '}\'' 
#
#    os.system(awk_code + ' ' + log_file + ' >> ' + results_log_file + '_' + port + '.txt')
#   
#    #os.system('echo ' + awk_code + ' > tmp_' + port + '.txt')

def monitor_port(port_log_summary_file, port, results_log_file, seed,
                 sensitive_pir, sensitive_data_source, sensitive_data_destination, pir, epir_tg, epir_ni,
                 attack, attacker_source, attacker_destination, attacker_pir, eapir_tg, eapir_ni):

    input_file_name = 'tmp/simul_temp/traces/track' + port + '.txt'
 
    with open(input_file_name) as input_file:
        file_line = input_file.readline().strip()
        while file_line:
            line_elements = file_line.split(" ")
            
            if line_elements[0] == "BL": initial_timestamp = line_elements[3] 

            if (line_elements[0] == "H" or line_elements[0] == "R") :
                
                if line_elements[0]  == "H" :
                    header_arriving_time = line_elements[1] 
                else :
                    total_delay = int(line_elements[1]) - int(header_arriving_time)

                    if (attack == True and line_elements[3] == str(attacker_source) and line_elements[4] == str(attacker_destination)) :
                        port_log_summary_file.write ("A " + str(sensitive_pir) + " " + str(epir_tg) + " " + str(epir_ni) + \
                        " " + str(attacker_pir) + " " + str(eapir_tg) + " " + str(eapir_ni) + " -" + \
                        " " + str(seed) + " " + line_elements[9] + " " + line_elements[10] +  " -" + \
                        " " + header_arriving_time + " " + line_elements[1] + " " + str(total_delay) + " -" + \
                        " " + line_elements[11] + " " + line_elements[12] + " " + line_elements[13] + " -" + \
                        " " + str(pir) + " " + line_elements[14] + " " + line_elements[15] + "\n")
                    elif (line_elements[3] == str(sensitive_data_source) and line_elements[4] == str(sensitive_data_destination)) : 
                        port_log_summary_file.write ("S " + str(sensitive_pir) + " " + str(epir_tg) + " " + str(epir_ni) + \
                        " " + str(attacker_pir) + " " + str(eapir_tg) + " " + str(eapir_ni) + " -" + \
                        " " + str(seed) + " " + line_elements[9] + " " + line_elements[10] +  " -" + \
                        " " + header_arriving_time + " " + line_elements[1] + " " + str(total_delay) + " -" + \
                        " " + line_elements[11] + " " + line_elements[12] + " " + line_elements[13] + " -" + \
                        " " + str(pir) + " " + line_elements[14] + " " + line_elements[15] + "\n")

            file_line = input_file.readline().strip()





def run_experiment(traffic, attack, pir, sensitive_pir, sensitive_data_source, sensitive_data_destination,
                  attacker_source, attacker_destination, attacker_pir, attacker_packet_length,
                  max_seed, network_size, results_log_file):
    
    # Calculates the network coordinates of the sensitive source
    sensitive_source_x = sensitive_data_source%network_size
    sensitive_source_y = sensitive_data_source/network_size

    # Calculates the path length of the malicious traffic
    if attack:
        distance = find_distance(attacker_source, attacker_destination, network_size)
    else:
        distance = 0

    # Generates a list of traffic seeds only if Traffic is True
    if traffic == True:
        seed_list = range(1, max_seed+1)
    else:
        seed_list = [1]

    for seed in seed_list:
        # Print the Scenario's configuration
        print "-----------------------------------"
        print "Scenario:", "\033[92mTraffic\033[0m," if traffic else "\033[94mNo traffic,", "\033[91mAttack\033[0m" if attack else "\033[94mNo attack\033[0m"
        print "    Netowrk: PIR:", pir if traffic else "0.000", "|", "PL:", '%3s' %str(network_packet_length) if traffic else "00", "|"
        print "  Sensitive: PIR:",  sensitive_pir, "|", "PL:", '%3s' %str(network_packet_length), "|", '%3s' %str(sensitive_data_source), "-->", '%3s' %str(sensitive_data_destination)
        print "   Attacker: PIR:", attacker_pir, "|", "PL:", '%3s' %str(attacker_packet_length), "|", '%3s' %str(attacker_source), "-->", '%3s' %str(attacker_destination), "|", "seed:", "\033[93m"+str(seed)+"\033[0m"
        print "  -----------"

        # generate proper testbench package file
        tb_file = "TB_Package_32_bit_credit_based_NI.vhd"
        generate_tb_package.gen_tb_package(tb_file, traffic, sensitive_pir, sensitive_data_source, sensitive_data_destination,attack, pir, attacker_source, attacker_destination, attacker_packet_length, attacker_pir, seed)
        os.system("mv -f TB_Package_32_bit_credit_based_NI.vhd Packages/")

        # run simulation
        print "  running simulation..."
        os.system('python simulate.py -D '+str(network_size)+' '+ str(network_size)+' -DW 32 -FIFOD 4 -sim 100000 -end 130000 -NI 1024 -Rand '+str(pir)+' -PS '+str(network_packet_length)+' '+ str(network_packet_length)+' -lat --trace -routing xy >>/dev/null')
        #os.system('python simulate.py -D '+str(network_size)+' '+ str(network_size)+' -DW 32 -FIFOD 4 -sim 100000 -end 130000 -NI 1024 -Rand '+str(pir)+' -PS '+str(network_packet_length)+' '+ str(network_packet_length)+' -lat --trace -routing xy')

        if attack == True:
            eapir_tg = calc_effective_pir_traffic_generator(attacker_source, attacker_destination)
            eapir_ni = calc_effective_pir_NI(attacker_source, attacker_destination)
        else:
            attacker_pir=0
            eapir_tg = 0
            eapir_ni = 0

        epir_tg = calc_effective_pir_traffic_generator(sensitive_data_source, sensitive_data_destination)
        epir_ni = calc_effective_pir_NI(sensitive_data_source, sensitive_data_destination)

        for port in monitor_port_list_extended:
            port_log_summary_file = open(results_log_file + "_" + port + ".txt", "a")
            monitor_port(port_log_summary_file, port, results_log_file, seed,
                sensitive_pir, sensitive_data_source, sensitive_data_destination, pir, epir_tg, epir_ni,
                attack, attacker_source, attacker_destination, attacker_pir, eapir_tg, eapir_ni)
            port_log_summary_file.close()

################################################################################
################################################################################

# Creates de results directory
os.system('mkdir -p ' + results_dir)

# Removes the sensitive_data_source and the sensitive_data_destination from the attackers list
if sensitive_data_source in attacker_source_list: 
    attacker_source_list.remove(sensitive_data_source)
if sensitive_data_destination in attacker_source_list: 
    attacker_source_list.remove(sensitive_data_destination)

# Adds the Sensitive data path origin and destination router ports to the monitor_port_list 
if str(sensitive_data_source) + '_L' not in monitor_port_list:
    monitor_port_list.append(str(sensitive_data_source) + '_L')
if str(sensitive_data_destination) + '_T' not in monitor_port_list:
    monitor_port_list.append(str(sensitive_data_destination) + '_T')
monitor_port_list_extended = monitor_port_list

for traffic in traffic_list:

    if traffic == False:
        pir_list_1 = [0]
    else :
        pir_list_1 = pir_list

    for attack in attack_list:

        if attack:
            for attacker_packet_length in attacker_packet_length_list:
                for attacker_source in attacker_source_list:

                    # Adds the attack source router port to the monitor_port_list_extended 
                    monitor_port_list_extended = monitor_port_list
                    if str(attacker_source) + '_L' not in monitor_port_list:
                        monitor_port_list_extended.append(str(attacker_source) + '_L')

                    for attacker_destination in attacker_destination_list:

                        # Define the name of sensitive packets arrival log
                        results_log_file = results_dir +\
                            '/T_' + str(traffic) + '_' +\
                            'A_' + str(attack) + '_' +\
                            'APL_' + str(attacker_packet_length) + '_' +\
                            'AS_'  + str(attacker_source) + '_' +\
                            'AD_' + str(attacker_destination) + '_' +\
                            'log_summary'

                        # Create clean log summary files
                        for port in monitor_port_list_extended:
                            os.system('echo -n > ' + results_log_file + '_' + port + '.txt')

                        for pir in pir_list_1:
                            for attacker_pir in attacker_pir_list:
                                for sensitive_pir in sensitive_pir_list:
                                    # Run experiments
                                    run_experiment(traffic,  attack, pir, sensitive_pir, sensitive_data_source, sensitive_data_destination,
                                        attacker_source, attacker_destination, attacker_pir, attacker_packet_length,
                                        max_seed, network_size, results_log_file)

        else:

            # Define the name of sensitive packets arrival log file
            results_log_file = results_dir + '/' + 'T_' + str(traffic) + '_A_False_log_summary'

            # Create clean log summary files
            for port in monitor_port_list_extended:
                os.system('echo -n > ' + results_log_file + '_' + port + '.txt')

            for pir in pir_list_1:
                for sensitive_pir in sensitive_pir_list:
                    # setup TB_package
                    run_experiment(traffic, attack, pir, sensitive_pir, sensitive_data_source, sensitive_data_destination,
                        "None", "None", "None", "None", 
                        max_seed, network_size, results_log_file)

print "-----------------------------------"
