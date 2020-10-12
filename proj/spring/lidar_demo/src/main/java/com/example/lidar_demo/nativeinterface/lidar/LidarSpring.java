package com.example.lidar_demo.nativeinterface.lidar;

public class LidarSpring {
    native public String print();
    native public void lidar_start();
    native public void lidar_stop();

    //static {
    //    System.loadLibrary("lidarspring");
    //}
}
