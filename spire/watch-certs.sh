#!/bin/bash
# watch-certs.sh — Continuously fetch X.509 SVIDs from the SPIRE Workload API
# and write PEM files to /spire-certs/. Timestamps each renewal so rotation is visible.
#
# Runs as the spire-cert-watcher service inside a container that has:
#   - /tmp/spire-agent/public/api.sock  (SPIRE agent socket)
#   - /spire-certs/                     (shared named volume, writable)

set -euo pipefail

SOCKET="/tmp/spire-agent/public/api.sock"
OUT_DIR="/spire-certs"
SPIRE_AGENT_BIN="/opt/spire/bin/spire-agent"
POLL_INTERVAL=10  # seconds between fetch attempts

mkdir -p "$OUT_DIR"

echo "[watch-certs] Starting SVID watcher. Output dir: $OUT_DIR"
echo "[watch-certs] Agent socket: $SOCKET"
echo "[watch-certs] Polling every ${POLL_INTERVAL}s"

wait_for_socket() {
    echo "[watch-certs] Waiting for SPIRE agent socket..."
    until [ -S "$SOCKET" ]; do
        sleep 2
    done
    echo "[watch-certs] SPIRE agent socket ready."
}

fetch_svids() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' RETURN

    # Fetch X.509 SVIDs; writes svid.0.pem, svid.0.key.pem, bundle.0.pem
    "$SPIRE_AGENT_BIN" api fetch x509 \
        -socketPath "$SOCKET" \
        -write "$tmp_dir" \
        2>&1

    # Atomically move files to shared volume so Spring Boot sees a consistent snapshot
    if [ -f "$tmp_dir/svid.0.pem" ]; then
        cp "$tmp_dir/svid.0.pem"     "$OUT_DIR/svid.pem.tmp"
        cp "$tmp_dir/svid.0.key"     "$OUT_DIR/svid-key.pem.tmp"
        cp "$tmp_dir/bundle.0.pem"   "$OUT_DIR/bundle.pem.tmp"

        mv "$OUT_DIR/svid.pem.tmp"     "$OUT_DIR/svid.pem"
        mv "$OUT_DIR/svid-key.pem.tmp" "$OUT_DIR/svid-key.pem"
        mv "$OUT_DIR/bundle.pem.tmp"   "$OUT_DIR/bundle.pem"

        # Extract cert metadata
        local serial not_after not_before spiffe_id fingerprint issuer
        serial=$(openssl x509 -in "$OUT_DIR/svid.pem" -noout -serial 2>/dev/null | sed 's/serial=//' || echo "unknown")
        not_after=$(openssl x509 -in "$OUT_DIR/svid.pem" -noout -enddate 2>/dev/null | sed 's/notAfter=//' || echo "unknown")
        not_before=$(openssl x509 -in "$OUT_DIR/svid.pem" -noout -startdate 2>/dev/null | sed 's/notBefore=//' || echo "unknown")
        issuer=$(openssl x509 -in "$OUT_DIR/svid.pem" -noout -issuer 2>/dev/null | sed 's/issuer=//' || echo "unknown")
        fingerprint=$(openssl x509 -in "$OUT_DIR/svid.pem" -noout -fingerprint -sha256 2>/dev/null | sed 's/SHA256 Fingerprint=//' || echo "unknown")
        spiffe_id=$(openssl x509 -in "$OUT_DIR/svid.pem" -noout -ext subjectAltName 2>/dev/null | grep -o 'URI:[^,]*' | sed 's/URI://' | head -1 || echo "unknown")

        # Increment rotation counter (persisted across polls)
        local count_file="$OUT_DIR/.rotation_count"
        local count=0
        [ -f "$count_file" ] && count=$(cat "$count_file")
        count=$((count + 1))
        echo "$count" > "$count_file"

        local now
        now=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

        # Write cert-info.json atomically — served by nginx to the frontend
        cat > "$OUT_DIR/cert-info.json.tmp" <<EOF
{
  "status": "active",
  "spiffeId": "${spiffe_id}",
  "serial": "${serial}",
  "notBefore": "${not_before}",
  "notAfter": "${not_after}",
  "issuer": "${issuer}",
  "fingerprint": "${fingerprint}",
  "rotationCount": ${count},
  "lastRotated": "${now}"
}
EOF
        mv "$OUT_DIR/cert-info.json.tmp" "$OUT_DIR/cert-info.json"

        echo "[watch-certs] ${now} | rotation #${count} | serial=${serial} | expires=${not_after}"
    else
        echo "[watch-certs] WARNING: No SVID returned by agent (not yet attested?)"
        # Write unavailable state so the frontend shows a clear message
        cat > "$OUT_DIR/cert-info.json" <<'EOF'
{"status": "pending", "message": "Waiting for SPIRE agent attestation..."}
EOF
    fi
}

wait_for_socket

while true; do
    fetch_svids || echo "[watch-certs] fetch failed, retrying in ${POLL_INTERVAL}s"
    sleep "$POLL_INTERVAL"
done
