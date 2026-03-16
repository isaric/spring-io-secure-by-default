package io.spring.demo.resourceserver.controller;

import io.spring.demo.resourceserver.service.AuditService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AuditService auditService;

    public AdminController(AuditService auditService) {
        this.auditService = auditService;
    }

    @GetMapping("/users")
    public List<Map<String, String>> listUsers(@AuthenticationPrincipal Jwt jwt) {
        auditService.audit("LIST_USERS", jwt.getSubject(), "all-users", "SUCCESS");
        return List.of(
            Map.of("username", "alice", "roles", "ADMIN,USER", "department", "engineering"),
            Map.of("username", "bob", "roles", "USER", "department", "marketing"),
            Map.of("username", "carol", "roles", "USER,AUDITOR", "department", "finance")
        );
    }

    @GetMapping("/audit")
    @PreAuthorize("hasRole('ADMIN') or hasRole('AUDITOR')")
    public List<Map<String, Object>> getAuditLog(@AuthenticationPrincipal Jwt jwt) {
        auditService.audit("VIEW_AUDIT_LOG", jwt.getSubject(), "audit-log", "SUCCESS");
        return auditService.getRecentEvents();
    }

    @PostMapping("/opa/reload")
    public Map<String, String> reloadPolicy(@AuthenticationPrincipal Jwt jwt) {
        auditService.audit("RELOAD_POLICY", jwt.getSubject(), "opa-policy", "SUCCESS");
        return Map.of("message", "Policy reload triggered", "status", "success");
    }
}
