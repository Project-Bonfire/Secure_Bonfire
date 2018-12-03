filenames = ["network_latency_nt_a.txt", "network_latency_nt_na.txt", "network_latency_t_a.txt",
			 "network_latency_t_na.txt", "secure_latency_nt_a.txt", "secure_latency_nt_na.txt", 
			 "secure_latency_t_a.txt", "secure_latency_t_na.txt"
			]
result_file_network = open("results_network.csv", "w")
result_file_network.write("info traffic attack Path_Length PIR latency throughput\n")
result_file_network.close()
result_file_network = open("results_network.csv", "a")

result_file_secure = open("results_secure.csv", "w")
result_file_secure.write("info traffic attack Path_Length PIR latency throughput WCL\n")
result_file_secure.close()
result_file_secure = open("results_secure.csv", "a")
for filename in filenames:
	# print "-------------------------"*2
	file = open(filename, "r")

	Attack_Path_Length = None
	PIR = None
	latency = None
	throughput = None

	attack = True
	traffic = True
	info = None 
	WCL = None
	if "secure" in filename:
		info = "S"
	if "network" in filename:
		info = "N"

	if "na" in filename:
		attack = False
	if "nt" in filename:
		traffic = False
	for line in file:
		if "#"*92 in line:
			if throughput != None:
				if WCL != None:
					result_file_secure.write(str(info)+" "+str(traffic)+" "+str(attack)+
						              " "+str(Attack_Path_Length)+" "+str(PIR)+
						              " "+str(float(latency)/10)+" "+str(throughput)+" "+str(WCL)+"\n")
				else:
					result_file_network.write(str(info)+" "+str(traffic)+" "+str(attack)+
						              " "+str(Attack_Path_Length)+" "+str(PIR)+
						              " "+str(float(latency)/10)+" "+str(throughput)+"\n")

			Attack_Path_Length = None
			PIR = None
			latency = None
			throughput = None
			WCL = None
		if "ATTACK_PATH_LENGTH:" in line:
			Attack_Path_Length= int(line.split(" ")[-2])
		if "PIR" in line:
			PIR= float(line.split(" ")[-1])
			
		if "average packet latency:" in line:
			latency= float(line.split(" ")[-2])

		if "throughput" in line:
			throughput= float(line.split(" ")[-2])

		if "Worst Case Latency on Router" in line:
			WCL = float(line.split(" ")[-3])
		else:
			WCL = None
result_file_secure.close()
result_file_network.close()
		
