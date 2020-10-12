#include <jni.h>
#include <stdio.h>

JNIEXPORT jstring JNICALL
Java_com_example_lidar_1demo_nativeinterface_test_HelloSpring_print(JNIEnv *env, jobject obj)
{
    char msg[60] = "Hello C Lang with Java for JNI";
    jstring res;

    res = (*env)->NewStringUTF(env, msg);
    return res;
}