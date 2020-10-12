package com.example.lidar_demo.nativeinterface.cpptest;

import com.example.lidar_demo.nativeinterface.array.TestStruct;
import com.example.lidar_demo.nativeinterface.array.User;

public class DonUseMallocFreeOnJNI {
    native public static PositionRec[] getPositionBlotter();
    native public static void newBasedArray(long[] dist, long[] angle1, int len);

    static {
        System.loadLibrary("cpptest");
    }
}
