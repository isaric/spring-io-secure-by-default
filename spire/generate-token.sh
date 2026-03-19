#!/bin/bash
# Generate a SPIRE join token and write it to a file for the agent to consume
set -e

SPIRE_SERVER_SOCKET="/tmp/spire-server/private/api.sock"
TOKEN_FILE="/token/join-token"
TRUST_DOMAIN="demo.spring.io"
SPIFFE_ID="spiffe://${TRUST_DOMAIN}/agent/demo"

echo "Waiting for SPIRE server to be ready..."
until /opt/spire/bin/spire-server healthcheck -socketPath "$SPIRE_SERVER_SOCKET" 2>/dev/null; do
    echo "SPIRE server not ready yet, waiting..."
    sleep 2
done

echo "SPIRE server is ready. Generating join token..."

# Generate a new join token with a reasonable TTL (10 minutes)
TOKEN=$(/opt/spire/bin/spire-server token generate \
    -socketPath "$SPIRE_SERVER_SOCKET" \
    -spiffeID "$SPIFFE_ID" \
    -ttl 600 2>/dev/null | grep 'Token:' | awk '{print $2}')

if [ -z "$TOKEN" ]; then
    echo "ERROR: Failed to generate token"
    exit 1
fi

echo "Token generated successfully: ${TOKEN:0:20}..."

# Write token to shared volume
echo "$TOKEN" > "$TOKEN_FILE"
chmod 644 "$TOKEN_FILE"

echo "Token written to $TOKEN_FILE"
echo "Init complete!"
