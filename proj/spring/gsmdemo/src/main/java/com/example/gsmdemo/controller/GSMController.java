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

        UartSpring.phone_call("01012341234");

        return "gsm";
    }

    @GetMapping("/phone_msg_send")
    public String phone_msg_send() throws InterruptedException {
        log.info("phone_msg_send()");

        String msg = "test message";

        UartSpring.phone_msg_send("01012341234", msg);

        return "gsm";
    }
}
