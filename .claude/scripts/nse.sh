#!/usr/bin/env bash
# nmap con una lista blanca de scripts NSE de solo lectura (nunca categorías: evita dos/brute/intrusive).
# Uso: nse.sh HOST PUERTO LOGS_DIR   -> LOGS_DIR/port_PUERTO/nse.txt
set -u
. "$(dirname "$0")/lib/common.sh"
HOST="${1:?uso: nse.sh HOST PUERTO LOGS_DIR}"; PORT="${2:?}"; LOGS="${3:?}"
require_loopback "$HOST"; validate_ports "$PORT"
D="$LOGS/port_$PORT"; mkdir -p "$D"

SCRIPTS="+http-title,+http-server-header,+http-headers,+http-security-headers,+http-methods,+http-cors,+http-cookie-flags,+http-robots.txt,+http-git,+http-config-backup,+ssl-cert,+ssl-enum-ciphers,+ssl-heartbleed"
NMAP=(-Pn); case "$HOST" in *:*) NMAP+=(-6) ;; esac

log "Puerto $PORT: nmap NSE (solo lectura)"
nmap "${NMAP[@]}" -sV --version-light -p "$PORT" --script "$SCRIPTS" "$HOST" -oN "$D/nse.txt" >/dev/null 2>&1
