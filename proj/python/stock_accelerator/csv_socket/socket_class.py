import socket

class WindowsSocket:
    def __init__(self, sock=None):
        if sock is None:
            self.sock = socket.socket(
                            socket.AF_INET, socket.SOCK_STREAM)
        else:
            self.sock = sock

    def setsockopt(self):
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    def bind(self, host, port):
        self.sock.bind((host, port))

    def listen(self):
        self.sock.listen()

    def accept(self):
        self.clnt_sock, self.addr = self.sock.accept()
        print("Connected by:", self.addr)
        return self.clnt_sock, self.addr

    def connect(self, host, port):
        self.sock.connect((host, port))

    def sendall(self, msg):
        self.sock.sendall(msg)

    def recv(self, num):
        self.data = self.sock.recv(num)
        return self.data

    def mysend(self, msg):
        totalsent = 0
        while totalsent < MSGLEN:
            sent = self.sock.send(msg[totalsent:])
            if sent == 0:
                raise RuntimeError("socket connection broken")
            totalsent = totalsent + sent

    def myreceive(self):
        chunks = []
        bytes_recd = 0
        while bytes_recd < MSGLEN:
            chunk = self.sock.recv(min(MSGLEN - bytes_recd, 2048))
            if chunk == b'':
                raise RuntimeError("socket connection broken")
            chunks.append(chunk)
            bytes_recd = bytes_recd + len(chunk)
        return b''.join(chunks)

    def myclose(self):
        if hasattr(self, "clnt_sock"):
            self.clnt_sock.close()
        self.sock.close()
