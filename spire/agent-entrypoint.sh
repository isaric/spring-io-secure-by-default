#!/bin/sh
# Wrapper script for SPIRE agent that loads join token from file if needed

set -e

# If agent hasn't been attested yet and token file exists, load it
if [ ! -f /opt/spire/data/agent/data.db ] && [ -f /token/join-token ]; then
    export SPIRE_JOIN_TOKEN=$(cat /token/join-token)
    echo "Using join token from init container: ${SPIRE_JOIN_TOKEN:0:20}..."
else
    echo "Agent already attested or no token file found, using existing identity"
fi

# Start the agent with the original entrypoint
exec /opt/spire/bin/spire-agent run -config /opt/spire/conf/agent/agent.conf
