package com.example.lidar_demo.nativeinterface.array;

/*
struct user {
    long serial;
    char name[32];
    int age;
}
 */
public class User {
    long serial;
    String name;
    int age;

    public void setSerial(long serial) {
        this.serial = serial;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
