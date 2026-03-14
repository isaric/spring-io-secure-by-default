package authz_test

import data.authz
import rego.v1

# ─── Allow: public path ──────────────────────────────────────────────────────
test_allow_public_health if {
    authz.allow with input as {
        "method": "GET",
        "path": "/api/public/health",
        "subject": "anonymous",
        "roles": [],
        "department": "unknown",
        "hour": 10,
    }
}

test_allow_actuator if {
    authz.allow with input as {
        "method": "GET",
        "path": "/actuator/health",
        "subject": "anonymous",
        "roles": [],
        "department": "unknown",
        "hour": 10,
    }
}

# ─── Allow: authenticated GET on documents ───────────────────────────────────
test_allow_authenticated_read if {
    authz.allow with input as {
        "method": "GET",
        "path": "/api/documents",
        "subject": "alice",
        "roles": ["ADMIN", "USER"],
        "department": "engineering",
        "hour": 10,
    }
}

# ─── Deny: unauthenticated GET on documents ──────────────────────────────────
test_deny_unauthenticated_read if {
    not authz.allow with input as {
        "method": "GET",
        "path": "/api/documents",
        "subject": "anonymous",
        "roles": [],
        "department": "unknown",
        "hour": 10,
    }
}

# ─── Allow: ADMIN can POST ───────────────────────────────────────────────────
test_allow_admin_create if {
    authz.allow with input as {
        "method": "POST",
        "path": "/api/documents",
        "subject": "alice",
        "roles": ["ADMIN", "USER"],
        "department": "engineering",
        "hour": 10,
    }
}

# ─── Deny: non-ADMIN cannot POST ─────────────────────────────────────────────
test_deny_non_admin_create if {
    not authz.allow with input as {
        "method": "POST",
        "path": "/api/documents",
        "subject": "bob",
        "roles": ["USER"],
        "department": "marketing",
        "hour": 10,
    }
}

# ─── Deny: ADMIN cannot read during restricted hours ─────────────────────────
test_deny_restricted_hours if {
    not authz.allow with input as {
        "method": "GET",
        "path": "/api/documents",
        "subject": "alice",
        "roles": ["ADMIN", "USER"],
        "department": "engineering",
        "hour": 23,
    }
}

# ─── Allow: ADMIN access to admin endpoints ──────────────────────────────────
test_allow_admin_endpoint if {
    authz.allow with input as {
        "method": "GET",
        "path": "/api/admin/users",
        "subject": "alice",
        "roles": ["ADMIN"],
        "department": "engineering",
        "hour": 10,
    }
}

# ─── Deny: non-ADMIN access to admin endpoints ───────────────────────────────
test_deny_non_admin_endpoint if {
    not authz.allow with input as {
        "method": "GET",
        "path": "/api/admin/users",
        "subject": "bob",
        "roles": ["USER"],
        "department": "marketing",
        "hour": 10,
    }
}

# ─── Allow: AUDITOR can access audit log ─────────────────────────────────────
test_allow_auditor_audit_log if {
    authz.allow with input as {
        "method": "GET",
        "path": "/api/admin/audit",
        "subject": "carol",
        "roles": ["AUDITOR"],
        "department": "finance",
        "hour": 10,
    }
}
