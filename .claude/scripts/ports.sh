#!/usr/bin/env bash
# Detección de puertos abiertos (ncat -z) y servicios (nmap). Uso: ports.sh HOST PUERTOS_CSV LOGS_DIR
# Deja los abiertos, uno por línea, en LOGS_DIR/open_ports.txt.
set -u
. "$(dirname "$0")/lib/common.sh"
HOST="${1:?uso: ports.sh HOST PUERTOS_CSV LOGS_DIR}"; PORTS="${2:?}"; LOGS="${3:?}"
require_loopback "$HOST"; validate_ports "$PORTS"
mkdir -p "$LOGS"

log "Escaneo de puertos con ncat -z"
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
log "nmap -sV (puertos comunes + abiertos)"
nmap "${NMAP[@]}" -sV --version-light -p "$PORTS" "$HOST" -oN "$LOGS/nmap_services.txt" >/dev/null 2>&1
nmap "${NMAP[@]}" -p 1-10000 --open "$HOST" -oN "$LOGS/nmap_1-10000.txt" >/dev/null 2>&1
