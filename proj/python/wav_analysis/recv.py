import socket

(host, port) = ('localhost', 37373)

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind((host, port))
s.listen(1)

conn, addr = s.accept()

with open('output', 'wb') as f:
	while True:
		l = conn.recv(1024)
		if not 1:
			break
		f.write(l)

s.close()
