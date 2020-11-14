from socket_class import WindowsSocket

# Server Address
HOST = '127.0.0.1'
PORT = 33333

# Initialization Socket
win_sock = WindowsSocket()

# Connect to Server
win_sock.connect(HOST, PORT)

# Call to Phone
win_sock.sendall('1 1 01029807183'.encode())

# Receive Message from Server
data = win_sock.recv(32)
print('Received', repr(data.decode()))

# Close Socket
win_sock.myclose()
