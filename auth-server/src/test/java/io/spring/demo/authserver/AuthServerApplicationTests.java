package io.spring.demo.authserver;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class AuthServerApplicationTests {

    @Test
    void contextLoads() {
        // Verifies that the Spring context starts successfully with all beans
    }
}
