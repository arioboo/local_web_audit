#!/usr/bin/env bash
# Comprobaciones HTTP de un puerto: banner, cabeceras, métodos (solo lectura) y rutas sensibles.
# Uso: http.sh HOST PUERTO LOGS_DIR   -> LOGS_DIR/port_PUERTO/
set -u
. "$(dirname "$0")/lib/common.sh"
HOST="${1:?uso: http.sh HOST PUERTO LOGS_DIR}"; PORT="${2:?}"; LOGS="${3:?}"
require_loopback "$HOST"; validate_ports "$PORT"
U="$(url_host "$HOST"):$PORT"
D="$LOGS/port_$PORT"; mkdir -p "$D"

SENSITIVE=(/.env /.git/config /.git/HEAD /.DS_Store /robots.txt /sitemap.xml /server-status /phpinfo.php /admin /login /wp-login.php /backup.zip /config.json /package.json /api /swagger.json /openapi.json /actuator/health)

code() { curl -sk -m 5 -o /dev/null -w '%{http_code}' "$@" 2>/dev/null; }

log "Puerto $PORT: banner y HTTP"
printf 'HEAD / HTTP/1.0\r\nHost: %s\r\n\r\n' "$HOST" | ncat -w 3 "$HOST" "$PORT" > "$D/ncat_banner.txt" 2>&1

for scheme in http https; do
  curl -sk -m 5 -D "$D/headers_$scheme.txt" -o "$D/body_$scheme.html" -w \
    "code=%{http_code} ip=%{remote_ip} connect=%{time_connect}s ttfb=%{time_starttransfer}s total=%{time_total}s size=%{size_download}B\n" \
    "$scheme://$U/" > "$D/timing_$scheme.txt" 2>&1
done

# Esquema efectivo: el primero que respondió (no 000). Métodos y rutas se prueban solo por ese.
SCHEME=none
for s in http https; do
  grep -q '^code=000' "$D/timing_$s.txt" || { SCHEME=$s; break; }
done
echo "$SCHEME" > "$D/scheme.txt"
BASE="$SCHEME://$U"
if [ "$SCHEME" = none ]; then
  echo "(no probado: el puerto no respondió por http ni por https)" | tee "$D/methods.txt" > "$D/paths.txt"
  exit 0
fi

# Métodos: solo sin efectos secundarios. Los de escritura se deducen de la cabecera Allow.
{
  echo "GET $(code "$BASE/")"
  echo "HEAD $(code -I "$BASE/")"
  echo "OPTIONS $(code -X OPTIONS -D "$D/headers_options.txt" "$BASE/")"
  echo "TRACE $(code -X TRACE "$BASE/")"
  grep -i '^allow:' "$D/headers_options.txt" 2>/dev/null
} > "$D/methods.txt"

: > "$D/paths.txt"
for path in "${SENSITIVE[@]}"; do
  echo "$(code "$BASE$path") $path" >> "$D/paths.txt"
done
