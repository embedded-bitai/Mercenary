package com.example.gsmdemo.controller;

import com.example.gsmdemo.nativeinterface.uart.UartSpring;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class GSMController {
    static final Logger log = LoggerFactory.getLogger(GSMController.class);

    @GetMapping("/phone_call")
    public String phone_call() throws InterruptedException {
        log.info("phone_call()");

        log.info(UartSpring.phone_call("01029807183"));

        return "gsm";
    }

    @GetMapping("/phone_msg_send")
    public String phone_msg_send() throws InterruptedException {
        log.info("phone_msg_send()");

        String msg = "Hello BitAI from LTE with JNI";

        log.info(UartSpring.phone_msg_send("01029807183", msg));

        return "gsm";
    }
}
