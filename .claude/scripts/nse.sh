#!/usr/bin/env bash
# nmap with a read-only NSE script allowlist (never categories: avoids dos/brute/intrusive).
# Usage: nse.sh HOST PORT LOGS_DIR   -> LOGS_DIR/port_PORT/nse.txt
set -u
. "$(dirname "$0")/lib/common.sh"
HOST="${1:?usage: nse.sh HOST PORT LOGS_DIR}"; PORT="${2:?}"; LOGS="${3:?}"
require_loopback "$HOST"; validate_ports "$PORT"
D="$LOGS/port_$PORT"; mkdir -p "$D"

SCRIPTS="+http-title,+http-server-header,+http-headers,+http-security-headers,+http-methods,+http-cors,+http-cookie-flags,+http-robots.txt,+http-git,+http-config-backup,+ssl-cert,+ssl-enum-ciphers,+ssl-heartbleed"
NMAP=(-Pn); case "$HOST" in *:*) NMAP+=(-6) ;; esac

log "Port $PORT: nmap NSE (read-only)"
nmap "${NMAP[@]}" -sV --version-light -p "$PORT" --script "$SCRIPTS" "$HOST" -oN "$D/nse.txt" >/dev/null 2>&1
