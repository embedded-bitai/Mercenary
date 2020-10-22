package com.example.gsmdemo.nativeinterface.uart;

public class UartSpring {
    native public static String phone_call(String phoneNum);
    native public static String phone_msg_send(String phoneNum, String msg);
    native public static String phone_call_fin();
    native public static String phone_msg_send_fin();
    native public static void gsm_init();
    native public static String print();

    static {
        System.loadLibrary("uartspring");
    }
}
