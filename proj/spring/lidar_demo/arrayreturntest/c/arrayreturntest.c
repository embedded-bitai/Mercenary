#include <jni.h>
#include <stdio.h>

struct User
{
    long lSerial;
    char caName[32];
    int iAge;
};

JNIEXPORT jint JNICALL
Java_com_example_lidar_demo_nativeinterface_array_ArrayReturnTest_add
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
Java_com_example_lidar_demo_nativeinterface_lidar_LidarSpring_lidar_stop(JNIEnv *env, jobject obj)
{
    kill(lidar_pid, SIGINT);
}