from gsm import *
from time import sleep

# Server Address
HOST = '127.0.0.1'
PORT = 33333

# Initialization Socket
gsm_sock = GSMSocket()

# Connect to Server
gsm_sock.connect(HOST, PORT)

# Phone Call Start
#gsm_sock.phone_call('01029807183')

#data = gsm_sock.recv(1024)
#print('Received', repr(data.decode()))

# Call Finish
#gsm_sock.finish_call()

#data = gsm_sock.recv(1024)
#print('Received', repr(data.decode()))

gsm_sock.send_msg('01029807183', "Hello BitAI from Python GSM Module")

data = gsm_sock.recv(1024)
print('Received', repr(data.decode()))

gsm_sock.finish_msg()

data = gsm_sock.recv(1024)
print('Received', repr(data.decode()))

# Finish Everything
gsm_sock.kill_daemon()

data = gsm_sock.recv(1024)
print('Received', repr(data.decode()))

gsm_sock.myclose()
