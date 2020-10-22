#include "uart.h"

int main(int argc, char **argv)
{
	int fd;
    int baud;
    char dev_name[128];

	printf("Serial Test Start... (%s)\n", __DATE__);

    strcpy(dev_name, "/dev/ttyACM0");
    baud = 115200;

    fd = open_serial(dev_name, baud, 10, 32);

    if(fd < 0)
        return -2;

	gsm_msg_send(fd, "01029807183", "Hello BitAI");

	close_serial(fd);

	printf("Message Send Success\n");

	return 0;
}
