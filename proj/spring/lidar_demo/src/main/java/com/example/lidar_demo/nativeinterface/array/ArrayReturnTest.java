package com.example.lidar_demo.nativeinterface.array;

public class ArrayReturnTest {
    native public static int add(User user);
    native public static int[] makeIntArr(int len);
    native public static int setIntArr(int[] arr, int value);
    native public static void readyToGetStruct(long[] dist, long[] angle, int len);
    native public static void getStruct(long[] dist, long[] angle);
    native public static TestStruct[] testStruct(int len);

    static {
        System.loadLibrary("arrayreturntest");
    }
}
