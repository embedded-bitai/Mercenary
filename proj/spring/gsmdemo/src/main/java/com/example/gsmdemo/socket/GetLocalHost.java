package com.example.gsmdemo.socket;

import java.net.InetAddress;
import java.net.UnknownHostException;

public class GetLocalHost {
    public InetAddress getLocalHost() throws UnknownHostException {
        InetAddress inetAddress = InetAddress.getLocalHost();

        System.out.println("IP Address:- " + inetAddress.getHostAddress());
        System.out.println("Host Name:- " + inetAddress.getHostName());

        return inetAddress;
    }
}
