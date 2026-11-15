# shellcheck shell=bash
# Shared functions for the audit scripts (sourced with `.`; not executable).
# Bash 3.2 compatible (macOS): no mapfile, no empty arrays under `set -u`.

# Writes to the screen and to $LOGS/audit.log when LOGS is set.
log() {
  local line
  line="$(printf '[%s] %s' "$(date +%T)" "$*")"
  if [ -n "${LOGS:-}" ]; then echo "$line" | tee -a "$LOGS/audit.log"; else echo "$line"; fi
}

# Loopback only; do not relax.
require_loopback() {
  case "$1" in
    127.0.0.1|localhost|::1) ;;
    *) echo "Only loopback can be audited (127.0.0.1/localhost/::1)." >&2; exit 2 ;;
  esac
}

# CSV list of numeric ports 1-65535.
validate_ports() {
  case "$1" in
    ''|*[!0-9,]*|,*|*,|*,,*) echo "Invalid ports: '$1' (use N[,N...])." >&2; exit 2 ;;
  esac
  local p IFS=,
  for p in $1; do
    case "$p" in 0*|??????*) echo "Invalid port: $p" >&2; exit 2 ;; esac
    if [ "$p" -lt 1 ] || [ "$p" -gt 65535 ]; then echo "Puerto fuera de rango: $p" >&2; exit 2; fi
  done
}

# Host ready for URL/openssl: IPv6 in brackets.
url_host() {
  case "$1" in *:*) printf '[%s]' "$1" ;; *) printf '%s' "$1" ;; esac
}
