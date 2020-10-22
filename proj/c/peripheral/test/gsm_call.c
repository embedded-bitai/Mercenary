#include "uart.h"

#include <stdbool.h>

bool call_exit = true;

void phone_call_exit(int signo)
{
	call_exit = false;
}

int main(int argc, char **argv)
{
	int fd;
    int baud;
    char dev_name[128];

	if (argc != 2)
	{
		printf("Need Phone Number\n");
		exit(0);
	}

	printf("Serial Test Start... (%s)\n", __DATE__);

    strcpy(dev_name, "/dev/ttyACM0");
	baud = 115200;

    fd = open_serial(dev_name, baud, 10, 32);

    if(fd < 0)
        return -2;

	signal(SIGINT, phone_call_exit);
	gsm_phone_call(fd, argv[1]);

	for(; call_exit; )
		;

	close_serial(fd);

	printf("Message Send Success\n");

	return 0;
}
