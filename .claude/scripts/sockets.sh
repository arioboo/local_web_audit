#!/usr/bin/env bash
# Sockets TCP en escucha de todo el sistema (lsof/netstat). Uso: sockets.sh LOGS_DIR
set -u
. "$(dirname "$0")/lib/common.sh"
LOGS="${1:?uso: sockets.sh LOGS_DIR}"
mkdir -p "$LOGS"

lsof -iTCP -sTCP:LISTEN -nP > "$LOGS/listening.txt" 2>&1
netstat -an -p tcp | grep LISTEN > "$LOGS/netstat_listen.txt" 2>&1
