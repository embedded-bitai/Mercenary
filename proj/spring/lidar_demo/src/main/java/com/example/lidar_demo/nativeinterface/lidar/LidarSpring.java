package com.example.lidar_demo.nativeinterface.lidar;

public class LidarSpring {
    public native String print();
    public native Void lidar_start();
    public native Void lidar_stop();

    static {
        System.loadLibrary("lidarspring");
    }
}
