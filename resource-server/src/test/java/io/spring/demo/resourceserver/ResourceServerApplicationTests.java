package io.spring.demo.resourceserver;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

@SpringBootTest
@TestPropertySource(properties = {
    "spring.security.oauth2.resourceserver.jwt.jwk-set-uri=https://example.com/oauth2/jwks",
    "spring.security.oauth2.resourceserver.jwt.issuer-uri=",
    "opa.url=http://localhost:8181"
})
class ResourceServerApplicationTests {

    @Test
    void contextLoads() {
    }
}
