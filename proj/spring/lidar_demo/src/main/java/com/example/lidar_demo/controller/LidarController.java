package com.example.lidar_demo.controller;

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
    LidarSpring ls = new LidarSpring();

    @GetMapping("/lidar")
    public String index(Locale locale, Model model) {
        log.info("index()");

        Date date = new Date();

        DateFormat dateFormat = DateFormat.getDateTimeInstance(
                DateFormat.LONG, DateFormat.LONG, locale
        );

        String formattedDate = dateFormat.format(date);
        model.addAttribute("servTime", formattedDate);



        return "index";
    }
}
