package com.altimetrik.devops.demoapi;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GreetingController {
    private static final String template = "Hello, %s!";
    private final AtomicLong counter = new AtomicLong();

    @GetMapping("/greeting")
    Greeting greeting(@RequestParam(value="name", defaultValue="World") String name) throws UnknownHostException {
        Greeting greeting = new Greeting(counter.incrementAndGet(), String.format(template, name),"UNKNOWN");
        greeting.hostname = InetAddress.getLocalHost().getHostName();
        return greeting;
    }
}