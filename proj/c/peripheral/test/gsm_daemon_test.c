#include <sys/types.h> 
#include <pthread.h>
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

pthread_mutex_t mtx;

int protocol;
int operation;

void *mq_recv(void *none)
{
	key_t key = 12345;
	int msqid;

	control_packet pkt = { 0 };
	//pkt.msg_type = 1;

	for(;;)
	{
		pthread_mutex_lock(&mtx);

		if((msqid = msgget(key, IPC_CREAT | 0666)) == -1)
		{
			printf("msgget failed\n");
			exit(0);
		}

		if(msgrcv(msqid, &pkt, sizeof(control_message), 1, 0) == -1)
		{
			printf("What\n");
		}

		//printf("pkt.protocol = %d, oper = %d\n", pkt.msg.protocol, pkt.msg.operation);

		if(pkt.msg.protocol == 1 || pkt.msg.protocol == 2)
		{
			protocol = pkt.msg.protocol;
			operation = pkt.msg.operation;
		}

		if(msgctl(msqid, IPC_RMID, NULL) == -1)
		{
			//printf("msgctl failed\n");
		}

		pthread_mutex_lock(&mtx);

		usleep(1000);
	}
}

void *cmd_proc(void *none)
{
	pid_t call_pid;
	pid_t msg_pid;

	for(;;)
	{
		pthread_mutex_lock(&mtx);
	
		switch(protocol)
		{
			case 1:
				printf("Recv 1: Phone Call\n");

				if(operation == 1)
				{
					call_pid = vfork();

					if(call_pid > 0)
						printf("Phone Call Parent\n");
					else if(call_pid == 0)
					{
						printf("Start Phone Call\n");
						execl("/home/oem/proj/bitai/team_proj/Mercenary/proj/c/peripheral/test/gsm_phone_call_test", "gsm_phone_call_test", "/dev/ttyACM0", 115200, (char *)0);
					}
				}
				else if(operation == 0)
				{
					printf("Device Already Connected\n");
					kill(call_pid, SIGINT);
					call_pid = 0;
				}

				break;

			case 2:
				printf("Recv 2: Message Send\n");

				if(operation == 1)
				{
					msg_pid = vfork();

					if(msg_pid > 0)
						printf("Phone Message Send Parent\n");
					else if(msg_pid == 0)
					{
						printf("Start Send Phone Message\n");
						execl("./gsm_msg_test", "gsm_msg_test", "/dev/ttyACM0", 115200, (char *)0);
					}
				}
				else if(operation == 0)
				{
					printf("Kill Phone Message Send Process\n");
					kill(msg_pid, SIGINT);
					msg_pid = 0;
				}

				break;

			default:
				printf("Recv wrong info\n");
				break;
		}

		pthread_mutex_lock(&mtx);

		usleep(1000);
	}
}

int main(void)
{
	int thread_id, status;
	pthread_t mq_recv_thread;
	pthread_t command_thread;

	pthread_mutex_init(&mtx, NULL);

	thread_id = pthread_create(&mq_recv_thread, NULL, mq_recv, NULL);
	if(thread_id < 0)
	{
		printf("pthread_create Error\n");
		exit(0);
	}

	thread_id = pthread_create(&command_thread, NULL, cmd_proc, NULL);
	if(thread_id < 0)
	{
		printf("pthread_create Error\n");
		exit(0);
	}

	pthread_join(mq_recv_thread, (void **)&status);
	pthread_join(command_thread, (void **)&status);

	return 0;

}
