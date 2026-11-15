#!/usr/bin/env bash
# Open-port detection (ncat -z) and services (nmap). Usage: ports.sh HOST PORTS_CSV LOGS_DIR
# Leaves the open ones, one per line, in LOGS_DIR/open_ports.txt.
set -u
. "$(dirname "$0")/lib/common.sh"
HOST="${1:?usage: ports.sh HOST PORTS_CSV LOGS_DIR}"; PORTS="${2:?}"; LOGS="${3:?}"
require_loopback "$HOST"; validate_ports "$PORTS"
mkdir -p "$LOGS"

log "Port scan with ncat -z"
: > "$LOGS/ncat_ports.txt"; : > "$LOGS/open_ports.txt"
IFS=',' read -ra PLIST <<< "$PORTS"
for p in "${PLIST[@]}"; do
  if ncat -z -w 2 "$HOST" "$p" 2>/dev/null; then
    echo "$p open" >> "$LOGS/ncat_ports.txt"; echo "$p" >> "$LOGS/open_ports.txt"
  else
    echo "$p closed" >> "$LOGS/ncat_ports.txt"
  fi
done

NMAP=(-Pn); case "$HOST" in *:*) NMAP+=(-6) ;; esac
log "nmap -sV (common + open ports)"
nmap "${NMAP[@]}" -sV --version-light -p "$PORTS" "$HOST" -oN "$LOGS/nmap_services.txt" >/dev/null 2>&1
nmap "${NMAP[@]}" -p 1-10000 --open "$HOST" -oN "$LOGS/nmap_1-10000.txt" >/dev/null 2>&1
