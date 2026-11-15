#!/usr/bin/env bash
# TLS certificate of a port, only if https answered (requires http.sh first). Usage: tls.sh HOST PORT LOGS_DIR
set -u
. "$(dirname "$0")/lib/common.sh"
HOST="${1:?usage: tls.sh HOST PORT LOGS_DIR}"; PORT="${2:?}"; LOGS="${3:?}"
require_loopback "$HOST"; validate_ports "$PORT"
D="$LOGS/port_$PORT"

grep -q '^code=000' "$D/timing_https.txt" 2>/dev/null && exit 0
echo | openssl s_client -connect "$(url_host "$HOST"):$PORT" -servername "$HOST" 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates -fingerprint > "$D/tls_cert.txt" 2>&1
