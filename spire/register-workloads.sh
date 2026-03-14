#!/bin/bash
# Bootstrap SPIRE workload registrations for demo services
# This script registers workload identities for each service in the demo

set -e

SPIRE_SERVER_SOCKET="/tmp/spire-server/private/api.sock"
TRUST_DOMAIN="demo.spring.io"

echo "Waiting for SPIRE server to be ready..."
until /opt/spire/bin/spire-server healthcheck -socketPath "$SPIRE_SERVER_SOCKET" 2>/dev/null; do
    echo "SPIRE server not ready yet, waiting..."
    sleep 2
done

echo "SPIRE server is ready. Registering workloads..."

# Register auth-server
/opt/spire/bin/spire-server entry create \
    -socketPath "$SPIRE_SERVER_SOCKET" \
    -parentID "spiffe://${TRUST_DOMAIN}/spire/agent/join_token/demo" \
    -spiffeID "spiffe://${TRUST_DOMAIN}/auth-server" \
    -selector "docker:label:com.spring.demo.service:auth-server" \
    -ttl 3600 2>/dev/null || echo "auth-server entry may already exist"

# Register resource-server
/opt/spire/bin/spire-server entry create \
    -socketPath "$SPIRE_SERVER_SOCKET" \
    -parentID "spiffe://${TRUST_DOMAIN}/spire/agent/join_token/demo" \
    -spiffeID "spiffe://${TRUST_DOMAIN}/resource-server" \
    -selector "docker:label:com.spring.demo.service:resource-server" \
    -ttl 3600 2>/dev/null || echo "resource-server entry may already exist"

# Register OPA
/opt/spire/bin/spire-server entry create \
    -socketPath "$SPIRE_SERVER_SOCKET" \
    -parentID "spiffe://${TRUST_DOMAIN}/spire/agent/join_token/demo" \
    -spiffeID "spiffe://${TRUST_DOMAIN}/opa" \
    -selector "docker:label:com.spring.demo.service:opa" \
    -ttl 3600 2>/dev/null || echo "opa entry may already exist"

echo "Workload registration complete!"
echo ""
echo "Registered SPIFFE IDs:"
/opt/spire/bin/spire-server entry show -socketPath "$SPIRE_SERVER_SOCKET"
