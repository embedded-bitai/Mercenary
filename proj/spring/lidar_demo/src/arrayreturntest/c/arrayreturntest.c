#include <jni.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include <unistd.h>

typedef struct _User
{
    long iSerial;
    char caName[32];
    int iAge;
} User;

typedef struct _test_struct
{
    long distance;
    long angle;
} test_struct, *ptest_struct;

typedef struct _JNI_POSREC{
    jclass cls;
    jmethodID ctorID;
    jfieldID distanceID;
    jfieldID angleID;
} JNI_POSREC;

JNI_POSREC *jniPosRec = NULL;

jfloat *float_dist_buf;
jfloat *float_angle_buf;

float range;

int count = 0;

JNIEXPORT jint JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_setIntArr
(JNIEnv *env, jclass cls, jintArray ji_array, jint value)
{
    int i, len;
    jint *int_buf;

    len = (*env)->GetArrayLength(env, ji_array);
    int_buf = (jint *)malloc(sizeof(jint) * len);

    if (int_buf == NULL)
    {
        printf("Fail Allocate Memory\n");
        return 0;
    }

    for (i = 0; i < len; i++)
    {
        int_buf[i] = value;
    }

    (*env)->SetIntArrayRegion(env, ji_array, 0, len, (const jint *)int_buf);

    free(int_buf);

    return len;
}

JNIEXPORT jintArray JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_makeIntArr
(JNIEnv *env, jclass cls, jint arr_len)
{
    jintArray ji_array = NULL;
    ji_array = (*env)->NewIntArray(env, arr_len);

    if (ji_array != NULL)
    {
        printf("new int array: %d\n", arr_len);
        return ji_array;
    }
    else
    {
        printf("fail make new int array:\n");
        return NULL;
    }
}

JNIEXPORT jint JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_add
(JNIEnv * _env, jclass _clazz, jobject _object)
{
    jclass clazz;
    clazz = (*_env)->GetObjectClass(_env, _object);

    jfieldID fid;
    jstring jstr;

    User user;
    fid = (*_env)->GetFieldID(_env, clazz, "serial", "J");
    user.iSerial = (*_env)->GetLongField(_env, _object, fid);
    // L이 아니라 J임에 주의하자

    fid = (*_env)->GetFieldID(_env, clazz, "name", "Ljava/lang/String;");
    jstr = (jstring)(*_env)->GetObjectField(_env, _object, fid);
    const char * pcName = (*_env)->GetStringUTFChars(_env, jstr, NULL);
    strcpy(user.caName, pcName);
    (*_env)->ReleaseStringUTFChars(_env, jstr, pcName);
    // ReleaseStringUTFChars 반드시 해준다.

    fid = (*_env)->GetFieldID(_env, clazz, "age", "I");
    user.iAge = (*_env)->GetIntField(_env, _object, fid);

    return 1;
}

#if 0
JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_readyToGetStruct
(JNIEnv *env, jclass _cls, jlongArray dist1, jlongArray dist2, jlongArray angle1, jlongArray angle2, jint len)
{
    jlong i;
    jlong *long_dist_buf1;
    jlong *long_angle_buf1;
    jlong *long_dist_buf2;
    jlong *long_angle_buf2;
    jlong range = (jlong)(ceil(360000 / 8192));

    long_dist_buf1 = (jlong *)malloc(sizeof(jlong) * len);
    long_angle_buf1 = (jlong *)malloc(sizeof(jlong) * len);
    long_dist_buf2 = (jlong *)malloc(sizeof(jlong) * len);
    long_angle_buf2 = (jlong *)malloc(sizeof(jlong) * len);

    if (long_dist_buf1 == NULL && long_angle_buf1 == NULL && long_dist_buf2 == NULL && long_angle_buf2 == NULL)
    {
        printf("Fail Allocate Memory\n");
    }

    for (i = 0; i < len; i++)
    {
        long_dist_buf1[i] = (jlong)(rand() % 40 + 1);
        // Need to scaling: 1 / 1000
        long_angle_buf1[i] = (jlong)(range * i);
    }

    for (i = 0; i < len; i++)
    {
        long_dist_buf2[i] = (jlong)(rand() % 40 + 1);
        // Need to scaling: 1 / 1000
        long_angle_buf2[i] = (jlong)(range * i);
    }

    (*env)->SetIntArrayRegion(env, dist1, 0, len, (const jlong *)long_dist_buf1);
    (*env)->SetIntArrayRegion(env, angle1, 0, len, (const jlong *)long_angle_buf1);
    (*env)->SetIntArrayRegion(env, dist2, 0, len, (const jlong *)long_dist_buf2);
    (*env)->SetIntArrayRegion(env, angle2, 0, len, (const jlong *)long_angle_buf2);

    sleep(1);
    free(long_dist_buf1);
    free(long_angle_buf1);
    free(long_dist_buf2);
    free(long_angle_buf2);
}

JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_getStruct
(JNIEnv *env, jclass cls, jlongArray dist, jlongArray angle)
{

}
#endif

#if 0
bool make_struct(void *array, int len)
{
    test_struct *ts = (test_struct *)malloc(sizeof(test_struct));

    ts->distance = (long *)malloc(sizeof(long) * len);
    ts->angle = (long *)malloc(sizeof(long) * len);

    *((test_struct **) array) = ts;

    return true;
}

void load_jni_pos_rec(JNIEnv *env)
{
    if (jniPosRec != NULL)
        return;

    jniPosRec = (JNI_POSREC *)malloc(sizeof(JNI_POSREC));
    jniPosRec->cls = (*env)->FindClass(env, "TestStruct");
    jniPosRec->ctorID = (*env)->GetMethodID(env, jniPosRec->cls, "<init>", "()V");
    jniPosRec->distanceID = (*env)->GetFieldID(env, jniPosRec->cls, "distance", "J");
    jniPosRec->angleID = (*env)->GetFieldID(env, jniPosRec->cls, "angle", "J");
}

JNIEXPORT jobject JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_testStruct
(JNIEnv *env, jclass _cls, jint len)
{
    load_jni_pos_rec(env);

    test_struct *ts;

    if (!make_struct((void *)&ts, len))
        return NULL;

    jobject jArray = (*env)->NewObject(env, jniPosRec->cls, jniPosRec->ctorID);

    /* Structure Array Set */
    ji_dist_array = (*env)->NewIntArray(env, len);
    (*env)->
    /* SAS Fin */

    (*env)->SetLongArrayRegion(env, jArray->distanceID, 0, len, ts->distance);
    (*env)->SetLongArrayRegion(env, jArray->angleID, 0, len, ts->angle);

    return jArray;
}
#endif

#if 0
bool make_struct(void *array, int len)
{
    int i;
    long range = ceil(360000 / 8192);
    //test_struct *ts = (test_struct *)malloc(sizeof(test_struct) * len);
    test_struct *ts = new test_struct[len];

    for (i = 0; i < len; i++)
    {
        ts[i].distance = rand() % 40 + 1;
        // Need to scaling: 1 / 1000
        ts[i].angle = range * i;
    }

    *((test_struct **) array) = ts;

    return true;
}

void load_jni_pos_rec(JNIEnv *env)
{
    if (jniPosRec != NULL)
        return;

    jniPosRec = (JNI_POSREC *)malloc(sizeof(JNI_POSREC));
    jniPosRec->cls = (*env)->FindClass(env, "TestStruct");
    jniPosRec->ctorID = (*env)->GetMethodID(env, jniPosRec->cls, "<init>", "()V");
    jniPosRec->distanceID = (*env)->GetFieldID(env, jniPosRec->cls, "distance", "J");
    jniPosRec->angleID = (*env)->GetFieldID(env, jniPosRec->cls, "angle", "J");
}

void fill_java_rec_values(JNIEnv *env, jobject jRec, test_struct ts)
{
    (*env)->SetLongField(env, jRec, jniPosRec->distanceID, ts.distance);
    (*env)->SetLongField(env, jRec, jniPosRec->angleID, ts.angle);
}

JNIEXPORT jobjectArray JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_testStruct
(JNIEnv *env, jclass cls, jint len)
{
    load_jni_pos_rec(env);

    test_struct *ts;

    if (!make_struct((void *)&ts, len))
        return NULL;

    jobject jArray = (*env)->NewObjectArray(env, len, jniPosRec->cls, NULL);

    for (int i = 0; i < len; i++)
    {
        jobject jRec = (*env)->NewObject(env, jniPosRec->cls, jniPosRec->ctorID);

        fill_java_rec_values(env, jRec, ts[i]);
        (*env)->SetObjectArrayElement(env, jArray, i, jRec);
    }

    return jArray;
}
#endif

JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_readyToGetIntArray
(JNIEnv *env, jclass _cls, jintArray dist, jintArray angle, jint len)
{
    jint i;
    jint *int_dist_buf;
    jint *int_angle_buf;

    jint range = (jlong)(ceil(360000.0 / 8192.0));

    int_dist_buf = (jint *)malloc(sizeof(jint) * len);
    int_angle_buf = (jint *)malloc(sizeof(jint) * len);

    if (int_dist_buf == NULL && int_angle_buf == NULL)
    {
        printf("Fail Allocate Memory\n");
        return;
    }

    for (i = 0; i < len; i++)
    {
        int_dist_buf[i] = (jint)(rand() % 40 + 1);
        // Need to scaling: 1 / 1000
        int_angle_buf[i] = (jint)(range * i);
    }

    (*env)->SetIntArrayRegion(env, dist, 0, len, (const jint *)int_dist_buf);
    (*env)->SetIntArrayRegion(env, angle, 0, len, (const jint *)int_angle_buf);

    free(int_dist_buf);
    free(int_angle_buf);
}

JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_readyToGetFloatArray
(JNIEnv *env, jclass cls)
{
    range = 360.0f / 1750.0f;

    float_dist_buf = (jfloat *)malloc(sizeof(jfloat) * 1024);
    float_angle_buf = (jfloat *)malloc(sizeof(jfloat) * 1024);
}

JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_getFloatArray
(JNIEnv *env, jclass _cls, jfloatArray dist, jfloatArray angle)
{
    int i;

    for (i = 0; i < 1024; i++)
    {
        float_dist_buf[i] = (jfloat)(rand() % 10 + 20);

        if (count >= 1750)
            count = 0;

        float_angle_buf[i] = (jfloat)(range * count);

        count++;
    }

    (*env)->SetFloatArrayRegion(env, dist, 0, 1024, (const jfloat *)float_dist_buf);
    (*env)->SetFloatArrayRegion(env, angle, 0, 1024, (const jfloat *)float_angle_buf);
}