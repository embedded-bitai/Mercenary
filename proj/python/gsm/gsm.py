from socket_class import Socket

class GSMSocket(Socket):
    def __init__(self):
        super(GSMSocket, self).__init__()

    def phone_call(self, phone_num):
        msg = "1 1 " + phone_num
        print(msg)
        self.sendall(msg.encode())

    def finish_call(self):
        msg = "1 0"
        print(msg)
        self.sendall(msg.encode())
        pass

    def send_msg(self, phone_num, sms_msg):
        msg = "2 1 " + phone_num + " " + sms_msg
        print(msg)
        self.sendall(msg.encode())

    def finish_msg(self):
        pass

    def kill_daemon(self):
        msg = "3"
        print(msg)
        self.sendall(msg.encode())
