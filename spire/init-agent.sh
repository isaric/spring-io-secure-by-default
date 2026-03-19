#!/bin/bash
# Generate a new join token if the agent hasn't been attested yet
set -e

if [ ! -f spire/data/agent/data.db ]; then
    echo "Generating new SPIRE join token..."

    # Start server first
    docker compose up -d spire-server

    # Wait for server to be healthy
    echo "Waiting for SPIRE server..."
    until docker compose exec spire-server /opt/spire/bin/spire-server healthcheck -socketPath /tmp/spire-server/private/api.sock 2>/dev/null; do
        sleep 2
    done

    # Generate token
    TOKEN=$(docker compose exec spire-server /opt/spire/bin/spire-server token generate \
        -socketPath /tmp/spire-server/private/api.sock \
        -spiffeID spiffe://demo.spring.io/agent/demo \
        -ttl 600 2>/dev/null | grep 'Token:' | awk '{print $2}')

    echo "Token generated: ${TOKEN:0:20}..."
    export SPIRE_JOIN_TOKEN="$TOKEN"

    # Save to .env for docker compose
    echo "SPIRE_JOIN_TOKEN=$TOKEN" > .env

    echo "Starting SPIRE agent with new token..."
else
    echo "Agent already attested, no new token needed"
fi

# Start all services
docker compose up -d
