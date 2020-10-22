PWD = $(shell pwd)

INC_DIRS += -I$(PWD)/../lib

LIBS = -lm -lpthread

SRCS = $(wildcard *.c)
OBJS = $(SRCS:%.c=%.o)

LIB_DIR = $(PWD)/../lib
LIB_OBJS = $(shell find $(LIB_DIR) -name '*.o')

#TARGET = custom_vector_test heap_sort_test quick_sort_test insert_sort_test
TARGET = uart_recv_test uart_send_test gsm_msg_test gsm_phone_call_test gsm_daemon_test gsm_protocol_send_test gsm_call gsm_send mq_recv_test gsm_socket_daemon

all: $(OBJS)
all: $(TARGET)

$(TARGET): $(OBJS)
uart_recv_test: uart_recv_test.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

uart_send_test: uart_send_test.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

gsm_msg_test: gsm_msg_test.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

gsm_phone_call_test: gsm_phone_call_test.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

gsm_daemon_test: gsm_daemon_test.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

gsm_protocol_send_test: gsm_protocol_send_test.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

gsm_call: gsm_call.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

gsm_send: gsm_send.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

mq_recv_test: mq_recv_test.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

gsm_socket_daemon: gsm_socket_daemon.o
	$(CC) -o $@ $< $(LIB_OBJS) $(LIBS) -g

.c.o:
	@echo "**********************************"
	@echo "********** Main Program **********"
	@echo "**********************************"
	$(CC) -c $< -o $@ $(INC_DIRS) -g -lpthread -lm

clean:
	rm -rf *.o
	rm -rf $(TARGET)
