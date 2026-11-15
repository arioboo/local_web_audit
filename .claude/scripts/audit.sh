#!/usr/bin/env bash
# Auditoría ligera de la web local (solo loopback). Orquesta los scripts por utilidad
# (sockets, ports, http, tls, report) y escribe en reports/<timestamp>/.
# Uso: scripts/audit.sh [host] [puertos_csv]
#   host     por defecto 127.0.0.1 (solo loopback)
#   puertos  por defecto: 80,443,3000,5000,5173,7000,8000,8080,8443
#   --containers  añade los contenedores Docker con puertos publicados
#   --diff        compara con el run anterior (cambios de exposición)
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/lib/common.sh"

WITH_CONTAINERS=0; WITH_DIFF=0; ARGS=()
for a in "$@"; do
  case "$a" in
    --containers) WITH_CONTAINERS=1 ;;
    --diff) WITH_DIFF=1 ;;
    *) ARGS+=("$a") ;;
  esac
done
HOST="${ARGS[0]:-127.0.0.1}"
PORTS="${ARGS[1]:-80,443,3000,5000,5173,7000,8000,8080,8443}"
require_loopback "$HOST"; validate_ports "$PORTS"

REPORTS="$(cd "$DIR/.." && pwd)/reports"
TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$REPORTS"
PREV="$(ls -d "$REPORTS"/2*/ 2>/dev/null | tail -1)"; PREV="${PREV%/}"
OUT="$REPORTS/$TS"; n=0
while ! mkdir "$OUT" 2>/dev/null; do n=$((n+1)); OUT="$REPORTS/$TS-$n"; done
LOGS="$OUT/logs"; mkdir -p "$LOGS"

log "Sockets TCP en escucha"
"$DIR/sockets.sh" "$LOGS"
"$DIR/ports.sh" "$HOST" "$PORTS" "$LOGS"
"$DIR/owners.sh" "$LOGS"
[ "$WITH_CONTAINERS" = 1 ] && "$DIR/containers.sh" "$LOGS"

while IFS= read -r p <&3; do
  "$DIR/http.sh" "$HOST" "$p" "$LOGS"
  "$DIR/tls.sh" "$HOST" "$p" "$LOGS"
  "$DIR/cookies_cors.sh" "$HOST" "$p" "$LOGS"
  "$DIR/nse.sh" "$HOST" "$p" "$LOGS"
done 3< "$LOGS/open_ports.txt"

if [ "$WITH_DIFF" = 1 ]; then
  if [ -n "$PREV" ]; then "$DIR/diff_runs.sh" "$PREV" "$OUT" > "$LOGS/diff_prev.txt"; else echo "No hay run anterior" > "$LOGS/diff_prev.txt"; fi
fi

"$DIR/report.sh" "$OUT" "$HOST" "$PORTS"
ln -sfn "$(basename "$OUT")" "$REPORTS/latest"   # solo al terminar: latest siempre tiene report.md
log "Hecho. Informe: $OUT/report.md"
