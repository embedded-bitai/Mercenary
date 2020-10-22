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
	char phone_num[64];
	char phone_msg[128];
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

void protocol_msg_send(char *phone_num, char *phone_msg)
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
		strcpy(pkt.msg.phone_num, phone_num);
		strcpy(pkt.msg.phone_msg, phone_msg);

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

int main(void)
{
	protocol_msg_send("01029807183", "BitAI: Call to me");

	return 0;

}
