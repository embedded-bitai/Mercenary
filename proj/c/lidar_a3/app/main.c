#include <sys/select.h>

#include <asm/ioctls.h>
#include <asm/termbits.h>
#include <sys/ioctl.h>

#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <assert.h>
#include <fcntl.h>
#include <stdio.h>

#define EVENT_TIMEOUT	(-1)
#define EVENT_OK		(1)

#define min(a,b)            (((a) < (b)) ? (a) : (b))

#define _countof(_Array) (int)(sizeof(_Array) / sizeof(_Array[0]))

typedef int8_t			s8;
typedef uint8_t			u8;

typedef int16_t			s16; 
typedef uint16_t		u16;

typedef int32_t			s32;
typedef uint32_t		u32;

typedef int64_t			s64;
typedef uint64_t		u64;

typedef uint32_t		u_result;

#define DEFAULT_TIMEOUT	(2000)

#define ANS_OK			(0)
#define ANS_TIMEOUT		(-1)
#define ANS_DEV_ERR		(-2)

#define max(a,b) \
({ \
	__typeof__ (a) _a = (a); \
	__typeof__ (b) _b = (b); \
	_a > _b ? _a : _b; \
})

// Response
#define RPLIDAR_ANS_TYPE_DEVINFO          0x4
#define RPLIDAR_ANS_TYPE_DEVHEALTH        0x6

#define RPLIDAR_ANS_TYPE_MEASUREMENT                0x81
// Added in FW ver 1.17
#define RPLIDAR_ANS_TYPE_MEASUREMENT_CAPSULED       0x82
#define RPLIDAR_ANS_TYPE_MEASUREMENT_HQ            0x83

// Added in FW ver 1.17
#define RPLIDAR_ANS_TYPE_SAMPLE_RATE      0x15
// added in FW ver 1.23alpha
#define RPLIDAR_ANS_TYPE_MEASUREMENT_CAPSULED_ULTRA  0x84
// added in FW ver 1.24
#define RPLIDAR_ANS_TYPE_GET_LIDAR_CONF     0x20
#define RPLIDAR_ANS_TYPE_SET_LIDAR_CONF     0x21
#define RPLIDAR_ANS_TYPE_MEASUREMENT_DENSE_CAPSULED        0x85
#define RPLIDAR_ANS_TYPE_ACC_BOARD_FLAG   0xFF
        
#define RPLIDAR_RESP_ACC_BOARD_FLAG_MOTOR_CTRL_SUPPORT_MASK      (0x1)
typedef struct _rplidar_response_acc_board_flag_t {
    u32 support_flag;
} __attribute__((packed)) rplidar_response_acc_board_flag_t;

// RP-Lidar Input Packets
#define RPLIDAR_CMD_SYNC_BYTE        0xA5
#define RPLIDAR_CMDFLAG_HAS_PAYLOAD  0x80

#define RPLIDAR_ANS_SYNC_BYTE1       0xA5
#define RPLIDAR_ANS_SYNC_BYTE2       0x5A

#define RPLIDAR_ANS_PKTFLAG_LOOP     0x1

#define RPLIDAR_ANS_HEADER_SIZE_MASK        0x3FFFFFFF
#define RPLIDAR_ANS_HEADER_SUBTYPE_SHIFT    (30)

#define RESULT_OK              0
#define RESULT_FAIL_BIT        0x80000000
#define RESULT_ALREADY_DONE    0x20
#define RESULT_INVALID_DATA    (0x8000 | RESULT_FAIL_BIT)
#define RESULT_OPERATION_FAIL  (0x8001 | RESULT_FAIL_BIT)
#define RESULT_OPERATION_TIMEOUT  (0x8002 | RESULT_FAIL_BIT)
#define RESULT_OPERATION_STOP    (0x8003 | RESULT_FAIL_BIT)
#define RESULT_OPERATION_NOT_SUPPORT    (0x8004 | RESULT_FAIL_BIT)
#define RESULT_FORMAT_NOT_SUPPORT    (0x8005 | RESULT_FAIL_BIT)
#define RESULT_INSUFFICIENT_MEMORY   (0x8006 | RESULT_FAIL_BIT)

#define IS_OK(x)    ( ((x) & RESULT_FAIL_BIT) == 0 )
#define IS_FAIL(x)  ( ((x) & RESULT_FAIL_BIT) )

// Commands without payload and response
#define RPLIDAR_CMD_STOP               0x25
#define RPLIDAR_CMD_SCAN               0x20
#define RPLIDAR_CMD_FORCE_SCAN         0x21
#define RPLIDAR_CMD_RESET              0x40
    
// Commands without payload but have response
#define RPLIDAR_CMD_GET_DEVICE_INFO    0x50
#define RPLIDAR_CMD_GET_DEVICE_HEALTH  0x52

#define RPLIDAR_CMD_GET_SAMPLERATE     0x59 //added in fw 1.17
    
#define RPLIDAR_CMD_HQ_MOTOR_SPEED_CTRL      0xA8
    
// Commands with payload and have response
#define RPLIDAR_CMD_EXPRESS_SCAN       0x82 //added in fw 1.17
#define RPLIDAR_CMD_HQ_SCAN                  0x83 //added in fw 1.24
#define RPLIDAR_CMD_GET_LIDAR_CONF           0x84 //added in fw 1.24
#define RPLIDAR_CMD_SET_LIDAR_CONF           0x85 //added in fw 1.24

//add for A2 to set RPLIDAR motor pwm when using accessory board
#define RPLIDAR_CMD_SET_MOTOR_PWM      0xF0
#define RPLIDAR_CMD_GET_ACC_BOARD_FLAG 0xFF

#define MAX_MOTOR_PWM               1023
#define DEFAULT_MOTOR_PWM           660
typedef struct _rplidar_payload_motor_pwm_t {
    u16 pwm_value;
} __attribute__((packed)) rplidar_payload_motor_pwm_t;

char portname[64] = "";
unsigned int serial_baudrate = 256000;

int serial_fd;
int serial_flags;

int selfpipe[2] = { -1, -1 };

bool is_scanning = false;
bool is_connected = false;
bool is_serial_opened = false;
bool operation_aborted = false;
bool is_support_motor_ctrl = false;
bool ctrl_c_pressed = false;

int required_tx_cnt = 0;
int required_rx_cnt = 0;

pthread_mutex_t serial_mtx;

u64 rp_getus(void)
{
    struct timespec t;
    t.tv_sec = t.tv_nsec = 0;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1000000LL + t.tv_nsec / 1000;
}

u32 rp_getms(void)
{
    struct timespec t;
    t.tv_sec = t.tv_nsec = 0;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec * 1000L + t.tv_nsec / 1000000L;
}

#define getms() rp_getms()

typedef struct _rplidar_cmd_packet_t {
    u8 syncByte; //must be RPLIDAR_CMD_SYNC_BYTE
    u8 cmd_flag;
    u8 size;
    u8 data[0];
} __attribute__((packed)) rplidar_cmd_packet_t;

typedef struct _rplidar_ans_header_t {
    u8  syncByte1; // must be RPLIDAR_ANS_SYNC_BYTE1
    u8  syncByte2; // must be RPLIDAR_ANS_SYNC_BYTE2
    u32 size_q30_subtype; // see _u32 size:30; _u32 subType:2;
    u8  type;
} __attribute__((packed)) rplidar_ans_header_t; 

typedef struct _rplidar_response_device_info_t {
    u8		model;
    u16		firmware_version;
    u8		hardware_version;
    u8		serialnum[16];
} __attribute__((packed)) rplidar_response_device_info_t;

typedef struct _rplidar_payload_acc_board_flag_t {
    u32 reserved;
} __attribute__((packed)) rplidar_payload_acc_board_flag_t;

typedef struct _rplidar_response_device_health_t {
    _u8   status;
    _u16  error_code;
} __attribute__((packed)) rplidar_response_device_health_t;

void clear_dtr(void);

bool connected()
{
	return is_connected;
}

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

void disable_data_grab(void)
{
	is_scanning = false;
}

int senddata(const unsigned char *data, size_t size)
{   
    if (!is_opened())
		return 0;

    if (data == NULL || size ==0) return 0;

    size_t tx_len = 0;
    required_tx_cnt = 0;

    do {
        int ans = write(serial_fd, data + tx_len, size-tx_len);

        if (ans == -1)
			return tx_len;

        tx_len += ans; 
        required_tx_cnt = tx_len;
    } while (tx_len<size);

    return tx_len;
}

u_result send_command(u8 cmd, const void *payload, size_t payloadsize)
{
    u8 pkt_header[10];
    //rplidar_cmd_packet_t *header = reinterpret_cast<rplidar_cmd_packet_t *>(pkt_header);
    rplidar_cmd_packet_t *header = (rplidar_cmd_packet_t *)pkt_header;
    u8 checksum = 0;

    if (!is_connected)
		return RESULT_OPERATION_FAIL;

    if (payloadsize && payload) {
        cmd |= RPLIDAR_CMDFLAG_HAS_PAYLOAD;
    }

    header->syncByte = RPLIDAR_CMD_SYNC_BYTE;
    header->cmd_flag = cmd;

    // send header first
    senddata(pkt_header, 2);

	if (cmd & RPLIDAR_CMDFLAG_HAS_PAYLOAD) {
		checksum ^= RPLIDAR_CMD_SYNC_BYTE; 
		checksum ^= cmd;
		checksum ^= (payloadsize & 0xFF);

		// calc checksum
		for (size_t pos = 0; pos < payloadsize; ++pos) {
			checksum ^= ((u8 *)payload)[pos];
		}   

		// send size
		u8 sizebyte = payloadsize;
		senddata(&sizebyte, 1);

		// send payload
		senddata((const u8 *)payload, sizebyte);

		// send checksum
		senddata(&checksum, 1);
	}

	return RESULT_OK;
}

int waitfordata(size_t data_count, u32 timeout, size_t *returned_size)
{   
    size_t length = 0; 
    if (returned_size == NULL)
		returned_size = (size_t *)&length;

    *returned_size = 0;
    
    int max_fd;
    fd_set input_set;
    struct timeval timeout_val;
        
    /* Initialize the input set */
    FD_ZERO(&input_set);
    FD_SET(serial_fd, &input_set);
        
    if (selfpipe[0] != -1)
        FD_SET(selfpipe[0], &input_set);
        
    max_fd = max(serial_fd, selfpipe[0]) + 1;
  
    /* Initialize the timeout structure */
    timeout_val.tv_sec = timeout / 1000;
    timeout_val.tv_usec = (timeout % 1000) * 1000;

    if ( is_opened() )
    {
        if ( ioctl(serial_fd, FIONREAD, returned_size) == -1) return ANS_DEV_ERR;
        if (*returned_size >= data_count)
        {
            return 0;
        }
    }

    while ( is_opened() )
	{
		/* Do the select */
        int n = select(max_fd, &input_set, NULL, NULL, &timeout_val);

        if (n < 0)
        {
            // select error
            *returned_size =  0;
            return ANS_DEV_ERR;
        }
        else if (n == 0)
        {
            // time out
            *returned_size =0;
            return ANS_TIMEOUT;
        }
        else
        {
			if (FD_ISSET(selfpipe[0], &input_set))
			{
                // require aborting the current operation
                int ch;
                for (;;)
				{
                    if (read(selfpipe[0], &ch, 1) == -1)
					{
                        break;
                    }

                }

                // treat as timeout
                *returned_size = 0;
                return ANS_TIMEOUT;
            }

            // data avaliable
            assert (FD_ISSET(serial_fd, &input_set));

            if ( ioctl(serial_fd, FIONREAD, returned_size) == -1)
				return ANS_DEV_ERR;

            if (*returned_size >= data_count)
            {
                return 0;
            }
            else
            {
                int remain_timeout = timeout_val.tv_sec*1000000 + timeout_val.tv_usec;
                int expect_remain_time = (data_count - *returned_size) * 1000000 * 8 / serial_baudrate;
                if (remain_timeout > expect_remain_time)
                    usleep(expect_remain_time);
            }
        }
    }

    return ANS_DEV_ERR;
}

int recvdata(unsigned char *data, size_t size)
{
    if (!is_opened())
		return 0;

    int ans = read(serial_fd, data, size);

    if (ans == -1)
		ans = 0;

    required_rx_cnt = ans;

    return ans; 
}

u_result wait_response_header(rplidar_ans_header_t *header, u32 timeout)
{
    int  recvPos = 0;
    u32 startTs = getms();
    u8  recvBuffer[sizeof(rplidar_ans_header_t)];
    //u8  *headerBuffer = reinterpret_cast<_u8 *>(header);
    u8 *headerBuffer = (u8 *)header;
    u32 waitTime;

    while ((waitTime = getms() - startTs) <= timeout) {
        size_t remainSize = sizeof(rplidar_ans_header_t) - recvPos;
        size_t recvSize;

        bool ans = waitfordata(remainSize, timeout - waitTime, &recvSize);
        if (!ans)
			return RESULT_OPERATION_TIMEOUT;

        if (recvSize > remainSize)
			recvSize = remainSize;

        recvSize = recvdata(recvBuffer, recvSize);

        for (size_t pos = 0; pos < recvSize; ++pos)
		{
            u8 currentByte = recvBuffer[pos];
            switch (recvPos)
			{
            	case 0:
            	    if (currentByte != RPLIDAR_ANS_SYNC_BYTE1)
					{
            	       continue;
            	    }

                	break;
	            case 1:
    	            if (currentByte != RPLIDAR_ANS_SYNC_BYTE2)
					{
        	            recvPos = 0;
            	        continue;
            	    }
                	break;
            }
            headerBuffer[recvPos++] = currentByte;

			if (recvPos == sizeof(rplidar_ans_header_t))
			{
                return RESULT_OK;
            }
        }
    }

    return RESULT_OPERATION_TIMEOUT;
}

u_result check_motor_ctrl_support(bool support, u32 timeout)
{
	u_result	ans;
	support = false;

	size_t returned_size;

	rplidar_response_acc_board_flag_t acc_board_flag;
	rplidar_payload_acc_board_flag_t flag;
	rplidar_ans_header_t response_header;
	u32 header_size;

	if (!connected())
		return RESULT_OPERATION_FAIL;

	disable_data_grab();

	{
		pthread_mutex_lock(&serial_mtx);
		flag.reserved = 0;

		if (IS_FAIL(ans = send_command(RPLIDAR_CMD_GET_ACC_BOARD_FLAG, &flag, sizeof(flag)))) {
			return ans;
		}

		if (IS_FAIL(ans = wait_response_header(&response_header, timeout))) {
			return ans;
		}   

		// verify whether we got a correct header
		if (response_header.type != RPLIDAR_ANS_TYPE_ACC_BOARD_FLAG) {
			return RESULT_INVALID_DATA;
		}

		header_size = (response_header.size_q30_subtype & RPLIDAR_ANS_HEADER_SIZE_MASK);
		if ( header_size < sizeof(rplidar_response_acc_board_flag_t)) {
			return RESULT_INVALID_DATA;
		}

		if (!waitfordata(header_size, timeout, &returned_size)) {
			return RESULT_OPERATION_TIMEOUT;
		}

		recvdata((u8 *)(&acc_board_flag), sizeof(acc_board_flag));

		if (acc_board_flag.support_flag & RPLIDAR_RESP_ACC_BOARD_FLAG_MOTOR_CTRL_SUPPORT_MASK) {
			support = true;
		}

		pthread_mutex_unlock(&serial_mtx);
	}

	return RESULT_OK;
}

u_result set_motor_PWM(u16 pwm)
{
    u_result ans;
    rplidar_payload_motor_pwm_t motor_pwm;
    motor_pwm.pwm_value = pwm;

    {
		pthread_mutex_lock(&serial_mtx);

        if (IS_FAIL(ans = send_command(RPLIDAR_CMD_SET_MOTOR_PWM, (const u8 *)&motor_pwm, sizeof(motor_pwm))))
		{
            return ans;
        }

		pthread_mutex_unlock(&serial_mtx);
    }

    return RESULT_OK;
}

static inline void delay(u32 ms)
{
    while (ms >= 1000)
	{
        usleep(1000*1000);
        ms-=1000;
    }

    if (ms != 0)
        usleep(ms * 1000);
}

u_result start_motor(void)
{
    if (is_supporting_motor_ctrl)
	{
		// RPLIDAR A2
        set_motor_PWM(DEFAULT_MOTOR_PWM);
        delay(500); 
        return RESULT_OK; 
    }
	else
	{
		// RPLIDAR A1
		pthread_mutex_lock(&serial_mtx);

        //_chanDev->clearDTR();
        delay(500);

		pthread_mutex_unlock(&serial_mtx);

        return RESULT_OK;
    }
}

u_result stop(u32 timeout)
{
    u_result ans;
    disable_data_grab();

    {
		pthread_mutex_lock(&serial_mtx);

        if (IS_FAIL(ans = send_command(RPLIDAR_CMD_STOP))) {
            return ans;
        }

		pthread_mutex_unlock(&serial_mtx);
    }

    return RESULT_OK;
}

u_result stop_motor(void)
{
    if (is_support_motor_ctrl)
	{
		// RPLIDAR A2
        set_motor_PWM(0);
        delay(500);
        return RESULT_OK;
    }
	else
	{
		// RPLIDAR A1
		pthread_mutex_lock(&serial_mtx);

        //_chanDev->setDTR();
        delay(500);

		pthread_mutex_unlock(&serial_mtx);

        return RESULT_OK;
    }
}

bool serial_connect(char *path, unsigned int baudrate)
{
	pthread_mutex_init(&serial_mtx, NULL);
	pthread_mutex_lock(&serial_mtx);

	if (!serial_bind(path, baudrate) || !serial_open()) 
	{
		return false;
	}
	serial_flush();

	pthread_mutex_unlock(&serial_mtx);

	is_connected = true;

	check_motor_ctrl_support(is_support_motor_ctrl, DEFAULT_TIMEOUT);
    stop_motor();

	return true;
}

u_result get_device_info(rplidar_response_device_info_t *info, u32 timeout)
{
    u_result  ans;
	void *payload = NULL;
	size_t payloadsize = 0;
	size_t *returned_size = NULL;

    if (!connected())
		return RESULT_OPERATION_FAIL;

    disable_data_grab();

    {
		pthread_mutex_unlock(&serial_mtx);

        if (IS_FAIL(ans = send_command(RPLIDAR_CMD_GET_DEVICE_INFO, payload, payloadsize))) {
            return ans;
        }

        rplidar_ans_header_t response_header;
        if (IS_FAIL(ans = wait_response_header(&response_header, timeout))) {
            return ans;
        }

        // verify whether we got a correct header
        if (response_header.type != RPLIDAR_ANS_TYPE_DEVINFO) {
            return RESULT_INVALID_DATA;
        }

        u32 header_size = (response_header.size_q30_subtype & RPLIDAR_ANS_HEADER_SIZE_MASK);
        if (header_size < sizeof(rplidar_response_device_info_t)) {
            return RESULT_INVALID_DATA;
        }

        if (!waitfordata(header_size, timeout, returned_size)) {
            return RESULT_OPERATION_TIMEOUT;
        }
        recvdata((u8 *)(info), sizeof(info));

		pthread_mutex_unlock(&serial_mtx);
    }
    return RESULT_OK;
}

u_result get_health(rplidar_response_device_health_t *healthinfo, u32 timeout)
{
    u_result  ans;
	rplidar_ans_header_t response_header;
	u32 header_size;

    if (!connected())
		return RESULT_OPERATION_FAIL;

    disable_data_grab();

    {
		pthread_mutex_lock(&serial_mtx);

        if (IS_FAIL(ans = send_command(RPLIDAR_CMD_GET_DEVICE_HEALTH))) {
            return ans;
        }

        if (IS_FAIL(ans = wait_response_header(&response_header, timeout))) {
            return ans;
        }

        // verify whether we got a correct header
        if (response_header.type != RPLIDAR_ANS_TYPE_DEVHEALTH) {
            return RESULT_INVALID_DATA;
        }

        header_size = (response_header.size_q30_subtype & RPLIDAR_ANS_HEADER_SIZE_MASK);
        if ( header_size < sizeof(rplidar_response_device_health_t)) {
            return RESULT_INVALID_DATA;
        }

         if (!waitfordata(header_size, timeout)) {
            return RESULT_OPERATION_TIMEOUT;
        }
        recvdata((u8 *)(healthinfo), sizeof(healthinfo));

		pthread_mutex_unlock(&serial_mtx);
    }
    return RESULT_OK;
}

bool check_RPLIDAR_health(void)
{
    u_result     op_result;
    rplidar_response_device_health_t healthinfo;

    op_result = get_health(&healthinfo, DEFAULT_TIMEOUT);
    if (IS_OK(op_result))
	{
		// the macro IS_OK is the preperred way to judge whether the operation is succeed.
        printf("RPLidar health status : %d\n", healthinfo.status);
        if (healthinfo.status == RPLIDAR_STATUS_ERROR)
		{
            fprintf(stderr, "Error, rplidar internal error detected. Please reboot the device to retry.\n");
            // enable the following code if you want rplidar to be reboot by software
            // drv->reset();
            return false;
        }
		else
		{
            return true;
        }
    }
	else
	{
        fprintf(stderr, "Error, cannot retrieve the lidar health code: %x\n", op_result);
        return false;
    }
}

u_result check_support_config_commands(bool& outSupport, u32 timeoutInMs)
{
    u_result ans;

    rplidar_response_device_info_t devinfo;
    ans = get_device_info(devinfo, timeoutInMs);

    if (IS_FAIL(ans))
		return ans;

    // if lidar firmware >= 1.24
    if (devinfo.firmware_version >= ((0x1 << 8) | 24))
	{
        outSupport = true;
    }

    return ans;
}

u_result get_lidar_conf(u32 type, std::vector<u8> &outputBuf, const std::vector<u8> &reserve, _u32 timeout)
{
	rplidar_ans_header_t response_header;
    rplidar_payload_get_scan_conf_t query;

	u32 replyType = -1;
	u32 header_size;
    u_result ans;

	//std::vector<u8> dataBuf;
	int payLoadLen;

    int sizeVec = reserve.size();
	int maxLen;

    memset(&query, 0, sizeof(query));
    query.type = type;

    maxLen = sizeof(query.reserved) / sizeof(query.reserved[0]);
    if (sizeVec > maxLen)
		sizeVec = maxLen;

    if (sizeVec > 0)
        memcpy(query.reserved, &reserve[0], reserve.size());

    {
		pthread_mutex_lock(&serial_mtx);

        if (IS_FAIL(ans = send_command(RPLIDAR_CMD_GET_LIDAR_CONF, &query, sizeof(query)))) {
            return ans;
        }

        // waiting for confirmation
        if (IS_FAIL(ans = wait_response_header(&response_header, timeout))) {
            return ans;
        }

        // verify whether we got a correct header
        if (response_header.type != RPLIDAR_ANS_TYPE_GET_LIDAR_CONF) {
            return RESULT_INVALID_DATA;
        }

		header_size = (response_header.size_q30_subtype & RPLIDAR_ANS_HEADER_SIZE_MASK);
        if (header_size < sizeof(type)) {
            return RESULT_INVALID_DATA;
        }

        if (!waitfordata(header_size, timeout)) {
            return RESULT_OPERATION_TIMEOUT;
        }

        dataBuf.resize(header_size);
        recvdata(reinterpret_cast<u8 *>(&dataBuf[0]), header_size);

        //check if returned type is same as asked type
        memcpy(&replyType, &dataBuf[0], sizeof(type));

        if (replyType != type) {
            return RESULT_INVALID_DATA;
        }

        //copy all the payload into &outputBuf
        payLoadLen = header_size - sizeof(type);

        //do consistency check
        if (payLoadLen <= 0) {
            return RESULT_INVALID_DATA;
        }

        //copy all payLoadLen bytes to outputBuf
        outputBuf.resize(payLoadLen);
        memcpy(&outputBuf[0], &dataBuf[0] + sizeof(type), payLoadLen);

		pthread_mutex_unlock(&serial_mtx);
    }

    return ans;
}

u_result get_typical_scan_mode(u16& outMode, u32 timeoutInMs)
{
    u_result ans;
    std::vector<_u8> answer;
    bool lidar_support_config_cmds = false;
    ans = check_support_config_commands(lidar_support_config_cmds);

    if (IS_FAIL(ans))
		return RESULT_INVALID_DATA;

    if (lidar_support_config_cmds)
    {
        ans = get_lidar_conf(RPLIDAR_CONF_SCAN_MODE_TYPICAL, answer, std::vector<_u8>(), timeoutInMs);
        if (IS_FAIL(ans))
		{
            return ans;
        }

        if (answer.size() < sizeof(u16))
		{
            return RESULT_INVALID_DATA;
        }

        const u16 *p_answer = (const u16 *)(&answer[0]);
        outMode = *p_answer;
        return ans;
    }
    //old version of triangle lidar
    else
    {
        outMode = RPLIDAR_CONF_SCAN_COMMAND_EXPRESS;
        return ans;
    }

    return ans;
}

_result get_lidar_sample_duration(float& sampleDurationRes, u16 scanModeID, u32 timeoutInMs)
{
    u_result ans;
    std::vector<u8> reserve(2);
    memcpy(&reserve[0], &scanModeID, sizeof(scanModeID));

    std::vector<u8> answer;
    ans = get_lidar_conf(RPLIDAR_CONF_SCAN_MODE_US_PER_SAMPLE, answer, reserve, timeoutInMs);

    if (IS_FAIL(ans))
    {
        return ans;
    }

    if (answer.size() < sizeof(u32))
    {
        return RESULT_INVALID_DATA;
    }

    const u32 *result = (const u32 *)(&answer[0]);
    sampleDurationRes = (float)(*result >> 8);
    return ans;
}

u_result get_max_distance(float &maxDistance, u16 scanModeID, u32 timeoutInMs)
{
    u_result ans;
    std::vector<u8> reserve(2);
    memcpy(&reserve[0], &scanModeID, sizeof(scanModeID));

    std::vector<u8> answer;
    ans = get_lidar_conf(RPLIDAR_CONF_SCAN_MODE_MAX_DISTANCE, answer, reserve, timeoutInMs);

    if (IS_FAIL(ans))
    {
        return ans;
    }

    if (answer.size() < sizeof(u32))
    {
        return RESULT_INVALID_DATA;
    }

    const u32 *result = (const u32 *)(&answer[0]);
    maxDistance = (float)(*result >> 8);
    return ans;
}

u_result get_scan_mode_ans_type(u8 &ansType, u16 scanModeID, u32 timeoutInMs)
{
    u_result ans;
    std::vector<u8> reserve(2);
    memcpy(&reserve[0], &scanModeID, sizeof(scanModeID));

    std::vector<u8> answer;
    ans = get_lidar_conf(RPLIDAR_CONF_SCAN_MODE_ANS_TYPE, answer, reserve, timeoutInMs);

    if (IS_FAIL(ans))
    {
        return ans;
    }

    if (answer.size() < sizeof(u8))
    {
        return RESULT_INVALID_DATA;
    }

    const u8 *result = (const u8 *)(&answer[0]);
    ansType = *result;
    return ans;
}

u_result get_scan_mode_name(char* modeName, u16 scanModeID, u32 timeoutInMs)
{
    u_result ans;
    std::vector<u8> reserve(2);
    memcpy(&reserve[0], &scanModeID, sizeof(scanModeID));

    std::vector<u8> answer;
    ans = get_lidar_conf(RPLIDAR_CONF_SCAN_MODE_NAME, answer, reserve, timeoutInMs);

    if (IS_FAIL(ans))
    {
        return ans;
    }

    int len = answer.size();

    if (0 == len)
		return RESULT_INVALID_DATA;

    memcpy(modeName, &answer[0], len);
    return ans;
}

u_result get_sample_duration_us(rplidar_response_sample_rate_t & rateInfo, _u32 timeout)
{
	rplidar_ans_header_t response_header;
    rplidar_response_device_info_t devinfo;

	u32 header_size;

    u_result ans;

    DEPRECATED_WARN("getSampleDuration_uS", "RplidarScanMode::us_per_sample");

    if (!connected())
		return RESULT_OPERATION_FAIL;

    disable_data_grab();

    // 1. fetch the device version first...
    ans = get_device_info(devinfo, timeout);

    rateInfo.express_sample_duration_us = _cached_sampleduration_express;
    rateInfo.std_sample_duration_us = _cached_sampleduration_std;

    if (devinfo.firmware_version < ((0x1<<8) | 17)) {
        // provide fake data...

        return RESULT_OK;
    }

    {
		pthread_mutex_lock(&serial_mtx);

        if (IS_FAIL(ans = send_command(RPLIDAR_CMD_GET_SAMPLERATE))) {
            return ans;
        }

        if (IS_FAIL(ans = wait_response_header(&response_header, timeout))) {
            return ans;
        }

		// verify whether we got a correct header
        if (response_header.type != RPLIDAR_ANS_TYPE_SAMPLE_RATE) {
            return RESULT_INVALID_DATA;
        }

        header_size = (response_header.size_q30_subtype & RPLIDAR_ANS_HEADER_SIZE_MASK);
        if ( header_size < sizeof(rplidar_response_sample_rate_t)) {
            return RESULT_INVALID_DATA;
        }

        if (!waitfordata(header_size, timeout)) {
            return RESULT_OPERATION_TIMEOUT;
        }
        recvdata((u8 *)(&rateInfo), sizeof(rateInfo));

		pthread_mutex_unlock(&serial_mtx);
    }

    return RESULT_OK;
}

u_result start_scan_express(bool force, u16 scanMode, u32 options, RplidarScanMode *outUsedScanMode, u32 timeout)
{
	rplidar_payload_express_scan_t scanReq;
	rplidar_ans_header_t response_header;

    bool if_support_lidar_conf = false;
	u32 header_size;

    u8 scanAnsType;
    u_result ans;

    if (!isConnected())
		return RESULT_OPERATION_FAIL;

    if (is_scanning)
		return RESULT_ALREADY_DONE;

    stop(); //force the previous operation to stop

    if (scanMode == RPLIDAR_CONF_SCAN_COMMAND_STD)
    {
        return start_scan(force, false, 0, outUsedScanMode);
    }

    ans = check_support_config_commands(if_support_lidar_conf);

    if (IS_FAIL(ans))
		return RESULT_INVALID_DATA;

    if (outUsedScanMode)
    {
        outUsedScanMode->id = scanMode;

        if (if_support_lidar_conf)
        {
            ans = get_lidar_sample_duration(outUsedScanMode->us_per_sample, outUsedScanMode->id);
			if (IS_FAIL(ans))
            {
                return RESULT_INVALID_DATA;
            }

            ans = get_max_distance(outUsedScanMode->max_distance, outUsedScanMode->id);
            if (IS_FAIL(ans))
            {
                return RESULT_INVALID_DATA;
            }

            ans = get_scan_mode_ans_type(outUsedScanMode->ans_type, outUsedScanMode->id);
            if (IS_FAIL(ans))
            {
                return RESULT_INVALID_DATA;
            }

            ans = get_scan_mode_name(outUsedScanMode->scan_mode, outUsedScanMode->id);
            if (IS_FAIL(ans))
            {
                return RESULT_INVALID_DATA;
            }
        }
        else
        {
			rplidar_response_sample_rate_t sampleRateTmp;
            ans = getSampleDuration_uS(sampleRateTmp);

            if (IS_FAIL(ans))
				return RESULT_INVALID_DATA;

            outUsedScanMode->us_per_sample = sampleRateTmp.express_sample_duration_us;
            outUsedScanMode->max_distance = 16;
            outUsedScanMode->ans_type = RPLIDAR_ANS_TYPE_MEASUREMENT_CAPSULED;
            strcpy(outUsedScanMode->scan_mode, "Express");
        }
    }

    //get scan answer type to specify how to wait data
    if (ifSupportLidarConf)
    {
        get_scan_mode_ans_type(scanAnsType, scanMode);
    }
    else
    {
        scanAnsType = RPLIDAR_ANS_TYPE_MEASUREMENT_CAPSULED;
    }

    {
		pthread_mutex_lock(&serial_mtx);

        memset(&scanReq, 0, sizeof(scanReq));
        if (scanMode != RPLIDAR_CONF_SCAN_COMMAND_STD && scanMode != RPLIDAR_CONF_SCAN_COMMAND_EXPRESS)
            scanReq.working_mode = _u8(scanMode);
        scanReq.working_flags = options;

        if (IS_FAIL(ans = _sendCommand(RPLIDAR_CMD_EXPRESS_SCAN, &scanReq, sizeof(scanReq)))) {
            return ans;
        }

        // waiting for confirmation
        if (IS_FAIL(ans = _waitResponseHeader(&response_header, timeout))) {
            return ans;
        }

        // verify whether we got a correct header
        if (response_header.type != scanAnsType) {
            return RESULT_INVALID_DATA;
        }

        header_size = (response_header.size_q30_subtype & RPLIDAR_ANS_HEADER_SIZE_MASK);

        if (scanAnsType == RPLIDAR_ANS_TYPE_MEASUREMENT_CAPSULED)
        {
            if (header_size < sizeof(rplidar_response_capsule_measurement_nodes_t)) {
                return RESULT_INVALID_DATA;
            }
            _cached_express_flag = 0;
            _isScanning = true;
            _cachethread = CLASS_THREAD(RPlidarDriverImplCommon, _cacheCapsuledScanData);
        }
        else if (scanAnsType == RPLIDAR_ANS_TYPE_MEASUREMENT_DENSE_CAPSULED)
        {
			if (header_size < sizeof(rplidar_response_capsule_measurement_nodes_t)) {
                return RESULT_INVALID_DATA;
            }
            _cached_express_flag = 1;
            _isScanning = true;
            _cachethread = CLASS_THREAD(RPlidarDriverImplCommon, _cacheCapsuledScanData);
        }
        else if (scanAnsType == RPLIDAR_ANS_TYPE_MEASUREMENT_HQ) {
            if (header_size < sizeof(rplidar_response_hq_capsule_measurement_nodes_t)) {
                return RESULT_INVALID_DATA;
            }
            _isScanning = true;
            _cachethread = CLASS_THREAD(RPlidarDriverImplCommon, _cacheHqScanData);
        }
        else
        {
            if (header_size < sizeof(rplidar_response_ultra_capsule_measurement_nodes_t)) {
                return RESULT_INVALID_DATA;
            }
            _isScanning = true;
            _cachethread = CLASS_THREAD(RPlidarDriverImplCommon, _cacheUltraCapsuledScanData);
        }

        if (_cachethread.getHandle() == 0) {
            return RESULT_OPERATION_FAIL;
        }

		pthread_mutex_unlock(&serial_mtx);
    }

    return RESULT_OK;
}

u_result check_express_scan_supported(bool & support, u32 timeout)
{
    DEPRECATED_WARN("checkExpressScanSupported(bool&, u32)", "getAllSupportedScanModes()");

    rplidar_response_device_info_t devinfo;

    support = false;
    u_result ans = get_device_info(devinfo, timeout);

    if (IS_FAIL(ans))
		return ans;

    if (devinfo.firmware_version >= ((0x1<<8) | 17))
	{
        support = true;
        rplidar_response_sample_rate_t sample_rate;
        get_sample_duration_us(sample_rate);
        _cached_sampleduration_express = sample_rate.express_sample_duration_us;
        _cached_sampleduration_std = sample_rate.std_sample_duration_us;
    }

    return RESULT_OK;
}

u_result RPlidarDriverImplCommon::startScanNormal(bool force,  _u32 timeout)
{
	u32 header_size;
    u_result ans;

	rplidar_ans_header_t response_header;

    if (!connected())
		return RESULT_OPERATION_FAIL;

    if (_isScanning)
		return RESULT_ALREADY_DONE;

    stop(); //force the previous operation to stop

    {
		pthread_mutex_lock(&serial_mtx);

        if (IS_FAIL(ans = send_command(force?RPLIDAR_CMD_FORCE_SCAN:RPLIDAR_CMD_SCAN)))
		{
            return ans;
        }

        // waiting for confirmation
        if (IS_FAIL(ans = wait_response_header(&response_header, timeout)))
		{
            return ans;
        }

		// verify whether we got a correct header
        if (response_header.type != RPLIDAR_ANS_TYPE_MEASUREMENT)
		{
            return RESULT_INVALID_DATA;
        }

        header_size = (response_header.size_q30_subtype & RPLIDAR_ANS_HEADER_SIZE_MASK);
        if (header_size < sizeof(rplidar_response_measurement_node_t))
		{
            return RESULT_INVALID_DATA;
        }

        _isScanning = true;
        _cachethread = CLASS_THREAD(RPlidarDriverImplCommon, _cacheScanData);

        if (_cachethread.getHandle() == 0)
		{
            return RESULT_OPERATION_FAIL;
        }

		pthread_mutex_unlock(&serial_mtx);
    }

    return RESULT_OK;
}

u_result start_scan(bool force, bool use_typical_scan, u32 options, RplidarScanMode *outUsedScanMode)
{
    u_result ans;

    bool if_support_lidar_conf = false;
    ans = check_support_config_commands(if_support_lidar_conf);

    if (IS_FAIL(ans))
		return RESULT_INVALID_DATA;

    if (use_typical_scan)
    { 
        //if support lidar config protocol
        if (if_support_lidar_conf)
        {
            u16 typical_mode;  
            ans = get_typical_scan_mode(typical_mode);

            if (IS_FAIL(ans))
				return RESULT_INVALID_DATA;
    
            //call startScanExpress to do the job 
            return start_scan_express(false, typicalMode, 0, outUsedScanMode);
        }
        //if old version of triangle lidar
        else
        {
            bool isExpScanSupported = false;
            ans = check_express_scan_supported(isExpScanSupported);

            if (IS_FAIL(ans))
			{
                return ans;
            }

            if (isExpScanSupported)
            {
                return start_scan_express(false, RPLIDAR_CONF_SCAN_COMMAND_EXPRESS, 0, outUsedScanMode);
            }
        }
    }

	// 'useTypicalScan' is false, just use normal scan mode
    if (ifSupportLidarConf)
    {
        if (outUsedScanMode)
        {
            outUsedScanMode->id = RPLIDAR_CONF_SCAN_COMMAND_STD;
            ans = get_lidar_sample_duration(outUsedScanMode->us_per_sample, outUsedScanMode->id);

            if (IS_FAIL(ans))
            {
                return RESULT_INVALID_DATA;
            }

            ans = get_max_distance(outUsedScanMode->max_distance, outUsedScanMode->id);
            if (IS_FAIL(ans))
            {
                return RESULT_INVALID_DATA;
            }

            ans = get_scan_mode_ans_type(outUsedScanMode->ans_type, outUsedScanMode->id);
            if (IS_FAIL(ans))
            {
                return RESULT_INVALID_DATA;
            }

            ans = get_scan_mode_name(outUsedScanMode->scan_mode, outUsedScanMode->id);
            if (IS_FAIL(ans))
            {
                return RESULT_INVALID_DATA;
            }
        }
    }
    else
	{
        if (outUsedScanMode)
        {
            rplidar_response_sample_rate_t sampleRateTmp;
            ans = get_sample_duration_us(sampleRateTmp);

            if (IS_FAIL(ans))
				return RESULT_INVALID_DATA;

            outUsedScanMode->us_per_sample = sampleRateTmp.std_sample_duration_us;
            outUsedScanMode->max_distance = 16;
            outUsedScanMode->ans_type = RPLIDAR_ANS_TYPE_MEASUREMENT;
            strcpy(outUsedScanMode->scan_mode, "Standard");
        }
    }

    return startScanNormal(force);
}

static void convert(const rplidar_response_measurement_node_hq_t& from, rplidar_response_measurement_node_t& to)
{
    to.sync_quality = (from.flag & RPLIDAR_RESP_MEASUREMENT_SYNCBIT) | ((from.quality >> RPLIDAR_RESP_MEASUREMENT_QUALITY_SHIFT) << RPLIDAR_RESP_MEASUREMENT_QUALITY_SHIFT);
    to.angle_q6_checkbit = 1 | (((from.angle_z_q14 * 90) >> 8) << RPLIDAR_RESP_MEASUREMENT_ANGLE_SHIFT);
    to.distance_q2 = from.dist_mm_q2 > _u16(-1) ? _u16(0) : _u16(from.dist_mm_q2);
}

u_result grab_scan_data(rplidar_response_measurement_node_t *nodebuffer, size_t & count, u32 timeout)
{
    DEPRECATED_WARN("grabScanData()", "grabScanDataHq()");

    switch (_dataEvt.wait(timeout))
    {
		case EVENT_TIMEOUT:
    	    count = 0;
    	    return RESULT_OPERATION_TIMEOUT;
		case EVENT_OK:
        	{
            	if(_cached_scan_node_hq_count == 0)
					return RESULT_OPERATION_TIMEOUT; //consider as timeout

				pthread_mutex_lock(&serial_mtx);
    
            	size_t size_to_copy = min(count, _cached_scan_node_hq_count);
    
            	for (size_t i = 0; i < size_to_copy; i++)
                	convert(_cached_scan_node_hq_buf[i], nodebuffer[i]);
    
            	count = size_to_copy;
            	_cached_scan_node_hq_count = 0;

				pthread_mutex_unlock(&serial_mtx);
        	}
        	return RESULT_OK;

	    default:
    	    count = 0;
        	return RESULT_OPERATION_FAIL;
    }
}

static inline u16 get_distance_Q2(const rplidar_response_measurement_node_t& node)
{
    return node.distance_q2;
}

static inline float get_angle(const rplidar_response_measurement_node_hq_t& node)
{
    return node.angle_z_q14 * 90.f / 16384.f;
}

static inline void set_angle(rplidar_response_measurement_node_hq_t& node, float v)
{
    node.angle_z_q14 = _u32(v * 16384.f / 90.f);
}

template < class TNode >
static u_result ascendScanData_(TNode * nodebuffer, size_t count)
{
    float inc_origin_angle = 360.f/count;
    size_t i = 0;

    //Tune head
    for (i = 0; i < count; i++)
	{
        if(get_distance_Q2(nodebuffer[i]) == 0)
		{
            continue;
        }
		else
		{
            while(i != 0)
			{
                i--;
                float expect_angle = get_angle(nodebuffer[i+1]) - inc_origin_angle;

                if (expect_angle < 0.0f)
					expect_angle = 0.0f;

                set_angle(nodebuffer[i], expect_angle);
            }
            break;
        }
    }

    // all the data is invalid
    if (i == count)
		return RESULT_OPERATION_FAIL;

    //Tune tail
    for (i = count - 1; i >= 0; i--)
	{
        if(get_distance_Q2(nodebuffer[i]) == 0)
		{
            continue;
        }
		else
		{
            while(i != (count - 1))
			{
                i++;
                float expect_angle = get_angle(nodebuffer[i-1]) + inc_origin_angle;

                if (expect_angle > 360.0f)
					expect_angle -= 360.0f;

                set_angle(nodebuffer[i], expect_angle);
            }
            break;
        }
    }

	//Fill invalid angle in the scan
    float frontAngle = get_angle(nodebuffer[0]);
    for (i = 1; i < count; i++)
	{
        if(get_distance_Q2(nodebuffer[i]) == 0)
		{
            float expect_angle = frontAngle + i * inc_origin_angle;

            if (expect_angle > 360.0f)
				expect_angle -= 360.0f;

            set_angle(nodebuffer[i], expect_angle);
        }
    }

    // Reorder the scan according to the angle value
    std::sort(nodebuffer, nodebuffer + count, &angleLessThan<TNode>);

    return RESULT_OK;
}

u_result ascend_scan_data(rplidar_response_measurement_node_hq_t *nodebuffer, size_t count)
{
    return ascend_scan_data_<rplidar_response_measurement_node_hq_t>(nodebuffer, count);
}

void ctrlc(int)
{
    ctrl_c_pressed = true;
}

int main(void)
{
	unsigned int timeout = 2000;

	bool operation_aborted = false;

	rplidar_response_device_info_t devinfo;
	bool connect_success = false;

	u_result	op_result;

	if (IS_OK(serial_connect("/dev/ttyUSB0", 256000)))
	{   
		op_result = get_device_info(&devinfo, timeout);

		if (IS_OK(op_result))
		{
			connect_success = true;
		}
	}

	if (!connect_success)
	{
        //fprintf(stderr, "Error, cannot bind to the specified serial port %s.\n", opt_com_path);
		printf("Error, cannot bind to the specified serial port\n");
        goto on_finished;
    }

	// print out the device serial number, firmware and hardware version number..
    printf("RPLIDAR S/N: ");

    for (int pos = 0; pos < 16 ;++pos)
	{
        printf("%02X", devinfo.serialnum[pos]);
    }

    printf("\n"
            "Firmware Ver: %d.%02d\n"
            "Hardware Rev: %d\n"
            , devinfo.firmware_version>>8
            , devinfo.firmware_version & 0xFF
            , (int)devinfo.hardware_version);

	if (!check_RPLIDAR_health())
	{
        goto on_finished;
    }

    signal(SIGINT, ctrlc);

	start_motor();
    // start scan...
    start_scan(0, 1);

	while (1)
	{
        rplidar_response_measurement_node_t nodes[8192];
        size_t   count = _countof(nodes);

        op_result = grab_scan_data(nodes, count);

        if (IS_OK(op_result))
		{
            ascend_scan_data(nodes, count);
            for (int pos = 0; pos < (int)count; ++pos)
			{
                printf("%s theta: %03.2f Dist: %08.2f Q: %d \n",
                    (nodes[pos].sync_quality & RPLIDAR_RESP_MEASUREMENT_SYNCBIT) ?"S ":"  ",
                    (nodes[pos].angle_q6_checkbit >> RPLIDAR_RESP_MEASUREMENT_ANGLE_SHIFT)/64.0f,
                    nodes[pos].distance_q2/4.0f,
                    nodes[pos].sync_quality >> RPLIDAR_RESP_MEASUREMENT_QUALITY_SHIFT);
            }
        }

        if (ctrl_c_pressed)
		{
            break;
        }
    }

	stop();
    stop_motor();

on_finished:
	return 0;
}
