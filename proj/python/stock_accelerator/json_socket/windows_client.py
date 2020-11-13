from socket_class import WindowsSocket
import json

# Server Address
HOST = '127.0.0.1'
PORT = 33333

# Initialization Socket
win_sock = WindowsSocket()

# Connect to Server
win_sock.connect(HOST, PORT)

# Send Message to Server
#win_sock.sendall('안녕'.encode())
with open('json_test.json') as json_file:
	json_data = json.load(json_file)
	print(json_data)

# Receive Message from Server
data = win_sock.recv(1024)
print('Received', repr(data.decode()))

# Close Socket
win_sock.myclose()
