package com.example.lidar_demo.controller;

import com.example.lidar_demo.nativeinterface.array.ArrayReturnTest;
import com.example.lidar_demo.nativeinterface.array.TestStruct;
import com.example.lidar_demo.nativeinterface.array.User;
import com.example.lidar_demo.nativeinterface.lidar.LidarSpring;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class ArrTestController {
    static final Logger log = LoggerFactory.getLogger(ArrTestController.class);

    @GetMapping("/arraytest")
    public String index() {
        log.info("arraytest");

        /*
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
         */

        TestStruct[] arr = ArrayReturnTest.testStruct(8192);

        if (arr != null) {
            for (int i = 0; i < arr.length; i++) {
                log.info(arr[i].toString());
            }
        } else {
            log.info("Error to alloc C Based Array");
        }

        return "test";
    }
}
