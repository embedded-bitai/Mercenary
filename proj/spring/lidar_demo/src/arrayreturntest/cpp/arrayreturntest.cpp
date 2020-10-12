#ifdef __cplusplus
extern "C"
{
#endif

#include <jni.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

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

JNIEXPORT jint JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_setIntArr
(JNIEnv *env, jclass cls, jintArray ji_array, jint value)
{
    int i, len;
    jint *int_buf;

    len = env->GetArrayLength(ji_array);
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

    env->SetIntArrayRegion(ji_array, 0, len, (const jint *)int_buf);

    free(int_buf);

    return len;
}

JNIEXPORT jintArray JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_makeIntArr
(JNIEnv *env, jclass cls, jint arr_len)
{
    jintArray ji_array = NULL;
    ji_array = env->NewIntArray(arr_len);

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
    clazz = _env->GetObjectClass(_object);

    jfieldID fid;
    jstring jstr;

    User user;
    fid = _env->GetFieldID(clazz, "serial", "J");
    user.iSerial = _env->GetLongField(_object, fid);
    // L이 아니라 J임에 주의하자

    fid = _env->GetFieldID(clazz, "name", "Ljava/lang/String;");
    jstr = (jstring)_env->GetObjectField(_object, fid);
    const char * pcName = _env->GetStringUTFChars(jstr, NULL);
    strcpy(user.caName, pcName);
    _env->ReleaseStringUTFChars(jstr, pcName);
    // ReleaseStringUTFChars 반드시 해준다.

    fid = _env->GetFieldID(clazz, "age", "I");
    user.iAge = _env->GetIntField(_object, fid);

    return 1;
}

JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_readyToGetStruct
(JNIEnv *env, jclass _cls, jlongArray dist, jlongArray angle, jint len)
{
}

JNIEXPORT void JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_getStruct
(JNIEnv *env, jclass cls, jlongArray dist, jlongArray angle)
{
#if 0
    test_struct ts;
    jfieldID id;

    jclass jcls = (*env)->GetObjectClass(env, obj);

    fid = (*env)->GetFieldID(env, jcls, "distance", "J");
#endif
}

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
    jniPosRec->cls = env->FindClass("TestStruct");
    jniPosRec->ctorID = env->GetMethodID(jniPosRec->cls, "<init>", "()V");
    jniPosRec->distanceID = env->GetFieldID(jniPosRec->cls, "distance", "J");
    jniPosRec->angleID = env->GetFieldID(jniPosRec->cls, "angle", "J");
}

void fill_java_rec_values(JNIEnv *env, jobject jRec, test_struct ts)
{
    env->SetLongField(jRec, jniPosRec->distanceID, ts.distance);
    env->SetLongField(jRec, jniPosRec->angleID, ts.angle);
}

JNIEXPORT jobjectArray JNICALL
Java_com_example_lidar_1demo_nativeinterface_array_ArrayReturnTest_testStruct
(JNIEnv *env, jclass cls, jint len)
{
    load_jni_pos_rec(env);

    test_struct *ts;

    if (!make_struct((void *)&ts, len))
        return NULL;

    jobjectArray jArray = env->NewObjectArray(len, jniPosRec->cls, NULL);

    for (int i = 0; i < len; i++)
    {
        jobject jRec = env->NewObject(jniPosRec->cls, jniPosRec->ctorID);

        fill_java_rec_values(env, jRec, ts[i]);
        env->SetObjectArrayElement(jArray, i, jRec);
    }

    return jArray;
}

#ifdef __cplusplus
}
#endif