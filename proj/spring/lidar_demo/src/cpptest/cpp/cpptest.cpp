#include <jni.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include <unistd.h>

#ifdef __cplusplus
extern "C"
{
#endif

typedef struct _POSITIONREC {
    char SymIdent[20];
    int Quantity;
    double MarketPrice;
} POSITIONREC, * LPPOSITIONREC;

bool GetPositionBlotter(int * iCount, void * recArray) {
    LPPOSITIONREC pPosRec = new POSITIONREC[2];
    strcpy(pPosRec[0].SymIdent, "Hello");
    pPosRec[0].Quantity = 1;
    pPosRec[0].MarketPrice = 2.0;
    strcpy(pPosRec[1].SymIdent, "World!");
    pPosRec[1].Quantity = 3;
    pPosRec[1].MarketPrice = 4.0;
    *iCount = 2;
    *((LPPOSITIONREC *)recArray) = pPosRec;
    return true;
}

typedef struct _JNI_POSREC {
    jclass cls;
    jmethodID ctorID;
    jfieldID symIdentID;
    jfieldID quantityID;
    jfieldID marketPriceID;
} JNI_POSREC;

JNI_POSREC * jniPosRec = NULL;

void loadJniPosRec(JNIEnv * env) {
    if (jniPosRec != NULL)
        return;
    jniPosRec = new JNI_POSREC;
    jniPosRec->cls = env->FindClass("PositionRec");
    jniPosRec->ctorID = env->GetMethodID(jniPosRec->cls, "<init>", "()V");
    jniPosRec->symIdentID = env->GetFieldID(jniPosRec->cls, "symIdent", "Ljava/lang/String;");
    jniPosRec->quantityID = env->GetFieldID(jniPosRec->cls, "quantity", "I");
    jniPosRec->marketPriceID = env->GetFieldID(jniPosRec->cls, "marketPrice", "D");
}

void fillJavaPosRecValues(JNIEnv * env, jobject jPosRec, POSITIONREC cPosRec) {
    env->SetObjectField(jPosRec, jniPosRec->symIdentID, env->NewStringUTF(cPosRec.SymIdent));
    env->SetIntField(jPosRec, jniPosRec->quantityID, cPosRec.Quantity);
    env->SetDoubleField(jPosRec, jniPosRec->marketPriceID, cPosRec.MarketPrice);
}

JNIEXPORT jobjectArray JNICALL
Java_com_example_lidar_1demo_nativeinterface_cpptest_DonUseMallocFreeOnJNI_getPositionBlotter
(JNIEnv * env, jobject obj) {
    loadJniPosRec(env);

    LPPOSITIONREC pPosRec;
    int count;

    if (!GetPositionBlotter(&count, (void *)&pPosRec))
        return NULL;

    jobjectArray jPosRecArray = env->NewObjectArray(count, jniPosRec->cls, NULL);

    for (int i = 0; i < count; i++) {
        jobject jPosRec = env->NewObject(jniPosRec->cls, jniPosRec->ctorID);

        fillJavaPosRecValues(env, jPosRec, pPosRec[i]);
        env->SetObjectArrayElement(jPosRecArray, i, jPosRec);
    }

    return jPosRecArray;
}

#ifdef __cplusplus
}
#endif