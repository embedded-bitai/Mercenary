package com.example.gsmdemo.controller;

import com.example.gsmdemo.nativeinterface.uart.UartSpring;
import com.example.gsmdemo.socket.GetLocalHost;
import com.example.gsmdemo.socket.SocketClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import java.net.UnknownHostException;

import static java.lang.Thread.sleep;

@Controller
public class GSMController {
    static final Logger log = LoggerFactory.getLogger(GSMController.class);

    GetLocalHost gh;
    SocketClient sc;

    @GetMapping("/phone_init")
    public String phone_init() throws UnknownHostException {
        log.info("phone_init()");

        gh = new GetLocalHost();
        sc = new SocketClient(gh.getLocalHost().getHostAddress(), 33333);

        return "gsm";
    }

    @GetMapping("/phone_finish")
    public String phone_finish() throws UnknownHostException {
        log.info("phone_finish()");

        sc.closeSocket();

        return "gsm";
    }

    @GetMapping("/phone_call")
    public String phone_call() throws InterruptedException, UnknownHostException {
        log.info("phone_call()");

        String phoneNum = "01029807183";
        sc.sendData(1, 1, phoneNum);
        sleep(1000);

        //log.info(UartSpring.phone_call("01029807183"));

        return "gsm";
    }

    @GetMapping("/call_fin")
    public String call_fin() throws InterruptedException, UnknownHostException {
        log.info("call_fin()");

        sc.sendData(1, 0);
        sleep(1000);

        //log.info(UartSpring.phone_call("01029807183"));

        return "gsm";
    }

    @GetMapping("/phone_msg_send")
    public String phone_msg_send() throws InterruptedException, UnknownHostException {
        log.info("phone_msg_send()");

        String phoneNum = "01029807183";
        //String phoneNum = "01072400150";
        String phoneMsg = "Hello BitAI from LTE with JNI";

        sc.sendData(2, 1, phoneNum, phoneMsg);
        sleep(1000);

        //log.info(UartSpring.phone_msg_send(phoneNum, phoneMsg));

        return "gsm";
    }

    @GetMapping("/sms_fin")
    public String sms_fin() throws InterruptedException, UnknownHostException {
        log.info("sms_fin()");

        sc.sendData(2, 0);
        sleep(1000);

        //log.info(UartSpring.phone_call("01029807183"));

        return "gsm";
    }

    @GetMapping("/kill_daemon")
    public String kill_daemon() throws InterruptedException, UnknownHostException {
        log.info("kill_daemon()");

        sc.sendData(3);
        sleep(1000);

        //log.info(UartSpring.phone_call("01029807183"));

        return "gsm";
    }
}
