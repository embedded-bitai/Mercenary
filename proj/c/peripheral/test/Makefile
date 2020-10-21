PWD = $(shell pwd)

INC_DIRS += -I$(PWD)/../lib

LIBS = -lm

SRCS = $(wildcard *.c)
OBJS = $(SRCS:%.c=%.o)

LIB_DIR = $(PWD)/../lib
LIB_OBJS = $(shell find $(LIB_DIR) -name '*.o')

#TARGET = custom_vector_test heap_sort_test quick_sort_test insert_sort_test
TARGET = uart_recv_test uart_send_test gsm_msg_test gsm_phone_call_test

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

.c.o:
	@echo "**********************************"
	@echo "********** Main Program **********"
	@echo "**********************************"
	$(CC) -c $< -o $@ $(INC_DIRS) -g

clean:
	rm -rf *.o
	rm -rf $(TARGET)
