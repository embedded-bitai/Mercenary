#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/msg.h>
#include <stdbool.h>
#include <signal.h>

typedef struct _control_message
{
	int protocol;
	int operation;
	char phone_num[64];
	char phone_msg[128];
} control_message;

typedef struct _control_packet
{
	long msg_type;
	control_message msg;
} control_packet;

bool continue_running = true;

void do_not(int signo)
{
}

int main(void)
{
	int i;
	key_t key = 12345;
    int msqid;
	int protocol, operation;
    struct _control_packet pkt;
	pid_t call_pid, msg_pid;
	char phone_num[64] = {0};
	char phone_msg[128] = {0};

	signal(SIGINT, do_not);

	for(; continue_running;)
	{
    	//받아오는 쪽의 msqid얻어오고
    	if((msqid = msgget(key, IPC_CREAT | 0666)) == -1)
    	{
    	    printf("msgget failed\n");
    	    exit(0);
    	}

		if(msgrcv(msqid, &pkt, sizeof(struct _control_message), 1, 0) == -1)
		{
			//printf("msgrcv count failed\n");
		}

		protocol = pkt.msg.protocol;
		operation = pkt.msg.operation;
		strcpy(phone_num, pkt.msg.phone_num);
		strcpy(phone_msg, pkt.msg.phone_msg);

		switch(protocol)
		{
			case 1:
				printf("(1) Phone Call\n");

				if(operation == 1)
				{
					call_pid = vfork();

					if(call_pid > 0)
						printf("Phone Call Parent\n");
					else if(call_pid == 0)
					{
						printf("Start Phone Call\n");
						//execlp("gsm_phone_call_test", "gsm_phone_call_test", phone_num, (char *)0);
						execlp("gsm_call", "gsm_call", phone_num, (char *)0);
					}
				}
				else if(operation == 0)
				{
					printf("Device Already Connected\n");
					kill(call_pid, SIGKILL);
					call_pid = 0;
				}

				break;
			case 2:
				printf("(2) Phone SMS Send\n");

				if(operation == 1)
				{
					msg_pid = vfork();

					if(msg_pid > 0)
						printf("Phone Message Send Parent\n");
					else if(msg_pid == 0)
					{
						printf("Start Send Phone Message\n");
						//execlp("gsm_msg_test", "gsm_msg_test", phone_num, msg, (char *)0);
						execlp("gsm_send", "gsm_send", phone_num, phone_msg, (char *)0);
						//execlp("ls", "ls", (char *)0);
					}
				}
				else if(operation == 0)
				{
					printf("Kill Phone Message Send Process\n");
					kill(msg_pid, SIGKILL);
					msg_pid = 0;
				}

				break;
			case 3:
				printf("(3) Exit Process\n");
				continue_running = false;
				break;
			default:
				printf("Wrong Info\n");
				break;
		}

		protocol = 0;
		operation = 0;
		memset(phone_num, 0x0, 32);
		memset(phone_msg, 0x0, 128);

    	//이후 메시지 큐를 지운다.
    	if(msgctl(msqid, IPC_RMID, NULL) == -1)
    	{
    	    //printf("msgctl failed\n");
    	    //exit(0);
    	}

		memset(&pkt.msg, 0x0, 8);
	}

	return 0;
}
