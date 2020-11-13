from socket_class import WindowsSocket

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

# Process Something
while True:
    data = clnt_sock.recv(1024)

    if not data:
        break

    print("Received From", addr, data.decode())

    clnt_sock.sendall(success_msg.encode())

# Close Socket
linux_sock.myclose()
