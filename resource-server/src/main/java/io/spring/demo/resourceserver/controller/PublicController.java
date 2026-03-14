package io.spring.demo.resourceserver.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api/public")
public class PublicController {

    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
            "status", "UP",
            "service", "resource-server",
            "timestamp", Instant.now().toString()
        );
    }

    @GetMapping("/info")
    public Map<String, Object> info() {
        return Map.of(
            "name", "Spring IO Secure-by-Default Demo",
            "description", "Resource server demonstrating Zero Trust security patterns",
            "features", new String[]{
                "OAuth2/OIDC with Spring Security",
                "Policy-as-Code with OPA",
                "mTLS with SPIFFE/SPIRE",
                "Certificate-bound tokens",
                "Audit logging",
                "Prometheus metrics"
            }
        );
    }
}
