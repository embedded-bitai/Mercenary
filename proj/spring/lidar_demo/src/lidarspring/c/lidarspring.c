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
#include <signal.h>

typedef struct _lidar_sample_count {
    long msg_type;
    int msg_count;
} __attribute__((packed)) lidar_sample_count;

typedef struct _lidar_info {
    float   angle;
    float   distance;
} __attribute__((packed)) lidar_info;

typedef struct _message
{
    long msg_type;
    lidar_info info;
} message;

pid_t lidar_pid = 0;

message msg = { 0 };
lidar_sample_count lsc;

key_t key = 12345;
int msqid;

jfloat *float_dist_buf;
jfloat *float_angle_buf;

void make_lidar_task(void)
{
    // TODO: Shared Memroy Free
    //int shmid;
    //shm_t *shared_mem;

    //shmid = shmget(333, sizeof(shm_t), IPC_CREAT | 0777);
    //shared_mem = (shm_t *)shmat(shmid, (char *)0, 0);
    //shared_mem->pid = getpid();

    lsc.msg_type = 1;
    msg.msg_type = 1;

    float_dist_buf = (jfloat *)malloc(sizeof(jfloat) * 1421);
    float_angle_buf = (jfloat *)malloc(sizeof(jfloat) * 1421);

    if (float_dist_buf == NULL && float_angle_buf == NULL)
    {
        printf("Fail Allocate Memory\n");
        return;
    }

    printf("Pass Allocate\n");

    //받아오는 쪽의 msqid얻어오고
    if((msqid = msgget(key, IPC_CREAT | 0666)) == -1)
    {
        printf("msgget failed\n");
        exit(0);
    }

    printf("Pass MQ Creation\n");

#if 0
    lidar_pid = vfork();

    if(lidar_pid > 0)
        printf("Lidar Parent\n");
    else if(lidar_pid == 0)
    {
        printf("Start Lidar Process\n");
        execl("usr/bin/rplidar_a3", "usr/bin/rplidar_a3", (char *)0);
    }
#endif
}

JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_lidar_LidarSpring_print
(JNIEnv *env, jobject obj, jfloatArray dist, jfloatArray angle)
{
    int i;

    for (i = 0; i < 1421; i++)
    {
        //메시지를 받는다.
        if(msgrcv(msqid, &msg, sizeof(struct _lidar_info), 1, 0) == -1)
        {
            printf("msgrcv failed\n");
        }

        // Set JNI Float Function
        float_dist_buf[i] = msg.info.distance;
        float_angle_buf[i] = msg.info.angle;
        //printf("dist: %f, angle: %f\n", msg.info.distance, msg.info.angle);
    }

    //(*env)->SetIntArrayRegion(env, dist, 0, count, (const jfloat *)float_dist_buf);
    //(*env)->SetIntArrayRegion(env, angle, 0, count, (const jfloat *)float_angle_buf);
    (*env)->SetFloatArrayRegion(env, dist, 0, 1421, (const jfloat *)float_dist_buf);
    (*env)->SetFloatArrayRegion(env, angle, 0, 1421, (const jfloat *)float_angle_buf);
}

JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_lidar_LidarSpring_lidar_1start
//Java_com_example_lidar_demo_nativeinterface_lidar_LidarSpring_lidar_start
(JNIEnv *env, jobject obj)
{
    // parent 는 child(lidar)의 pid 값을 가지고 있음
    // child 는 lidar 동작
    //if (lidar_pid)
        make_lidar_task();
    //else
    //    return;

    // Need to make
}

JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_lidar_LidarSpring_lidar_1stop
//Java_com_example_lidar_demo_nativeinterface_lidar_LidarSpring_lidar_stop
(JNIEnv *env, jobject obj)
{
    //kill(lidar_pid, SIGINT);

    free(float_dist_buf);
    free(float_angle_buf);

    //이후 메시지 큐를 지운다.
    if(msgctl(msqid, IPC_RMID, NULL) == -1)
    {
        printf("msgctl failed\n");
        exit(0);
    }
}