#include <sys/types.h> 
#include <sys/stat.h> 
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

void run_daemon(void)
{
	key_t key = 12345;
	int msqid;
	pid_t pid;

	control_packet pkt = { 0 };
	//pkt.msg_type = 1;

	if((msqid = msgget(key, IPC_CREAT | 0666)) == -1)
	{
		printf("msgget failed\n");
		exit(0);
	}

	signal(SIGINT, set_continue_running);

	for(; continue_running;)
	{
		if(msgrcv(msqid, &pkt, sizeof(control_message), 1, 0) == -1)
			printf("msgrcv control_message failed\n");

		printf("pkt.protocol = %d\n", pkt.msg.protocol);

		switch(pkt.msg.protocol)
		{
			case 1:
				printf("Recv 1: Phone Call\n");
				if((pid = fork()) > 0)
					printf("Parent\n");
				else if(pid == 0)
					execl("./gsm_phone_call_test", "gsm_phone_call_test", "/dev/ttyACM0", 115200, 0);

				break;

			case 2:
				printf("Recv 2: Message Send\n");
				if((pid = fork()) > 0)
					printf("Parent\n");
				else if(pid == 0)
					execl("./gsm_msg_test", "gsm_msg_test", "/dev/ttyACM0", 115200, 0);
				break;

			default:
				printf("Recv wrong info\n");
				break;
		}
	}

	if(msgctl(msqid, IPC_RMID, NULL) == -1)
	{
		printf("msgctl failed\n");
		exit(0);
	}
}

int main(void)
{
	pid_t pid;
	int i; 

	pid = fork();

	if(pid == -1)
	{
		printf("fork\n");	
		return -1; 
	} 

	if(pid != 0)
		exit(EXIT_SUCCESS);
	
	if(setsid() == -1)
		return -1; 

	if(chdir("/") == -1)
	{
		printf("chdir()\n");
		return -1;
	}

	open("/dev/null", O_RDWR);
	dup(0);
	dup(0);

	run_daemon();

	return 0;

}
