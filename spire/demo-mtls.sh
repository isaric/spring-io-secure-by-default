#!/bin/bash
# demo-mtls.sh — Interactive demo script for SPIRE mTLS and certificate rotation
#
# Usage:
#   ./spire/demo-mtls.sh step1   # Show SPIRE workload registrations and a fresh SVID
#   ./spire/demo-mtls.sh step2   # Watch live cert rotation via the watcher service
#   ./spire/demo-mtls.sh step3   # Verify mTLS on resource-server (with/without client cert)
#   ./spire/demo-mtls.sh all     # Run all three steps sequentially

set -euo pipefail

SERVER_SOCKET="/tmp/spire-server/private/api.sock"
AGENT_SOCKET="/tmp/spire-agent/public/api.sock"
TRUST_DOMAIN="demo.spring.io"

_header() { echo; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo "  $*"; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; echo; }
_step()   { echo "▶ $*"; }
_pause()  { echo; read -rp "  [press Enter to continue] " _; echo; }

# ─── Step 1: Show Registered Workloads and Mint an SVID ───────────────────────
step1() {
    _header "STEP 1 — SPIRE Workload Registry & SVID Issuance"

    _step "Registered workload entries in trust domain: $TRUST_DOMAIN"
    docker exec spire-server /opt/spire/bin/spire-server entry show \
        -socketPath "$SERVER_SOCKET"

    _pause

    _step "Minting a short-lived X.509 SVID for resource-server (TTL: 60s)..."
    docker exec spire-server /opt/spire/bin/spire-server x509 mint \
        -socketPath "$SERVER_SOCKET" \
        -spiffeID "spiffe://${TRUST_DOMAIN}/resource-server" \
        -ttl 60s \
        | openssl x509 -text -noout \
        | grep -E "URI:|Subject:|Not Before:|Not After :|Serial Number:"

    _pause

    _step "The certificate above contains a SPIFFE URI SAN — that is the workload identity."
    echo "  SPIFFE ID:  spiffe://demo.spring.io/resource-server"
    echo "  Issued by:  Spring IO Demo CA (trust domain: demo.spring.io)"
    echo "  TTL:        60 seconds (configured in server.conf for this demo)"
}

# ─── Step 2: Watch Certificate Rotation ───────────────────────────────────────
step2() {
    _header "STEP 2 — Live Certificate Rotation"

    _step "Checking current SVID on disk (written by spire-cert-watcher)..."
    docker exec resource-server sh -c \
        "openssl x509 -in /spire-certs/svid.pem -noout -serial -enddate 2>/dev/null \
         || echo '(cert not yet available — spire-cert-watcher may still be starting)'"

    _pause

    _step "Streaming spire-cert-watcher logs — watch the serial number change every ~60s"
    echo "  (Ctrl+C to stop)"
    echo
    docker compose logs -f spire-cert-watcher

    _pause

    _step "Spring Boot reloads certs automatically when files change (reload-on-update: true)"
    echo "  Checking resource-server logs for SSL bundle reload events..."
    docker compose logs resource-server | grep -i "ssl bundle" || \
        echo "  (No reload events yet — wait for first rotation cycle)"
}

# ─── Step 3: Verify mTLS on Resource Server ───────────────────────────────────
step3() {
    _header "STEP 3 — mTLS Verification"

    _step "Attempt WITHOUT a client certificate (expect TLS handshake or 400)..."
    curl -sk --cacert <(docker exec resource-server cat /spire-certs/bundle.pem) \
        https://localhost:8443/public \
        -o /dev/null -w "HTTP status: %{http_code}\n" \
        || echo "  Connection refused or TLS error (expected — no client cert)"

    _pause

    _step "Attempt WITH the SPIFFE client certificate..."
    # Extract cert+key to temp files
    TMP=$(mktemp -d)
    trap 'rm -rf "$TMP"' RETURN
    docker exec resource-server cat /spire-certs/svid.pem     > "$TMP/client.pem"
    docker exec resource-server cat /spire-certs/svid-key.pem > "$TMP/client-key.pem"
    docker exec resource-server cat /spire-certs/bundle.pem   > "$TMP/ca.pem"

    curl -sk \
        --cert    "$TMP/client.pem" \
        --key     "$TMP/client-key.pem" \
        --cacert  "$TMP/ca.pem" \
        https://localhost:8443/public \
        -o /dev/null -w "HTTP status: %{http_code}\n" \
        || echo "  (Request failed — check that resource-server is up and certs are ready)"

    _pause

    _step "Inspect the SPIFFE URI SAN in the cert served by resource-server..."
    echo | openssl s_client \
        -connect localhost:8443 \
        -CAfile "$TMP/ca.pem" \
        -cert   "$TMP/client.pem" \
        -key    "$TMP/client-key.pem" \
        2>/dev/null \
        | openssl x509 -noout -text \
        | grep -E "URI:|Not After :|Serial Number:"
}

# ─── Dispatch ─────────────────────────────────────────────────────────────────
case "${1:-help}" in
    step1) step1 ;;
    step2) step2 ;;
    step3) step3 ;;
    all)
        step1
        step2
        step3
        ;;
    *)
        echo "Usage: $0 {step1|step2|step3|all}"
        echo
        echo "  step1  Show registered workloads and mint a fresh SVID"
        echo "  step2  Watch live cert rotation (serial number changes every ~60s)"
        echo "  step3  Verify mTLS: request with vs without a client certificate"
        echo "  all    Run all steps in sequence"
        exit 1
        ;;
esac
