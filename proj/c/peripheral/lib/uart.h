#ifndef __UART_H__
#define __UART_H__

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/signal.h>
#include <sys/ioctl.h>
#include <sys/poll.h>

#include <termios.h>
#include <errno.h>

int set_interface_attribs(int fd, int speed);
void set_mincount(int fd, int mcount);
int open_serial(char *dev_name, int baud, int vtime, int vmin);
void close_serial(int fd);
void gsm_msg_send(int fd, char *phone_num, char *msg);
void gsm_phone_call(int fd, char *phone_num);

#endif
