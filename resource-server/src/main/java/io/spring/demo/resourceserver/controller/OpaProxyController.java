package io.spring.demo.resourceserver.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@RestController
@RequestMapping("/api/opa")
public class OpaProxyController {

    private final RestTemplate restTemplate = new RestTemplate();
    private final String opaUrl;

    public OpaProxyController(@Value("${opa.url:http://localhost:8181}") String opaUrl) {
        this.opaUrl = opaUrl;
    }

    @PostMapping("/decision")
    public ResponseEntity<Map> evaluate(@RequestBody Map<String, Object> body) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
        return restTemplate.exchange(opaUrl + "/v1/data/authz/allow", HttpMethod.POST, entity, Map.class);
    }

    @GetMapping("/policy")
    public ResponseEntity<Map> policies() {
        return restTemplate.exchange(opaUrl + "/v1/policies", HttpMethod.GET, null, Map.class);
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return restTemplate.exchange(opaUrl + "/v1/policies", HttpMethod.GET, null, String.class);
    }
}
