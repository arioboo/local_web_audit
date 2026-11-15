#!/usr/bin/env bash
# Fuga de versión, cookies, CORS y redirecciones de un puerto (útil con una app real).
# Uso: cookies_cors.sh HOST PUERTO LOGS_DIR   (requiere http.sh antes) -> port_PUERTO/web_checks.txt
set -u
. "$(dirname "$0")/lib/common.sh"
HOST="${1:?uso: cookies_cors.sh HOST PUERTO LOGS_DIR}"; PORT="${2:?}"; LOGS="${3:?}"
require_loopback "$HOST"; validate_ports "$PORT"
U="$(url_host "$HOST"):$PORT"
D="$LOGS/port_$PORT"
SCHEME="$(cat "$D/scheme.txt" 2>/dev/null)"; [ -n "$SCHEME" ] && [ "$SCHEME" != none ] || exit 0
H="$D/headers_$SCHEME.txt"; [ -s "$H" ] || exit 0

log "Puerto $PORT: cookies, CORS y versión"
curl -sk -m 5 -D "$D/headers_cors.txt" -o /dev/null -H 'Origin: http://evil.example' "$SCHEME://$U/" 2>/dev/null
{
  echo "# Fuga de versión (Server / X-Powered-By)"
  tr -d '\r' < "$H" | grep -iE '^(server|x-powered-by):' || echo "(ninguna)"
  echo
  echo "# Cookies"
  COOKIES="$(tr -d '\r' < "$H" | grep -i '^set-cookie:')"
  if [ -z "$COOKIES" ]; then echo "(sin cookies)"; else
    echo "$COOKIES" | while IFS= read -r l; do
      # atributos tras el primer ';' (no el nombre ni el valor de la cookie): ";path=/;secure;samesite=lax;"
      attrs=";$(echo "$l" | tr '[:upper:]' '[:lower:]' | cut -s -d';' -f2- | tr -d ' ');"; miss=""
      case "$attrs" in *";httponly;"*) ;; *) miss="$miss HttpOnly" ;; esac
      case "$attrs" in *";secure;"*) ;; *) miss="$miss Secure" ;; esac
      case "$attrs" in *";samesite="*) ;; *) miss="$miss SameSite" ;; esac
      echo "$l -> faltan:${miss:- ninguno}"
    done
  fi
  echo
  echo "# CORS (Origin: http://evil.example)"
  ACAO="$(tr -d '\r' < "$D/headers_cors.txt" 2>/dev/null | grep -i '^access-control-allow-origin:')"
  case "$ACAO" in
    '') echo "(sin Access-Control-Allow-Origin)" ;;
    *'*'*) echo "$ACAO  <- comodín" ;;
    *evil.example*) echo "$ACAO  <- refleja el Origin" ;;
    *) echo "$ACAO" ;;
  esac
  echo
  echo "# Redirecciones"
  tr -d '\r' < "$H" | grep -iE '^location:' || echo "(ninguna)"
} > "$D/web_checks.txt"
