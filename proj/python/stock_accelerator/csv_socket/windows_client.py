from socket_class import WindowsSocket

import pickle
import json
import csv

HEADERSIZE = 10

# Server Address
HOST = '127.0.0.1'
PORT = 33333

# Initialization Socket
win_sock = WindowsSocket()

# Connect to Server
win_sock.connect(HOST, PORT)

# Send Message to Server
#win_sock.sendall('안녕'.encode())
#with open('./convert.json', "r") as json_file:
#	json_data = json.load(json_file)
#	print(json_data)

input_file_name = "./삼성전자.csv"

with open(input_file_name, "r", encoding="utf-8", newline="") as input_file:
	reader = csv.reader(input_file)

	col_names = next(reader)

	for cols in reader:
		doc = {col_name: col for col_name, col in zip(col_names, cols)}
		msg = pickle.dumps(doc)
		#msg = bytes(f"{len(msg):<{HEADERSIZE}}", 'utf-8') + msg
		#win_sock.sendall(doc.encode())
		win_sock.sendall(msg)

		# Receive Message from Server
		data = win_sock.recv(1024)
		print('Received', repr(data.decode()))

# Close Socket
win_sock.myclose()
