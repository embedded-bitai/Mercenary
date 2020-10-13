#include "mq_recv.h"

int main(void)
{
	int i;
	key_t key = 12345;
    int msqid;
    struct message msg;
	lidar_sample_count lsc;

    //받아오는 쪽의 msqid얻어오고
    if((msqid = msgget(key, IPC_CREAT | 0666)) == -1)
    {
        printf("msgget failed\n");
        exit(0);
    }

	for(;;)
	{
		if(msgrcv(msqid, &lsc, sizeof(lidar_sample_count), 1, 0) == -1)
		{
			printf("msgrcv count failed\n");
		}

		printf("count = %d\n", lsc.msg_count);

		for (i = 0; i < lsc.msg_count; i++)
		{
    		//메시지를 받는다.
    		if(msgrcv(msqid, &msg, sizeof(struct _lidar_info), 1, 0) == -1)
    		{
    		    printf("msgrcv failed\n");
    		}

		    printf("dist: %f, angle: %f\n", msg.info.distance, msg.info.angle);
		}
	}

    //이후 메시지 큐를 지운다.
    if(msgctl(msqid, IPC_RMID, NULL) == -1)
    {
        printf("msgctl failed\n");
        exit(0);
    }

	return 0;
}
