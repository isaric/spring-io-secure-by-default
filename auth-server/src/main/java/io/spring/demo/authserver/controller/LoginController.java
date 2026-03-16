package io.spring.demo.authserver.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class LoginController {

    @Value("${auth.frontend-uri:http://localhost:3000}")
    private String frontendUri;

    @GetMapping("/")
    public String root() {
        return "redirect:" + frontendUri;
    }

    @GetMapping("/login")
    public String login() {
        return "login";
    }
}
