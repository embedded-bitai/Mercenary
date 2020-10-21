#include "uart.h"

int set_interface_attribs(int fd, int speed)
{
    struct termios tty;

    if (tcgetattr(fd, &tty) < 0) {
        printf("Error from tcgetattr: %s\n", strerror(errno));
        return -1;
    }

    cfsetospeed(&tty, (speed_t)speed);
    cfsetispeed(&tty, (speed_t)speed);

    tty.c_cflag |= (CLOCAL | CREAD);    /* ignore modem controls */
    tty.c_cflag &= ~CSIZE;
    tty.c_cflag |= CS8;         /* 8-bit characters */
    tty.c_cflag &= ~PARENB;     /* no parity bit */
    tty.c_cflag &= ~CSTOPB;     /* only need 1 stop bit */
    tty.c_cflag &= ~CRTSCTS;    /* no hardware flowcontrol */

    /* setup for non-canonical mode */
    tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
    tty.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
    tty.c_oflag &= ~OPOST;

    /* fetch bytes as they become available */
    tty.c_cc[VMIN] = 1;
    tty.c_cc[VTIME] = 1;

    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        printf("Error from tcsetattr: %s\n", strerror(errno));
        return -1;
    }
    return 0;
}

void set_mincount(int fd, int mcount)
{
    struct termios tty;

    if (tcgetattr(fd, &tty) < 0) {
        printf("Error tcgetattr: %s\n", strerror(errno));
        return;
    }

    tty.c_cc[VMIN] = mcount ? 1 : 0;
    tty.c_cc[VTIME] = 5;        /* half second timer */

    if (tcsetattr(fd, TCSANOW, &tty) < 0)
        printf("Error tcsetattr: %s\n", strerror(errno));
}

int open_serial(char *dev_name, int baud, int vtime, int vmin)
{
	int fd;
	struct termios newtio;

	fd = open(dev_name, O_RDWR | O_NOCTTY);

	if(fd < 0)
	{
		printf("Device Open Fail %s\n", dev_name);
		return -1;
	}

	memset(&newtio, 0, sizeof(newtio));
	newtio.c_iflag = IGNPAR;
	newtio.c_oflag = 0;

	newtio.c_cflag = CS8 | CLOCAL | CREAD;

	switch(baud)
	{
		case 115200:
			newtio.c_cflag |= B115200;
			break;
		case 57600:
			newtio.c_cflag |= B57600;
			break;
		case 38400:
			newtio.c_cflag |= B38400;
			break;
		case 19200:
			newtio.c_cflag |= B19200;
			break;
		case 9600:
			newtio.c_cflag |= B9600;
			break;
		case 4800:
			newtio.c_cflag |= B4800;
			break;
		case 2400:
			newtio.c_cflag |= B2400;
			break;
		default:
			newtio.c_cflag |= B115200;
			break;
	}

	newtio.c_lflag = 0;
	newtio.c_cc[VTIME] = vtime;
	newtio.c_cc[VMIN] = vmin;

	tcflush(fd, TCIFLUSH);
	tcsetattr(fd, TCSANOW, &newtio);

	return fd;
}

void close_serial(int fd)
{
	close(fd);
}

void gsm_msg_send(int fd, char *phone_num, char *msg)
{
	int pn_len = strlen(phone_num);

    char buf[128] = "";
	char msg_buf[128] = "";
	unsigned char hex_1A[128] = {0x1A, '\r', '\n'};
    int buf_len;
    int msg_len;

	sprintf(buf, "AT+CMGS=\"%s\"\r\n", phone_num);
	buf_len = strlen(buf);

	sprintf(msg_buf, "%s\r\n", msg);
	msg_len = strlen(msg_buf);

    write(fd, "AT\r\n", 4);
	sleep(1);
    write(fd, "AT&F\r\n", 6);
	sleep(1);
    write(fd, "AT+CMGF=1\r\n", 11);
	sleep(1);
    write(fd, "AT+CSCS=\"GSM\"\r\n", 15);
	sleep(1);
	write(fd, buf, buf_len);
	sleep(1);
	write(fd, msg_buf, msg_len);
	sleep(1);
	write(fd, hex_1A, 3);
	sleep(1);

	printf("AT\n");
	printf("AT&F\n");
	printf("AT+CMGF=1\n");
	printf("AT+CSCS=\"GSM\"\n");
	printf("AT+CMGS=\"%s\"\n", phone_num);
	printf("%s\n", msg);
	printf("1A\n");
}

void gsm_phone_call(int fd, char *phone_num)
{
	int pn_len = strlen(phone_num);

    char buf[128] = "";
    int buf_len;

	sprintf(buf, "ATD%s;\r\n", phone_num);
	buf_len = strlen(buf);

    write(fd, "AT\r\n", 4);
	sleep(1);

    write(fd, buf, buf_len);
	sleep(1);

	sprintf(buf, "ATD%s;\r\n", phone_num);
	buf_len = strlen(buf);
    write(fd, buf, buf_len);
	sleep(1);

	printf("AT\n");
	printf("ATD%s\n", phone_num);
	printf("ATD%s;\n", phone_num);
}

