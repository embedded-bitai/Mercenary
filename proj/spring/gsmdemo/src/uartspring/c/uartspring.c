#include <jni.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <linux/fs.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <stdbool.h>
#include <signal.h>

typedef struct _control_message
{
	int protocol;
	int operation;
} control_message;

typedef struct _control_packet
{
	long msg_type;
	control_message msg;
} control_packet;

bool continue_running = true;

void set_continue_running(int signo)
{
	continue_running = false;
}

void protocol_msg_send(int protocol, int operation)
{
	key_t key = 12345;
	int msqid;
	int flag;

	char tmp[4] = {0};
	char value[4] = {0};
	char msg_chk[128] = {0};

	control_packet pkt = { 0 };
	pkt.msg_type = 1;

	signal(SIGINT, set_continue_running);

	flag = fcntl(0, F_GETFL, 0);
	fcntl(0, F_SETFL, flag | O_NONBLOCK);

	for(; continue_running;)
	{
		read(0, value, 3);
		memcpy(tmp, &value[2], 1);

		pkt.msg.protocol = atoi(value);
		pkt.msg.operation = atoi(tmp);

		if(!pkt.msg.protocol && !pkt.msg.operation)
			continue;

		if((msqid = msgget(key, IPC_CREAT | 0666)) == -1)
		{
			printf("msgget failed\n");
			exit(0);
		}

		printf("protocol = %d, oper = %d\n", pkt.msg.protocol, pkt.msg.operation);

		if(msgsnd(msqid, &pkt, sizeof(control_message), 0) == -1)
			printf("msgsnd control_message failed\n");

		if(msgctl(msqid, IPC_RMID, NULL) == -1)
		{
			printf("msgctl failed\n");
			exit(0);
		}

		memset(value, 0x0, 4);
		memset(tmp, 0x0, 4);
	}
}

// AT
// ATD010xxxxyyyy
// ATD010xxxxyyyy;
// The your phone will ringing
JNIEXPORT jstring JNICALL
Java_com_example_gsmdemo_nativeinterface_uart_UartSpring_phone_1call
(JNIEnv *env, jclass obj, jstring phone_num)
{
    const char *pn = (*env)->GetStringUTFChars(env, phone_num, NULL);

    int at_len = strlen(AT);
    int enter_len = strlen(ENTER);
    int pn_len = strlen(pn);

    jstring res;

    protocol_msg_send(1, 1);

    res = (*env)->NewStringUTF(env, "Success to Request Calling Phone\n");

    protocol_msg_send(1, 0);

    int fd;
    int baud;
    char dev_name[128];

    strcpy(dev_name, "/dev/ttyACM0");
    //baud = strtoul(argv[2], NULL, 10);
    baud = 115200;

    fd = open_serial(dev_name, baud, 10, 32);

    if(fd < 0)
    {
        res = (*env)->NewStringUTF(env, "Fail to Calling Phone\n");
        return res;
    }

    gsm_phone_call(fd, pn);

    sleep(5);

    close_serial(fd);

    res = (*env)->NewStringUTF(env, "Success to Calling Phone\n");

    return res;
}

// AT
// AT&F
// AT+CMGF=1
// AT+CSCS="GSM"
// AT+CMGS="010xxxxyyyy"
// Send msg what you want
// Send hex(1A)
// Then you can receive the msg ("Send msg what you want")
JNIEXPORT jstring JNICALL
Java_com_example_gsmdemo_nativeinterface_uart_UartSpring_phone_1msg_1send
(JNIEnv *env, jclass obj, jstring phone_num, jstring msg)
{
    const char *pn = (*env)->GetStringUTFChars(env, phone_num, NULL);
    const char *pmsg = (*env)->GetStringUTFChars(env, msg, NULL);
    int fd;
    int baud;
    char dev_name[128];

    jstring res;

    strcpy(dev_name, "/dev/ttyACM0");
    baud = 115200;

    fd = open_serial(dev_name, baud, 10, 32);

    if(fd < 0)
    {
        res = (*env)->NewStringUTF(env, "Fail to Calling Phone\n");
        return res;
    }

    gsm_msg_send(fd, pn, pmsg);

    sleep(5);

    close_serial(fd);

    res = (*env)->NewStringUTF(env, "Success to Send Message to Phone\n");

    return res;
}

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

JNIEXPORT void JNICALL
Java_com_example_gsmdemo_nativeinterface_uart_UartSpring_gsm_1init
(JNIEnv *env, jclass obj)
{
    char *portname = "/dev/ttyACM0";
    int wlen;

    serial_fd = open(portname, O_RDWR | O_NOCTTY | O_SYNC);

    if (serial_fd < 0) {
        printf("Error opening %s: %s\n", portname, strerror(errno));
        return -1;
    }

    set_interface_attribs(serial_fd, B9600);
}

JNIEXPORT jstring JNICALL
Java_com_example_gsmdemo_nativeinterface_uart_UartSpring_print
(JNIEnv *env, jclass obj)
{
    jstring result;
    key_t key = 12345;
    int msqid;
    struct message msg;

    //받아오는 쪽의 msqid얻어오고
    if((msqid = msgget(key, IPC_CREAT | 0666)) == -1)
    {
        printf("msgget failed\n");
        exit(0);
    }

    //메시지를 받는다.
    if(msgrcv(msqid, &msg, sizeof(struct uart_data), 0, 0) == -1)
    {
        printf("msgrcv failed\n");
        exit(0);
    }

    //printf("buf : %s\n", msg.data.buf);

    //이후 메시지 큐를 지운다.
    if(msgctl(msqid, IPC_RMID, NULL) == -1)
    {
        printf("msgctl failed\n");
        exit(0);
    }

    result = (*env)->NewStringUTF(env, msg.data.buf);
    return result;
}