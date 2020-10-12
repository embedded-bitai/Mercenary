package com.example.lidar_demo;

import com.example.lidar_demo.nativeinterface.test.HelloSpring;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class LidarDemoApplication {
    final static Logger log = LoggerFactory.getLogger(LidarDemoApplication.class);

    public static void main(String[] args) {
        HelloSpring hs = new HelloSpring();
        log.info(hs.print());

        SpringApplication.run(LidarDemoApplication.class, args);

        /*
        UartSpring us = new UartSpring();

        for(;;) {
            log.info(us.print());
        }
         */
    }
}