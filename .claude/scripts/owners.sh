#!/usr/bin/env bash
# Owning process of each open port and the interfaces it listens on. Usage: owners.sh LOGS_DIR
# Requires LOGS_DIR/open_ports.txt (ports.sh). Output: LOGS_DIR/owners.txt (port process pid bind exposure).
set -u
. "$(dirname "$0")/lib/common.sh"
LOGS="${1:?usage: owners.sh LOGS_DIR}"
: > "$LOGS/owners.txt"

log "Owner of each open port"
while IFS= read -r p <&3; do
  lsof -nP -iTCP:"$p" -sTCP:LISTEN -Fpcn 2>/dev/null | awk -v port="$p" '
    /^p/ { pid = substr($0, 2) }
    /^c/ { cmd = substr($0, 2) }
    /^n/ {
      n = substr($0, 2); bind = "otra-interfaz"
      if (n ~ /^\*:/ || n ~ /^0\.0\.0\.0:/ || n ~ /^\[::\]:/) bind = "EXPUESTO(todas-las-interfaces)"
      else if (n ~ /^127\./ || n ~ /^\[::1\]:/) bind = "loopback"
      print port, cmd, pid, n, bind
    }' | awk '!seen[$0]++' >> "$LOGS/owners.txt"
done 3< "$LOGS/open_ports.txt"
