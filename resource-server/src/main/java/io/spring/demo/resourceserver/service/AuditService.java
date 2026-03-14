package io.spring.demo.resourceserver.service;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class AuditService {
    private static final Logger auditLog = LoggerFactory.getLogger("AUDIT");
    private final MeterRegistry meterRegistry;
    private final List<Map<String, Object>> recentEvents = new CopyOnWriteArrayList<>();
    private final Map<String, Counter> counterCache = new ConcurrentHashMap<>();
    private static final int MAX_EVENTS = 100;

    public AuditService(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }

    public void audit(String action, String subject, String resource, String outcome) {
        Map<String, Object> event = Map.of(
            "timestamp", Instant.now().toString(),
            "action", action,
            "subject", subject,
            "resource", resource,
            "outcome", outcome
        );

        auditLog.info("AUDIT event={} subject={} resource={} outcome={}", action, subject, resource, outcome);

        counterCache.computeIfAbsent(action + ":" + outcome, key ->
            Counter.builder("security.audit.events")
                .tag("action", action)
                .tag("outcome", outcome)
                .register(meterRegistry)
        ).increment();

        recentEvents.add(0, event);
        if (recentEvents.size() > MAX_EVENTS) {
            recentEvents.subList(MAX_EVENTS, recentEvents.size()).clear();
        }
    }

    public List<Map<String, Object>> getRecentEvents() {
        return List.copyOf(recentEvents);
    }
}
