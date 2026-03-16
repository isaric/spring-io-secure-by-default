package io.spring.demo.resourceserver.model;

import java.time.Instant;

public record Document(
    String id,
    String title,
    String content,
    String owner,
    String classification,
    String department,
    Instant createdAt
) {}
