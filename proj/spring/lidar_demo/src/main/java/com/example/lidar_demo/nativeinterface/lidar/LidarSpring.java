package com.example.lidar_demo.nativeinterface.lidar;

public class LidarSpring {
    native public static void print(float[] dist, float[] angle);
    native public static void lidar_start();
    native public static void lidar_stop();

    static {
        System.loadLibrary("lidarspring");
    }
}
