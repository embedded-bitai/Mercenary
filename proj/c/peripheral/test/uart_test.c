#include "uart.h"

int main(void)
{
    char *portname = "/dev/ttyACM0";
    int fd;
    int wlen;

    fd = open(portname, O_RDWR | O_NOCTTY | O_SYNC);
    if (fd < 0) {
        printf("Error opening %s: %s\n", portname, strerror(errno));
        return -1;
    }
    /*baudrate 115200, 8 bits, no parity, 1 stop bit */
    //set_interface_attribs(fd, B115200);
    set_interface_attribs(fd, B9600);
    //set_mincount(fd, 0);                /* set to pure timed read */

    /* simple output */
    wlen = write(fd, "Hello!\n", 7);
    if (wlen != 7) {
        printf("Error from write: %d, %d\n", wlen, errno);
    }
    tcdrain(fd);    /* delay for output */

    /* simple noncanonical input */
    do {
        unsigned char buf[80];
        int rdlen;

        rdlen = read(fd, buf, sizeof(buf) - 1);
        if (rdlen > 0) {
#ifdef DISPLAY_STRING
            buf[rdlen] = 0;
            printf("Read %d: %s\n", rdlen, buf);
#else /* display hex */
            unsigned char   *p;
            printf("Read %d:", rdlen);
            for (p = buf; rdlen-- > 0; p++)
                printf(" 0x%x", *p);
            printf("\n");
#endif
        } else if (rdlen < 0) {
            printf("Error from read: %d: %s\n", rdlen, strerror(errno));
        } else {  /* rdlen == 0 */
            printf("Timeout from read\n");
        }               
        /* repeat read to get full message */
    } while (1);
}
