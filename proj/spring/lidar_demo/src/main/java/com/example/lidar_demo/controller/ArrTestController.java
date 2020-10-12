package com.example.lidar_demo.controller;

import com.example.lidar_demo.nativeinterface.array.ArrayReturnTest;
import com.example.lidar_demo.nativeinterface.array.TestStruct;
import com.example.lidar_demo.nativeinterface.array.User;
import com.example.lidar_demo.nativeinterface.cpptest.PositionRec;
import com.example.lidar_demo.nativeinterface.lidar.LidarSpring;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import static com.example.lidar_demo.nativeinterface.cpptest.DonUseMallocFreeOnJNI.getPositionBlotter;

@Controller
public class ArrTestController {
    static final Logger log = LoggerFactory.getLogger(ArrTestController.class);

    @GetMapping("/arraytest")
    public String index() throws InterruptedException {
        log.info("arraytest");

        User user = new User();
        user.setSerial(10L);
        user.setName("test");
        user.setAge(20);

        int res = ArrayReturnTest.add(user);
        log.info("res = " + res);

        int[] javaArr = ArrayReturnTest.makeIntArr(10);
        ArrayReturnTest.setIntArr(javaArr, 77);

        log.info("arr len = " + javaArr.length);

        for (int i = 0; i < javaArr.length; i++) {
            log.info("arr[" + i + "] = " + javaArr[i]);
        }

        long[] dist1 = new long[4096];
        long[] dist2 = new long[4096];
        long[] angle1 = new long[4096];
        long[] angle2 = new long[4096];
        ArrayReturnTest.readyToGetStruct(dist1, dist2, angle1, angle2, dist1.length);

        //Thread.sleep(1000);
        for (int i = 0; i < dist1.length; i++) {
            log.info("dist1 = " + dist1[i] + ", angle1 = " + angle1[i]);
        }

        for (int i = 0; i < dist2.length; i++) {
            log.info("dist2 = " + dist2[i] + ", angle2 = " + angle2[i]);
        }

        long heapSize = Runtime.getRuntime().totalMemory();

        System.out.println("Heap Size : " + heapSize);

        System.out.println("Heap Size(M) : " + heapSize / (1024 * 1024) + " MB");

        /*
        TestStruct[] arr = ArrayReturnTest.testStruct(10);

        if (arr != null) {
            for (int i = 0; i < arr.length; i++) {
                log.info(arr[i].toString());
            }
        } else {
            log.info("Error to alloc C Based Array");
        }
         */

        return "test";
    }

    @GetMapping("/donusemalloc")
    public String donusemalloc() throws InterruptedException {
        log.info("donusemalloc");

        PositionRec[] posRecArray = getPositionBlotter();

        if (posRecArray != null) {
            for (int i = 0; i < posRecArray.length; i++)
                System.out.println(posRecArray[i]);
        }

        return "donusemalloc";
    }

    @GetMapping("/longandint")
    public String longandint() throws InterruptedException {
        log.info("longandint");

        int[] dist = new int[8192];
        int[] angle = new int[8192];

        ArrayReturnTest.readyToGetIntArray(dist, angle, dist.length);

        //Thread.sleep(1000);
        for (int i = 0; i < dist.length; i++) {
            log.info("dist = " + dist[i] + ", angle = " + angle[i]);
        }

        return "longandint";
    }
}
