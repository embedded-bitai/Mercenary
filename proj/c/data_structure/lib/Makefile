PWD = $(shell pwd)

#INC_DIRS += -I$(PWD)/../constants

SRCS = $(wildcard *.c)
OBJS = $(SRCS:%.c=%.o)

all: $(OBJS)

.c.o:
	@echo "*************************************"
	@echo "********** Math Lib Module **********"
	@echo "*************************************"
#	$(CC) -c $< -o $@ $(INC_DIRS)
	$(CC) -c $< $(INC_DIRS)

clean:
	rm -rf *.o
