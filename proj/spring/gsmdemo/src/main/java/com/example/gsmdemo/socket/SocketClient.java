package com.example.gsmdemo.socket;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;

import java.net.InetAddress;
import java.net.UnknownHostException;

public class SocketClient {
    private Socket mSocket;

    private BufferedReader mIn;
    private PrintWriter mOut;

    public SocketClient(String ip, int port) {
        try {
            // 서버에 요청 보내기
            mSocket = new Socket(ip, port);
            System.out.println(ip + " 연결됨");

            // 통로 뚫기
            mIn = new BufferedReader(
                    new InputStreamReader(mSocket.getInputStream()));
            mOut = new PrintWriter(mSocket.getOutputStream());
        } catch (IOException e) {
            System.out.println(e.getMessage());
        }
    }

    public void sendData(int protocol) {
        // 메세지 전달
        mOut.println(protocol + " ");
        mOut.flush();
    }

    public void sendData(int protocol, int operation) {
        // 메세지 전달
        mOut.println(protocol + " " + operation);
        mOut.flush();
    }

    public void sendData(int protocol, int operation, String phoneNum) {
        // 메세지 전달
        mOut.println(protocol + " " + operation + " " + phoneNum);
        mOut.flush();
    }

    public void sendData(int protocol, int operation, String phoneNum, String phoneMsg) {
        // 메세지 전달
        mOut.println(protocol + " " + operation + " " + phoneNum + " " + phoneMsg);
        mOut.flush();
    }

    public void closeSocket() {
        // 소켓 닫기 (연결 끊기)
        try {
            mSocket.close();
        } catch (IOException e) {
            System.out.println(e.getMessage());
        }

        System.out.println("연결 해제!");
    }
}
