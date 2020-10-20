#include "uart.h"

int main(int argc, char **argv)
{
	int fd;
	int baud;
	char dev_name[128];
	char cc, buf[128];
	int rdcnt;

	if(argc != 3)
	{
		printf("sample_serial[device][baud]\n" \
				"device: /dev/ttyUSBx ...\n" \
				"baud: 2400 ... 115200\n");
		return -1;
	}

	printf("Serial Test Start... (%s)\n", __DATE__);

	strcpy(dev_name, argv[1]);
	baud = strtoul(argv[2], NULL, 10);

	fd = open_serial(dev_name, baud, 10, 32);

	if(fd < 0)
		return -2;

	for(cc = 'A'; cc <= 'z'; cc++)
	{
		memset(buf, cc, 32);
		write(fd, buf, 32);

		rdcnt = read(fd, buf, sizeof(buf));
		if(rdcnt > 0)
		{
			buf[rdcnt] = '\0';
			printf("<%s rd=%2d> %s\n", dev_name, rdcnt, buf);
		}

		sleep(1);
	}

	close_serial(fd);

	printf("serial test end\n");

	return 0;
}
