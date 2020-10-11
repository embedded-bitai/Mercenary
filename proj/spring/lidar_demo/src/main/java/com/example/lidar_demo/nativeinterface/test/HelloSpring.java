package com.example.lidar_demo.nativeinterface.test;

public class HelloSpring {
    // native란 시스템 하위 API들을 활용할 경우 사용한다.
    // native 키워드가 있으면 C, C++ 코드를 사용하겠다는 의미
    // Netty(JNI 베이스 고속 통신 라이브러리)
    public native String print();

    static {
        // System.out.println()
        // 라이브러리: 결국 실행 파일(메모리 섹션 text의 집합 덩어리)
        // *.dll, *.so 파일들이 라이브러리 파일임
        // 리눅스, 유닉스(맥)에서는 hello라는 이름이 libhello.so와 동일
        System.loadLibrary("hello");
    }
}
