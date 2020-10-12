package com.example.lidar_demo.nativeinterface.cpptest;

public class PositionRec {
    public String symIdent;
    public int quantity;
    public double marketPrice;
    public String toString() {
        return "[" + symIdent + "," + quantity + "," + marketPrice + "]";
    }
}