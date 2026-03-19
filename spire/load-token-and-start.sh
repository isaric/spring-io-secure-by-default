#!/bin/sh
# Load join token from file if agent not yet attested
# Check for both data.db (SQL) and agent-data.json (file-based) storage
if [ ! -f /opt/spire/data/agent/data.db ] && [ ! -f /opt/spire/data/agent/agent-data.json ] && [ -f /token/join-token ]; then
    export SPIRE_JOIN_TOKEN=$(cat /token/join-token)
    echo "Loaded join token from init container"
else
    echo "Agent already attested, using persisted identity"
fi
exec /opt/spire/bin/spire-agent run -config /opt/spire/conf/agent/agent.conf -expandEnv
