package com.example.gsmdemo.nativeinterface.uart;

public class UartSpring {
    native public static void phone_call();
    native public static void phone_msg_send(String msg);
    native public static String print();

    static {
        System.loadLibrary("uartspring");
    }
}
