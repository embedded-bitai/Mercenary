package com.example.lidar_demo.nativeinterface.array;

public class ArrayReturnTest {
    native public static int add(User user);
    native public static int[] makeIntArr(int len);
    native public static int setIntArr(int[] arr, int value);
    native public static void readyToGetStruct(long[] dist1, long[] dist2, long[] angle1, long[] angle2, int len);
    native public static void getStruct(long[] dist1, long[] dist2, long[] angle1, long[] angle2);
    native public static TestStruct[] testStruct(int len);
    native public static void readyToGetIntArray(int[] dist, int[] angle, int len);
    native public static void readyToGetFloatArray();
    native public static void getFloatArray(float[] dist, float[] angle);

    static {
        System.loadLibrary("arrayreturntest");
    }
}
