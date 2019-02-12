#!/bin/bash
################################################################################
#
# File name: process_results.sh 
#
# Copyright (C) 2018
# Cesar G. Chaves A. (cesar.chaves@stud.fra-uas.de)
#
# Creation date: 20 Jul 2018
# Description: This scripts Processes the result files.
#
################################################################################

results_dir=../../results

for result_file in $(ls -1 ${results_dir}/*3_T.txt | grep -v "AD_7" | sort -t_ -nk6,6); do
    IFS='_' read -r -a file_name <<< "$result_file"
    # Important file name segments:
    # [1] Did the experiment consider traffic? (True/False)
    # [3] Did the experiment consider an attack? (True/False)
    # [5] Attacker's Packet Length
    # [7] Attack Source
    # [9] Attack Destination
    traffic=${file_name[1]} 
    attack=${file_name[3]}

    if [ "$attack" = "False" ]; then
        attacker_source="None"
        attacker_path_length="None"
        attacker_packet_length="None"
    else
        attacker_source=${file_name[7]}
        attacker_path_length=${file_name[7]}
        attacker_packet_length=${file_name[5]}
    fi

    awk \
    -v v_traffic=$traffic \
    -v v_attack=$attack  \
    -v v_attacker_source=$attacker_source \
    -v v_attacker_path_length=$attacker_path_length \
    -v v_attacker_packet_length=$attacker_packet_length \
    'BEGIN{first_line=1}{

        if ($1 == "S") {
            if ($5 == last_pir) {

                if ($9 == last_seed) {

                    if (max_total_delay < $17) {
                        max_total_delay = $17
                        max_local_delay = $19
                        max_delay_router = $18
                    }
                }
                else
                {
                    last_seed = $9
                    sum_total_delays = sum_total_delays + max_total_delay
                    sum_local_delays = sum_local_delays + max_local_delay
                    if (max_local_delay != 0)
                        register_count++

                    max_total_delay = $17
                    max_local_delay = $19
                    max_delay_router = $18
                }


                #if (v_attack == "True" && $18 == v_attacker_source)
                #    positive_detections++
            }
            else {

                if (first_line != 1) {
                     print "S", v_traffic, v_attack, v_attacker_path_length, $2, 
                         sum_total_delays/50, "0", last_pir, v_attacker_packet_length, 
                         sum_local_delays/50, max_delay_router #, "-", positive_detections, "-", register_count, "--", positive_detections/register_count
                }
                register_count = 0
                last_pir = $5
                last_seed = $9

                sum_total_delays = 0
                sum_local_delays = 0

                max_total_delay = $17
                max_local_delay = $19
                max_delay_router = $18
            }
        }
        first_line = 0
    }
    END { 
        if (first_line != 1) {
            print "S", v_traffic, v_attack, v_attacker_path_length, last_pir, 
                sum_total_delays/50, "0", last_pir, v_attacker_packet_length, 
                sum_local_delays/50, max_delay_router #, "-", positive_detections, "-", register_count, "--", positive_detections/register_count
            print "" 
        }
    }' $result_file
done
