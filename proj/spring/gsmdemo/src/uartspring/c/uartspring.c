#include <jni.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/types.h>
#include <sys/msg.h>
#include <stdlib.h>
#include <string.h>

#include <errno.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <pthread.h>

struct uart_data
{
    char buf[64];
};

struct message
{
    long msg_type;
    struct uart_data data;
};

int serial_fd;
char gsm_command_buf[128];

char AT[128] = {'A', 'T'};
char ENTER[128] = {'\r', '\n'};
char return_buf[128];
char response_buf[256];
char suffix[128];

int current_location;

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

void gsm_msg_send(int fd, const char *phone_num, const char *msg)
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
    printf("1A(hex)\n");
}

void gsm_phone_call(int fd, const char *phone_num)
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

#if 0
    // Set AT Command on buffer
    memmove(gsm_command_buf, AT, at_len);
    current_location += at_len;

    // Set Enter Key on buffer
    memmove(&gsm_command_buf[current_location], ENTER, enter_len);
    current_location += enter_len;

    // Send AT Command to Device
    write(serial_fd, gsm_command_buf, strlen(gsm_command_buf));
    read(serial_fd, response_buf, sizeof(response_buf));

    // Record Send Command
    memmove(return_buf, gsm_command_buf, strlen(gsm_command_buf));
    current_location += strlen(gsm_command_buf);

    // Record Device Response
    memmove(&return_buf[current_location], response_buf, strlen(response_buf));
    current_location += strlen(response_buf);

    // Set ATD010xxxxyyyy
    memmove(&gsm_command_buf[2], 'D', 1);
    memmove(&gsm_command_buf[3], pn, pn_len);
    memmove(&gsm_command_buf[3 + pn_len], ENTER, enter_len);

    // Send ATD010xxxxyyyy
    write(serial_fd, gsm_command_buf, strlen(gsm_command_buf));
    read(serial_fd, response_buf, sizeof(response_buf));

    // Record ATD010xxxxyyyy Command
    memmove(return_buf, gsm_command_buf, strlen(gsm_command_buf));
    current_location += strlen(gsm_command_buf);

    // Record Device Response
    memmove(&return_buf[current_location], response_buf, strlen(response_buf));
    current_location += strlen(response_buf);
    memset(response_buf, 0x0, 32);

    // Set ATD010xxxxyyyy;
    memmove(&gsm_command_buf[strlen(gsm_command_buf)], ';', 1);
    memmove(&gsm_command_buf[strlen(gsm_command_buf)], ENTER, enter_len);

    // Send ATD010xxxxyyyy;
    write(serial_fd, gsm_command_buf, strlen(gsm_command_buf));
    read(serial_fd, response_buf, sizeof(response_buf));

    //Record ATD010xxxxyyyy; Command
    memmove(return_buf, gsm_command_buf, strlen(gsm_command_buf));
    current_location += strlen(gsm_command_buf);

    // Record Device Response
    memmove(&return_buf[current_location], response_buf, sizeof(response_buf));
    current_location += strlen(response_buf);

    res = (*env)->NewStringUTF(env, return_buf);
#endif

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