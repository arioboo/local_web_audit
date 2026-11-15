# shellcheck shell=bash
# Funciones compartidas por los scripts de auditoría (se usa con `.`; no es ejecutable).
# Compatible con bash 3.2 (macOS): sin mapfile ni arrays vacíos bajo `set -u`.

# Escribe en pantalla y en $LOGS/audit.log si LOGS está definido.
log() {
  local line
  line="$(printf '[%s] %s' "$(date +%T)" "$*")"
  if [ -n "${LOGS:-}" ]; then echo "$line" | tee -a "$LOGS/audit.log"; else echo "$line"; fi
}

# Solo loopback; no relajar.
require_loopback() {
  case "$1" in
    127.0.0.1|localhost|::1) ;;
    *) echo "Solo se permite auditar loopback (127.0.0.1/localhost/::1)." >&2; exit 2 ;;
  esac
}

# Lista CSV de puertos numéricos 1-65535.
validate_ports() {
  case "$1" in
    ''|*[!0-9,]*|,*|*,|*,,*) echo "Puertos inválidos: '$1' (usa N[,N...])." >&2; exit 2 ;;
  esac
  local p IFS=,
  for p in $1; do
    case "$p" in 0*|??????*) echo "Puerto inválido: $p" >&2; exit 2 ;; esac
    if [ "$p" -lt 1 ] || [ "$p" -gt 65535 ]; then echo "Puerto fuera de rango: $p" >&2; exit 2; fi
  done
}

# Host listo para URL/openssl: IPv6 entre corchetes.
url_host() {
  case "$1" in *:*) printf '[%s]' "$1" ;; *) printf '%s' "$1" ;; esac
}
