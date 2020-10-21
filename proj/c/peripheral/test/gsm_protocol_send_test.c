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

void protocol_msg_send(void)
{
	key_t key = 12345;
	int msqid;
	pid_t pid;
	char value = 0;

	control_packet pkt = { 0 };
	pkt.msg_type = 1;

	if((msqid = msgget(key, IPC_CREAT | 0666)) == -1)
	{
		printf("msgget failed\n");
		exit(0);
	}

	signal(SIGINT, set_continue_running);

	for(; continue_running;)
	{
		pkt.msg.protocol = getchar();
		printf("protocol = %d\n", pkt.msg.protocol);

		if(msgsnd(msqid, &pkt, sizeof(control_message), 0) == -1)
			printf("msgsnd control_message failed\n");
	}

	if(msgctl(msqid, IPC_RMID, NULL) == -1)
	{
		printf("msgctl failed\n");
		exit(0);
	}
}

int main(void)
{
	protocol_msg_send();

	return 0;

}
