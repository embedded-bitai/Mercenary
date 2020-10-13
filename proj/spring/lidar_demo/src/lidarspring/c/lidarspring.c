#include <jni.h>
#include <stdio.h>

#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/types.h>
#include <sys/msg.h>
#include <stdlib.h>
#include <string.h>

#include <sys/stat.h>
#include <fcntl.h>
#include <linux/fs.h>
#include <unistd.h>

typedef struct _lidar_info {
    float   angle;
    float   distance;
} __attribute__((packed)) lidar_info;

struct message
{
    long msg_type;
    lidar_info info;
};

pid_t lidar_pid = 0;

void make_lidar_task(void)
{
    // TODO: Shared Memroy Free
    int shmid;
    shm_t *shared_mem;

    shmid = shmget(333, sizeof(shm_t), IPC_CREAT | 0777);
    shared_mem = (shm_t *)shmat(shmid, (char *)0, 0);
    shared_mem->pid = getpid();

    lidar_pid = vfork();

    if(lidar_pid > 0)
        printf("Lidar Parent\n");
    else if(lidar_pid == 0)
    {
        printf("Start Lidar Process\n");
        execl("usr/bin/rplidar_a3", "rplidar_a3", (char *)0);
    }
}

JNIEXPORT jstring JNICALL
Java_com_example_lidar_demo_nativeinterface_lidar_LidarSpring_print(JNIEnv *env, jobject obj)
{
    int i;
    key_t key = 12345;
    int msqid;
    struct message msg;

    //받아오는 쪽의 msqid얻어오고
    if((msqid = msgget(key, IPC_CREAT | 0666)) == -1)
    {
        printf("msgget failed\n");
        exit(0);
    }

    for(;;)
    {
        //메시지를 받는다.
        if(msgrcv(msqid, &msg, sizeof(struct _lidar_info), 1, 0) == -1)
        {
            printf("msgrcv failed\n");
        }

        printf("dist: %f, angle: %f\n", msg.info.distance, msg.info.angle);
    }

    //이후 메시지 큐를 지운다.
    if(msgctl(msqid, IPC_RMID, NULL) == -1)
    {
        printf("msgctl failed\n");
        exit(0);
    }
}

JNIEXPORT void JNICALL
Java_com_example_lidar_demo_nativeinterface_lidar_LidarSpring_lidar_start(JNIEnv *env, jobject obj)
{
    // parent 는 child(lidar)의 pid 값을 가지고 있음
    // child 는 lidar 동작
    if (lidar_pid)
        make_lidar_task();
    else
        return;

    // Need to make
}

JNIEXPORT void JNICALL
Java_com_example_lidar_demo_nativeinterface_lidar_LidarSpring_lidar_stop(JNIEnv *env, jobject obj)
{
    kill(lidar_pid, SIGINT);
}