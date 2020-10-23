#include <signal.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <sys/socket.h>

#include <pthread.h>

#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/msg.h>
#include <fcntl.h>

typedef struct sockaddr_in      si;
typedef struct sockaddr *       sp;

#define BUF_SIZE                64

int serv_sock;
si serv_addr;
si clnt_addr;
socklen_t addr_size;

char sock_buf[BUF_SIZE] = {0};

pthread_mutex_t mtx;

void err_handler(char *msg)
{
    fputs(msg, stderr);
    fputc('\n', stderr);
    exit(1);
}

void socket_config(int *sc, si *sa, int sa_size, char *port)
{
    serv_sock = socket(PF_INET, SOCK_STREAM, 0);

    if(serv_sock == -1)
        err_handler("socket() error");

    memset(&serv_addr, 0, sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port = htons(atoi(port));

    if(bind(serv_sock, (sp)&serv_addr, sizeof(serv_addr)) == -1)
        err_handler("bind() error");

    if(listen(serv_sock, 1) == -1)
        err_handler("listen() error");

    addr_size = sizeof(clnt_addr);

	pthread_mutex_init(&mtx, NULL);
}

void *network_recv(void *fd)
{
    int len;
    char msg[BUF_SIZE] = "Success!\n";

    len = strlen(msg);

    for(;;)
    {
        int flag;
        int clnt_sock = accept(serv_sock, (sp)&clnt_addr, &addr_size);
        printf("clnt_sock = %d\n", clnt_sock);

        if(clnt_sock == -1)
            continue;

        flag = fcntl(clnt_sock, F_GETFL, 0);
        fcntl(clnt_sock, F_SETFL, flag | O_NONBLOCK);

		// TODO: Need to management Client Sockets
		//       Currently Support Only One Client
        for(;;)
        {
            pthread_mutex_lock(&mtx);

            if((read(clnt_sock, (char *)&sock_buf, BUF_SIZE)) != 0)
                //write(clnt_sock, msg, len);

            pthread_mutex_unlock(&mtx);

            usleep(1000);
        }
    }
}

void do_not(int signo) {}

void *command_proc(void *fd)
{
#if 0
    int usb2can = *((int *)fd);
#endif

    char temp[BUF_SIZE] = {0};
    char data[BUF_SIZE] = {0};
    char phone_num[BUF_SIZE] = {0};
    char phone_msg[BUF_SIZE] = {0};

    pid_t call_pid;
    pid_t msg_pid;

	int i, j;
	int protocol;
    int decision;

    //union sigval sv;
	signal(SIGINT, do_not);

	for(;;)
    {
        pthread_mutex_lock(&mtx);

        memcpy(temp, sock_buf, 1);
        memcpy(data, &sock_buf[2], 1);

		if(strlen(sock_buf))
	        printf("sock_buf = %s\n", sock_buf);

        switch(atoi(temp))
        {
			case 1:
                printf("(1) Phone Call\n");
                decision = atoi(data);

                if(decision == 1)
                {
                    call_pid = vfork();
                    if(call_pid > 0)
                        printf("Phone Call Parent\n");
                    else if(call_pid == 0)
                    {
                        printf("Start Phone Call Process\n");

						for (i = 0; sock_buf[4 + i] != (' ' || '\0'); i++)
							;

						strncpy(phone_num, &sock_buf[4], i);
						printf("phone_num = %s\n", phone_num);

                        execlp("gsm_call", "gsm_call", phone_num, (char *)0);
                    }
                }
                else if(decision == 0)
                {
                    // kill phone call process
                    printf("Kill Phone Call Process\n");
                    kill(call_pid, SIGINT);
                    call_pid = 0;
                }

                break;

			case 2:
				printf("(2) Phone SMS\n");
                decision = atoi(data);

                if(decision == 1)
                {
                    msg_pid = vfork();
                    if(msg_pid > 0)
                        printf("Phone SMS Parent\n");
                    else if(msg_pid == 0)
                    {
                        printf("Start Phone SMS Process\n");

						for (i = 0; sock_buf[4 + i] != ' '; i++)
							;

						strncpy(phone_num, &sock_buf[4], i);
						printf("phone_num = %s\n", phone_num);

						strcpy(phone_msg, &sock_buf[4 + i + 1]);
						printf("phone_msg = %s\n", phone_msg);

						printf("%c test", sock_buf[i]);

                        execlp("gsm_send", "gsm_send", phone_num, phone_msg, (char *)0);
                    }
                }
                else if(decision == 0)
                {
                    // kill phone call process
                    printf("Kill Phone SMS Process\n");
                    kill(msg_pid, SIGINT);
                    msg_pid = 0;
                }

                break;

			case 3:
				printf("(3) Kill Daemon\n");
				kill(msg_pid, SIGINT);
				kill(call_pid, SIGINT);
				//close(clnt_sock);
				close(serv_sock);
				exit(0);
				break;
        }

        memset(sock_buf, 0x0, BUF_SIZE);
        memset(data, 0x0, BUF_SIZE);
        memset(phone_num, 0x0, BUF_SIZE);

        pthread_mutex_unlock(&mtx);

        usleep(5000);
    }
}

int main(int argc, char **argv)
{
    int fd;

    pthread_t p_thread[2];
    int thread_id, status;
    struct sigaction sigact;

    char tx_buf[BUF_SIZE] = "Success\n";
    int tx_len = strlen(tx_buf);

    socklen_t addr_size;

    if(argc != 2)
    {
        printf("Usage: %s <port>\n", argv[0]);
        exit(1);
    }

    socket_config(&serv_sock, &serv_addr, sizeof(serv_addr), argv[1]);

	thread_id = pthread_create(&p_thread[0], NULL, network_recv, NULL);
    if(thread_id < 0)
    {
        perror("network recv thread create error: ");
        exit(0);
    }

    thread_id = pthread_create(&p_thread[1], NULL, command_proc, (void *)&fd);
    if(thread_id < 0)
    {
        perror("command proc thread create error: ");
        exit(0);
    }

	pthread_join(p_thread[0], (void **)&status);
    pthread_join(p_thread[1], (void **)&status);

	return 0;
}
