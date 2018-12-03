import sys

if '-D'  in sys.argv[1:]:
	network_dime_x = int(sys.argv[sys.argv.index('-D')+1])
	network_dime_y = int(sys.argv[sys.argv.index('-D')+2])
else:
	# Default nework size is 4x4!
	network_dime_x = 4
	network_dime_4 = 4

if '-o'  in sys.argv[1:]:
  file_path = sys.argv[sys.argv.index('-o')+1]
  if ".do" not in file_path:
      raise ValueError("wrong file extention. only do files are accepted!")
else:
  file_path = 'wave_'+str(network_dime_x)+"x"+str(network_dime_y)+'.do'

wave_file = open(file_path, 'w')

tb_name= "tb_network_"+str(network_dime_x)+"x"+str(network_dime_y)

wave_file.write("onerror {resume}\n")
wave_file.write("quietly WaveActivateNextPane {} 0\n")
for i in range(0 , network_dime_x*network_dime_y):
	wave_file.write("add wave -noupdate -group {NoC RX} -color green -radix decimal :"+tb_name+":RX_L_"+str(i)+"\n")
 
for i in range(0 , network_dime_x*network_dime_y):
	wave_file.write("add wave -noupdate -group {NoC TX} -color green -radix decimal :"+tb_name+":TX_L_"+str(i)+"\n")
 

for i in range(0 , network_dime_x*network_dime_y):
	if i / network_dime_x != 0: # Y coordinate
		wave_file.write("add wave -noupdate -group {Link NoC RX} -color green -radix decimal :"+tb_name+":NoC:R_"+str(i)+":RX_N\n")
	if i % network_dime_x != network_dime_x-1: # X coordinate
		wave_file.write("add wave -noupdate -group {Link NoC RX} -color green -radix decimal :"+tb_name+":NoC:R_"+str(i)+":RX_E\n")
	if i % network_dime_x != 0: # X coordinate
		wave_file.write("add wave -noupdate -group {Link NoC RX} -color green -radix decimal :"+tb_name+":NoC:R_"+str(i)+":RX_W\n")
	if i / network_dime_x != network_dime_y-1: # Y coordinate
		wave_file.write("add wave -noupdate -group {Link NoC RX} -color green -radix decimal :"+tb_name+":NoC:R_"+str(i)+":RX_S\n")


for i in range(0 , network_dime_x*network_dime_y):
	if i / network_dime_x != 0: # Y coordinate
		wave_file.write("add wave -noupdate -group {Link NoC TX} -color green -radix decimal :"+tb_name+":NoC:R_"+str(i)+":TX_N\n")
	if i % network_dime_x != network_dime_x-1: # X coordinate
		wave_file.write("add wave -noupdate -group {Link NoC TX} -color green -radix decimal :"+tb_name+":NoC:R_"+str(i)+":TX_E\n")
	if i % network_dime_x != 0: # X coordinate
		wave_file.write("add wave -noupdate -group {Link NoC TX} -color green -radix decimal :"+tb_name+":NoC:R_"+str(i)+":TX_W\n")
	if i / network_dime_x != network_dime_y-1: # Y coordinate
		wave_file.write("add wave -noupdate -group {Link NoC TX} -color green -radix decimal :"+tb_name+":NoC:R_"+str(i)+":TX_S\n")

for i in range(0 , network_dime_x*network_dime_y):
	wave_file.write("add wave -noupdate -group {NoC Detailed} -color Gold -radix decimal :"+tb_name+":RX_L_"+str(i)+"\n")
	wave_file.write("add wave -noupdate -group {NoC Detailed} -color Gold :"+tb_name+":valid_in_L_"+str(i)+"\n")
	wave_file.write("add wave -noupdate -group {NoC Detailed} -color Gold :"+tb_name+":credit_out_L_"+str(i)+"\n")
	wave_file.write("add wave -noupdate -group {NoC Detailed} -color Violet -radix decimal :"+tb_name+":TX_L_"+str(i)+"\n")
	wave_file.write("add wave -noupdate -group {NoC Detailed} -color Violet :"+tb_name+":valid_out_L_"+str(i)+"\n")
	wave_file.write("add wave -noupdate -group {NoC Detailed} -color Violet :"+tb_name+":credit_in_L_"+str(i)+"\n")
 	wave_file.write("add wave -noupdate -group {NoC Detailed} :"+tb_name+":clk\n")

for i in range(0 , network_dime_x*network_dime_y):
 	wave_file.write("add wave -noupdate -group {NoC Empty_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_N:empty\n")
 	wave_file.write("add wave -noupdate -group {NoC Empty_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_E:empty\n")
 	wave_file.write("add wave -noupdate -group {NoC Empty_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_W:empty\n")
 	wave_file.write("add wave -noupdate -group {NoC Empty_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_S:empty\n")
 	wave_file.write("add wave -noupdate -group {NoC Empty_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_L:empty\n")
wave_file.write("add wave -noupdate -group {NoC Empty_Sigs} :"+tb_name+":clk\n")

for i in range(0 , network_dime_x*network_dime_y):
 	wave_file.write("add wave -noupdate -group {NoC Full_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_N:full\n")
 	wave_file.write("add wave -noupdate -group {NoC Full_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_E:full\n")
 	wave_file.write("add wave -noupdate -group {NoC Full_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_W:full\n")
 	wave_file.write("add wave -noupdate -group {NoC Full_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_S:full\n")
 	wave_file.write("add wave -noupdate -group {NoC Full_Sigs} :"+tb_name+":NoC:R_"+str(i)+":FIFO_L:full\n")
wave_file.write("add wave -noupdate -group {NoC Full_Sigs} :"+tb_name+":clk\n")


wave_file.write("TreeUpdate [SetDefaultTree]\n")
wave_file.write("WaveRestoreCursors\n")
wave_file.write("quietly wave cursor active 0\n")
wave_file.write("configure wave -namecolwidth 396\n")
wave_file.write("configure wave -valuecolwidth 100\n")
wave_file.write("configure wave -justifyvalue left\n")
wave_file.write("configure wave -signalnamewidth 0\n")
wave_file.write("configure wave -snapdistance 10\n")
wave_file.write("configure wave -datasetprefix 0\n")
wave_file.write("configure wave -rowmargin 4\n")
wave_file.write("configure wave -childrowmargin 2\n")
wave_file.write("configure wave -gridoffset 0\n")
wave_file.write("configure wave -gridperiod 1\n")
wave_file.write("configure wave -griddelta 40\n")
wave_file.write("configure wave -timeline 0\n")
wave_file.write("configure wave -timelineunits ns\n")
wave_file.write("update\n")
wave_file.write("WaveRestoreZoom {0 ps} {147 ns}\n")
wave_file.close()