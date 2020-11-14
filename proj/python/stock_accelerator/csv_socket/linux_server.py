from socket_class import WindowsSocket

import pandas as pd
import pickle

# Server Address
HOST = '127.0.0.1'
PORT = 33333

# Initialization Socket
linux_sock = WindowsSocket()

# Solve Address Resolving Error(for Already Bind)
linux_sock.setsockopt()

# Socket Bind
linux_sock.bind(HOST, PORT)

# Server Listening
linux_sock.listen()

# Accept Client
clnt_sock, addr = linux_sock.accept()

success_msg = "Success"
dict_data = pd.DataFrame()

# Process Something
while True:
    data = clnt_sock.recv(1024)

    if not data:
        break

    #print("Received From", addr, data.decode())
    #print("Received From", addr, data)
    print("Received From", addr, pickle.loads(data))
    #dict_data.update([pickle.loads(data)])
    #dict_data.append(pickle.loads(data))
    dict_data = dict_data.append(pickle.loads(data), ignore_index=True)

    clnt_sock.sendall(success_msg.encode())

# After Processing
print("*********************************")
print(dict_data)

# Close Socket
linux_sock.myclose()
