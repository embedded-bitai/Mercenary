#include <asm/ioctls.h>
#include <asm/termbits.h>
#include <sys/ioctl.h>

#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

char portname[64] = "";
unsigned int serial_baudrate = 256000;

int serial_fd;
int serial_flags;

int selfpipe[2] = { -1, -1 };

bool is_connected = false;
bool is_serial_opened = false;
bool operation_aborted = false;

pthread_mutex_t serial_mtx;

typedef int8_t         s8;
typedef uint8_t        u8;

typedef int16_t        s16; 
typedef uint16_t       u16;

typedef int32_t        s32;
typedef uint32_t       u32;

typedef int64_t        s64;
typedef uint64_t       u64;

typedef struct _rplidar_response_device_info_t {
    u8		model;
    u16		firmware_version;
    u8		hardware_version;
    u8		serialnum[16];
} __attribute__((packed)) rplidar_response_device_info_t;

void clear_dtr(void);

bool serial_bind(char *path, unsigned int baudrate)
{
	strncpy(portname, path, sizeof(portname));
	serial_baudrate = baudrate;

	return true;
}

bool serial_open()
{
	struct termios2 tio;

	serial_fd = open(portname, O_RDWR | O_NOCTTY | O_NDELAY);

	if (serial_fd == -1)
		return false;

    ioctl(serial_fd, TCGETS2, &tio);
    bzero(&tio, sizeof(struct termios2));

    tio.c_cflag = BOTHER;
    tio.c_cflag |= (CLOCAL | CREAD | CS8); //8 bit no hardware handshake

    tio.c_cflag &= ~CSTOPB;   //1 stop bit
	tio.c_cflag &= ~CRTSCTS;  //No CTS
    tio.c_cflag &= ~PARENB;   //No Parity

	tio.c_iflag &= ~(IXON | IXOFF | IXANY); // no sw flow control


    tio.c_cc[VMIN] = 0;         //min chars to read
    tio.c_cc[VTIME] = 0;        //time in 1/10th sec wait

    tio.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
    // raw output mode   
    tio.c_oflag &= ~OPOST;

    tio.c_ispeed = serial_baudrate;
    tio.c_ospeed = serial_baudrate;

    ioctl(serial_fd, TCSETS2, &tio);

	tcflush(serial_fd, TCIFLUSH);

    if (fcntl(serial_fd, F_SETFL, FNDELAY))
    {
        close(serial_fd);
        return false;
    }

    is_serial_opened = true;
    operation_aborted = false;

    //Clear the DTR bit to let the motor spin
    clear_dtr();
    do {
        // create self pipeline for wait cancellation
        if (pipe(selfpipe) == -1) break;

        int flags = fcntl(selfpipe[0], F_GETFL);
        if (flags == -1)
            break;

        flags |= O_NONBLOCK;                /* Make read end nonblocking */
        if (fcntl(selfpipe[0], F_SETFL, flags) == -1)
            break;

        flags = fcntl(selfpipe[1], F_GETFL);
        if (flags == -1)
            break;

        flags |= O_NONBLOCK;                /* Make write end nonblocking */
        if (fcntl(selfpipe[1], F_SETFL, flags) == -1)
            break;

    } while (0);
    
    return true;
}

bool is_opened(void)
{
	return is_serial_opened;
}

void clear_dtr(void)
{
    uint32_t dtr_bit;

	if ( !is_opened() )
		return;

    dtr_bit = TIOCM_DTR;

    ioctl(serial_fd, TIOCMBIC, &dtr_bit);
}

void serial_flush(void)
{
	tcflush(serial_fd,TCIFLUSH);
}

bool serial_connect(char *path, unsigned int baudrate)
{
	pthread_mutex_init(&serial_mtx, NULL);
	pthread_mutex_lock(&mtx);

	if (!serial_bind(path, baudrate) || !serial_open()) 
	{
		return false;
	}
	serial_flush();

	pthread_mutex_unlock(&mtx);

	is_connected = true;

	//checkMotorCtrlSupport(_isSupportingMotorCtrl);
    //stopMotor();

	return true;
}

int main(void)
{
	unsigned int timeout = 2000;

	int required_tx_cnt = 0, required_rx_cnt = 0;

	bool operation_aborted = false;


	rplidar_response_device_info_t devinfo;
	bool connectSuccess = false;

	return 0;
}
