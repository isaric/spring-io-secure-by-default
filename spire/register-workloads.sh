#!/bin/bash
# Bootstrap SPIRE workload registrations for demo services.
# Safe to re-run: updates TTL on existing entries rather than failing silently.

set -e

SPIRE_SERVER_SOCKET="/tmp/spire-server/private/api.sock"
TRUST_DOMAIN="demo.spring.io"
PARENT_ID="spiffe://${TRUST_DOMAIN}/agent/demo"
SVID_TTL=60   # Short TTL so cert rotation is visible during the demo

echo "Waiting for SPIRE server to be ready..."
until /opt/spire/bin/spire-server healthcheck -socketPath "$SPIRE_SERVER_SOCKET" 2>/dev/null; do
    echo "SPIRE server not ready yet, waiting..."
    sleep 2
done

echo "SPIRE server is ready. Registering workloads (TTL: ${SVID_TTL}s)..."

# Register or update a workload entry.
# Uses `entry update` when the SPIFFE ID already exists so that TTL changes
# (e.g. switching from 3600s to 60s for the rotation demo) take effect.
register_workload() {
    local label="$1"
    local spiffe_id="spiffe://${TRUST_DOMAIN}/${label}"
    local selector="docker:label:com.spring.demo.service:${label}"

    local existing_id
    existing_id=$(
        /opt/spire/bin/spire-server entry show \
            -socketPath "$SPIRE_SERVER_SOCKET" \
            -spiffeID "$spiffe_id" 2>/dev/null \
        | grep "^Entry ID" | awk '{print $NF}' | head -1
    )

    if [ -n "$existing_id" ]; then
        echo "  Updating ${spiffe_id} (entry: ${existing_id}, TTL: ${SVID_TTL}s)..."
        /opt/spire/bin/spire-server entry update \
            -socketPath "$SPIRE_SERVER_SOCKET" \
            -id         "$existing_id" \
            -parentID   "$PARENT_ID" \
            -spiffeID   "$spiffe_id" \
            -selector   "$selector" \
            -ttl        "$SVID_TTL"
    else
        echo "  Creating ${spiffe_id} (TTL: ${SVID_TTL}s)..."
        /opt/spire/bin/spire-server entry create \
            -socketPath "$SPIRE_SERVER_SOCKET" \
            -parentID   "$PARENT_ID" \
            -spiffeID   "$spiffe_id" \
            -selector   "$selector" \
            -ttl        "$SVID_TTL"
    fi
}

register_workload "auth-server"
register_workload "resource-server"
register_workload "opa"

echo ""
echo "Workload registration complete. Registered SPIFFE IDs:"
/opt/spire/bin/spire-server entry show -socketPath "$SPIRE_SERVER_SOCKET"
