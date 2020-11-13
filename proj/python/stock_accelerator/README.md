# How to do ?
윈도우에서 증권 API를 처리하는 32비트 64비트 연동 작업을 진행한다.
그리고 리눅스 가속기와 소켓 통신을 수행하도록 한다.
해당 작업은 리눅스 가속기가 해야하는 일의 일부이다.

# Role of Each Files
socket directory - It's for Test Python Socket.  
windows_client.py - It's for windows client.  
linux_server.py - It's for linux server.  
socket_class.py - It's for Python Socket Communication Class.  

```make
How to test Socket Programming.

first terminal: python linux_server.py
second terminal: python windows_client.py
```

json directory - It's for Test json Encoding/Decoding.  
json_encode.py - It's for Test json Encoding.  
json_decode.py - It's for Test json Decoding.  

```make
How to test json Encoding/Decoding.

python json_encode.py
python json_decode.py
```

json_socket directory - It's for Socket Programming with json data.  
