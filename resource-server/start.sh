#!/bin/sh
# start.sh — wait for SPIRE cert files before launching Spring Boot.
#
# Spring Boot's SSL bundle file watcher (reload-on-update: true) registers
# inotify watches at startup. If the files don't exist yet the watcher throws
# "is neither a file nor a directory" and the application context fails to start.
#
# Waiting here ensures the files exist before the JVM starts, while still
# allowing Spring Boot to hot-reload them when SPIRE rotates the certs.

CERT_DIR="/spire-certs"
MAX_WAIT=120  # seconds before giving up and starting anyway

if [ -d "$CERT_DIR" ]; then
    echo "[start] Waiting for SPIRE certs in ${CERT_DIR}..."
    elapsed=0
    until [ -f "${CERT_DIR}/svid.pem" ] && \
          [ -f "${CERT_DIR}/svid-key.pem" ] && \
          [ -f "${CERT_DIR}/bundle.pem" ]; do
        if [ "$elapsed" -ge "$MAX_WAIT" ]; then
            echo "[start] WARNING: timed out after ${MAX_WAIT}s — starting without certs."
            echo "[start] The SSL bundle will fail to load; check that spire-cert-watcher is running."
            break
        fi
        sleep 2
        elapsed=$((elapsed + 2))
        echo "[start] Cert files not ready yet (${elapsed}s / ${MAX_WAIT}s)..."
    done
    if [ -f "${CERT_DIR}/svid.pem" ]; then
        echo "[start] SPIRE certs ready. Starting resource-server."
    fi
else
    echo "[start] ${CERT_DIR} not mounted — starting without SPIRE certs."
fi

exec java -jar /app/app.jar
