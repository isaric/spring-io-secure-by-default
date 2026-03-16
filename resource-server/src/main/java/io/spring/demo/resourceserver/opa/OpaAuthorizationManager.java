package io.spring.demo.resourceserver.opa;

import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authorization.AuthorizationDecision;
import org.springframework.security.authorization.AuthorizationManager;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.security.web.access.intercept.RequestAuthorizationContext;
import org.springframework.stereotype.Component;

import java.time.LocalTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

@Component
public class OpaAuthorizationManager implements AuthorizationManager<RequestAuthorizationContext> {
    private static final Logger log = LoggerFactory.getLogger(OpaAuthorizationManager.class);
    private final OpaClient opaClient;

    public OpaAuthorizationManager(OpaClient opaClient) {
        this.opaClient = opaClient;
    }

    @Override
    public AuthorizationDecision check(Supplier<Authentication> authenticationSupplier, RequestAuthorizationContext context) {
        Authentication authentication = authenticationSupplier.get();
        HttpServletRequest request = context.getRequest();

        Map<String, Object> input = buildInput(authentication, request);
        boolean allowed = opaClient.evaluate("authz/allow", input);

        log.info("OPA authorization: method={} path={} user={} allowed={}",
                request.getMethod(), request.getRequestURI(),
                authentication != null ? authentication.getName() : "anonymous", allowed);

        return new AuthorizationDecision(allowed);
    }

    private Map<String, Object> buildInput(Authentication authentication, HttpServletRequest request) {
        Map<String, Object> input = new HashMap<>();
        input.put("method", request.getMethod());
        input.put("path", request.getRequestURI());
        input.put("hour", LocalTime.now().getHour());

        if (authentication instanceof JwtAuthenticationToken jwtAuth) {
            Jwt jwt = jwtAuth.getToken();
            input.put("subject", jwt.getSubject());
            List<String> roles = jwt.getClaimAsStringList("roles");
            input.put("roles", roles != null ? roles : List.of());
            String department = jwt.getClaimAsString("department");
            input.put("department", department != null ? department : "unknown");
            input.put("scopes", jwt.getClaimAsStringList("scope"));
        } else {
            input.put("subject", "anonymous");
            input.put("roles", List.of());
            input.put("department", "unknown");
            input.put("scopes", List.of());
        }

        return input;
    }
}
