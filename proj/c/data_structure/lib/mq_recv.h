#ifndef __MQ_RECV_H__
#define __MQ_RECV_H__

#include <stdio.h>

#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/types.h>
#include <sys/msg.h>
#include <stdlib.h>
#include <string.h>

/* For Message Queue */
typedef struct _lidar_info {
    float   angle; // check_bit:1;angle_q6:15;
    float   distance;
} __attribute__((packed)) lidar_info;

struct message
{
    long msg_type;
    lidar_info info;
};

#endif
