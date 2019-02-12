################################################################################
#
# File name: track_packet.py
#
# Copyright (C) 2018
# Cesar G. Chaves A. (cesar.chaves@stud.fra-uas.de)
#
# Creation date: 10 Jul 2018
# Description: This scripts tracks a packet from source to destination.
#
################################################################################


import os
import sys

packet_id = 10
source=9
destination=3
network_size = 4
traces_dir = "../../tmp/simul_temp/traces"

################################################################################

src_x = source%network_size
src_y = source/network_size

dest_x = destination%network_size
dest_y = destination/network_size

def router_id2coord (router_id, network_size):
    print 'To be defined!'

def router_coord2id (x, y, network_size):
    return (y * network_size + x)

def find_packet_in_log (packet_id, src, dest, router_id, router_port):
    os.system('awk \'\
        {\
            if ($1=="H" && $4==' + str(src) + ' && $5==' + str(dest) + ') {\
                packet_detected=1;\
                H=$0;\
            }\
            else if (packet_detected==1) {\
                if ($1=="B1")\
                    B1=$0;\
                else if ($1=="B2") {\
                    if($5==' + str(packet_id) + ') {\
                        print H;\
                        print B1;\
                        print $0;\
                    }\
                    else\
                        packet_detected=0;\
                }\
                else if ($1=="R") {\
                    print $0;\
                    packet_detected=0;\
                }\
                else\
                    print $0;\
            }\
        }\' ' + traces_dir + '/track' + str(router_id) + '_' + router_port +  '.txt')
    return 0


if source != destination:
    x = src_x
    y = src_y

    print ""
    print '\033[96mRegistered for Packet ' + str(packet_id) + ' in the L input port of Router ' + str(source) + ' (' + str(x) + ',' + str(y) + ') :\033[0m'
    find_packet_in_log (packet_id, source, destination, source, 'L')

    while (x != dest_x) or (y != dest_y):
        if (x != dest_x):
            if src_x < dest_x:
                x = x+1
                router_port = 'W'
            else:
                x = x-1
                router_port = 'E'
        else:
            if src_y < dest_y:
                y = y+1
                router_port = 'N'
            else:
                y = y-1
                router_port = 'S'
        router = router_coord2id (x, y, network_size)
        print ""
        print '\033[96mRegistered for Packet ' + str(packet_id) + ' in the ' + router_port + ' input port of Router ' + str(router) + ' (' + str(x) + ',' + str(y) + ') :\033[0m'
        find_packet_in_log (packet_id, source, destination, router, router_port)

    print ""
    print '\033[96mRegistered for Packet ' + str(packet_id) + ' in the L output port of Router ' + str(router) + ' (' + str(x) + ',' + str(y) + ') :\033[0m'
    find_packet_in_log (packet_id, source, destination, router, router_port)
