package com.example.lidar_demo.nativeinterface.uart;

public class UartSpring {

    public native String print();

    static {
        System.loadLibrary("uartspring");
    }
}
