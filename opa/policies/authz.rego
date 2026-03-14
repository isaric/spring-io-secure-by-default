package authz

import rego.v1

# Default deny
default allow := false

# ─── Public paths ────────────────────────────────────────────────────────────
allow if {
    public_path
}

public_path if {
    startswith(input.path, "/api/public/")
}

public_path if {
    startswith(input.path, "/actuator/")
}

# ─── Authenticated read access ───────────────────────────────────────────────
allow if {
    input.method == "GET"
    startswith(input.path, "/api/documents")
    authenticated
    not restricted_hours
}

# ─── Write access requires ADMIN role ────────────────────────────────────────
allow if {
    input.method in {"POST", "PUT", "PATCH"}
    startswith(input.path, "/api/documents")
    has_role("ADMIN")
}

allow if {
    input.method == "DELETE"
    startswith(input.path, "/api/documents")
    has_role("ADMIN")
}

# ─── Admin endpoints ─────────────────────────────────────────────────────────
allow if {
    startswith(input.path, "/api/admin/")
    has_role("ADMIN")
}

allow if {
    input.path == "/api/admin/audit"
    has_role("AUDITOR")
}

# ─── Finance department: confidential docs only accessible during business hours ─
allow if {
    input.method == "GET"
    startswith(input.path, "/api/documents")
    has_role("AUDITOR")
    business_hours
}

# ─── Helpers ─────────────────────────────────────────────────────────────────
authenticated if {
    input.subject != "anonymous"
    input.subject != ""
}

has_role(role) if {
    role in input.roles
}

business_hours if {
    input.hour >= 8
    input.hour < 18
}

restricted_hours if {
    input.hour >= 22
    input.hour < 6
}

# ─── Deny rules (audit) ──────────────────────────────────────────────────────
deny_reason := "not_authenticated" if {
    not authenticated
    not public_path
}

deny_reason := "insufficient_role" if {
    authenticated
    input.method in {"POST", "PUT", "DELETE"}
    not has_role("ADMIN")
}

deny_reason := "outside_business_hours" if {
    authenticated
    restricted_hours
}
