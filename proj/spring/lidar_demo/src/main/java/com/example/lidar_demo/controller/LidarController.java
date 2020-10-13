package com.example.lidar_demo.controller;

import com.example.lidar_demo.nativeinterface.array.ArrayReturnTest;
import com.example.lidar_demo.nativeinterface.array.User;
import com.example.lidar_demo.nativeinterface.lidar.LidarSpring;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.text.DateFormat;
import java.util.Date;
import java.util.Locale;

@Controller
public class LidarController {
    static final Logger log = LoggerFactory.getLogger(LidarController.class);

    float[] dist = new float[1421];
    float[] angle = new float[1421];

    @GetMapping("/startlidar")
    public String startlidar(Locale locale, Model model) throws InterruptedException {
        log.info("startlidar()");

        /*
        Date date = new Date();

        DateFormat dateFormat = DateFormat.getDateTimeInstance(
                DateFormat.LONG, DateFormat.LONG, locale
        );

        String formattedDate = dateFormat.format(date);
        model.addAttribute("servTime", formattedDate);
         */

        LidarSpring.lidar_start();

        return "lidar";
    }

    @GetMapping("/getlidar")
    public String getlidar(Locale locale, Model model) throws InterruptedException {
        log.info("getlidar()");

        LidarSpring.print(dist, angle);

        for(int i = 0; i < 1421; i++)
        {
            log.info("dist = " + dist[i] + ", angle = " + angle[i]);
        }

        return "lidar";
    }

    @GetMapping("/stoplidar")
    public void stoplidar(Locale locale, Model model) throws InterruptedException {
        log.info("stoplidar()");

        LidarSpring.lidar_stop();
    }
}
