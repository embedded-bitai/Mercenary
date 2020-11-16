from socket_class import Socket
from gsm import *

# Server Address
HOST = '127.0.0.1'
PORT = 33333

# Initialization Socket
gsm_sock = Socket()

# Connect to Server
gsm_sock.connect(HOST, PORT)

# Call to Phone
gsm_sock.sendall('1 1 01029807183'.encode())

# Fin Call
gsm_sock.sendall('1 0'.encode())

# Receive Message from Server
#data = win_sock.recv(32)
#print('Received', repr(data.decode()))

# Send SMS
gsm_sock.sendall('2 1 01029807183 Hello BitAI from Python GSM Module\r\n\0'.encode())

# Fin SMS
gsm_sock.sendall('2 0\r\n\0'.encode())

# Receive Message from Server
#data = win_sock.recv(32)
#print('Received', repr(data.decode()))

# Fin Daemon
gsm_sock.sendall('3\r\n\0'.encode())

# Close Socket
gsm_sock.myclose()
