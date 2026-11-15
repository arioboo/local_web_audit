#!/usr/bin/env bash
# System-wide listening TCP sockets (lsof/netstat). Usage: sockets.sh LOGS_DIR
set -u
. "$(dirname "$0")/lib/common.sh"
LOGS="${1:?usage: sockets.sh LOGS_DIR}"
mkdir -p "$LOGS"

lsof -iTCP -sTCP:LISTEN -nP > "$LOGS/listening.txt" 2>&1
netstat -an -p tcp | grep LISTEN > "$LOGS/netstat_listen.txt" 2>&1

# Application firewall state (read-only; full path, not in PATH)
FW=/usr/libexec/ApplicationFirewall/socketfilterfw
if [ -x "$FW" ]; then
  "$FW" --getglobalstate --getblockall --getstealthmode > "$LOGS/firewall.txt" 2>&1
else
  echo "socketfilterfw no disponible" > "$LOGS/firewall.txt"
fi
