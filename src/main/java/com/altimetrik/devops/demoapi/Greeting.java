package com.altimetrik.devops.demoapi;

import lombok.Builder;
import lombok.Data;
import org.springframework.stereotype.Component;

@Data
@Component
public class Greeting {
    Long id;
    String content;
    String hostname;

    public Greeting() {

    }

    public Greeting(Long id, String content, String hostname) {
        this.id = id;
        this.content = content;
        this.hostname = hostname;
    }
}