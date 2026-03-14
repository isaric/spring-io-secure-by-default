package io.spring.demo.resourceserver.opa;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

import java.util.Map;

@Component
public class OpaClient {
    private static final Logger log = LoggerFactory.getLogger(OpaClient.class);

    private final RestTemplate restTemplate;
    private final String opaUrl;

    private final boolean failOpen;

    public OpaClient(
            @Value("${opa.url:http://opa:8181}") String opaUrl,
            @Value("${opa.fail-open:true}") boolean failOpen) {
        this.restTemplate = new RestTemplate();
        this.opaUrl = opaUrl;
        this.failOpen = failOpen;
    }

    /**
     * Evaluates an OPA policy.
     * @param policy the policy path (e.g. "authz/allow")
     * @param input the input object
     * @return true if allowed, false otherwise
     */
    public boolean evaluate(String policy, Map<String, Object> input) {
        try {
            String url = opaUrl + "/v1/data/" + policy;
            Map<String, Object> request = Map.of("input", input);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);

            ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.POST, entity, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                Object result = body.get("result");
                if (result instanceof Boolean) {
                    boolean decision = (Boolean) result;
                    log.info("OPA decision for policy={} input={}: {}", policy, input, decision);
                    return decision;
                }
            }
            log.warn("Unexpected OPA response for policy={}: {}", policy, response.getBody());
            return false;
        } catch (Exception e) {
            log.error("Failed to call OPA at {}: {}", opaUrl, e.getMessage());
            // Configurable fail behaviour: set opa.fail-open=false in production to fail closed
            return failOpen;
        }
    }
}
