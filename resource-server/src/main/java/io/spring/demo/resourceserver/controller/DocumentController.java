package io.spring.demo.resourceserver.controller;

import io.spring.demo.resourceserver.model.Document;
import io.spring.demo.resourceserver.service.AuditService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/documents")
public class DocumentController {
    private static final Logger log = LoggerFactory.getLogger(DocumentController.class);
    private final AuditService auditService;

    // In-memory document store for demo
    private static final Map<String, Document> documents = new ConcurrentHashMap<>();

    static {
        documents.put("doc-1", new Document("doc-1", "Q1 Engineering Report", "Engineering Q1 results...", "alice", "internal", "engineering", Instant.now()));
        documents.put("doc-2", new Document("doc-2", "Marketing Campaign 2025", "Marketing strategy for 2025...", "bob", "public", "marketing", Instant.now()));
        documents.put("doc-3", new Document("doc-3", "Finance Audit 2024", "Annual finance audit report...", "carol", "confidential", "finance", Instant.now()));
        documents.put("doc-4", new Document("doc-4", "Spring IO Demo Notes", "Notes for the Spring IO presentation...", "alice", "public", "engineering", Instant.now()));
    }

    public DocumentController(AuditService auditService) {
        this.auditService = auditService;
    }

    @GetMapping
    public List<Document> listDocuments(@AuthenticationPrincipal Jwt jwt) {
        String subject = jwt.getSubject();
        List<String> roles = jwt.getClaimAsStringList("roles");
        String department = jwt.getClaimAsString("department");

        auditService.audit("LIST_DOCUMENTS", subject, "all-documents", "SUCCESS");
        log.info("User {} (roles={}, dept={}) listing documents", subject, roles, department);

        // Filter documents based on user's department and roles
        boolean isAdmin = roles != null && roles.contains("ADMIN");
        if (isAdmin) {
            return List.copyOf(documents.values());
        }
        // Non-admins see their department's docs + public docs
        return documents.values().stream()
                .filter(doc -> "public".equals(doc.classification()) ||
                               (department != null && department.equals(doc.department())))
                .toList();
    }

    @GetMapping("/{id}")
    public Document getDocument(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        String subject = jwt.getSubject();
        Document doc = documents.get(id);
        if (doc == null) {
            auditService.audit("GET_DOCUMENT", subject, id, "NOT_FOUND");
            throw new org.springframework.web.server.ResponseStatusException(
                org.springframework.http.HttpStatus.NOT_FOUND, "Document not found: " + id);
        }
        auditService.audit("GET_DOCUMENT", subject, id, "SUCCESS");
        return doc;
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public Document createDocument(@RequestBody Document document, @AuthenticationPrincipal Jwt jwt) {
        String subject = jwt.getSubject();
        Document newDoc = new Document(
            "doc-" + (documents.size() + 1),
            document.title(),
            document.content(),
            subject,
            document.classification() != null ? document.classification() : "internal",
            document.department() != null ? document.department() : "unknown",
            Instant.now()
        );
        documents.put(newDoc.id(), newDoc);
        auditService.audit("CREATE_DOCUMENT", subject, newDoc.id(), "SUCCESS");
        return newDoc;
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public Map<String, String> deleteDocument(@PathVariable String id, @AuthenticationPrincipal Jwt jwt) {
        String subject = jwt.getSubject();
        Document removed = documents.remove(id);
        if (removed == null) {
            throw new org.springframework.web.server.ResponseStatusException(
                org.springframework.http.HttpStatus.NOT_FOUND, "Document not found: " + id);
        }
        auditService.audit("DELETE_DOCUMENT", subject, id, "SUCCESS");
        return Map.of("message", "Document " + id + " deleted successfully");
    }
}
