package com.example.lidar_demo.nativeinterface.array;

public class ArrayReturnTest {
    native public static void test();
    native public static int add(User user);

    static {
        System.loadLibrary("arrayreturntest");
    }
}
