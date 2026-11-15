#!/usr/bin/env bash
# Genera report.md a partir de la evidencia de logs/. Uso: report.sh RUN_DIR HOST PUERTOS_CSV
set -u
. "$(dirname "$0")/lib/common.sh"
OUT="${1:?uso: report.sh RUN_DIR HOST PUERTOS_CSV}"; HOST="${2:?}"; PORTS="${3:?}"
LOGS="$OUT/logs"; REPORT="$OUT/report.md"
OPEN_LIST="$(tr '\n' ' ' < "$LOGS/open_ports.txt" 2>/dev/null)"

log "Generando informe $REPORT"
{
  echo "# Informe de auditoría local — $(basename "$OUT")"
  echo
  echo "- Objetivo: \`$HOST\`"
  echo "- Host: $(uname -srm)"
  echo "- Puertos analizados: $PORTS"
  echo "- Puertos abiertos (ncat): ${OPEN_LIST:-ninguno}"
  echo
  echo "## Sockets en escucha (todo el sistema)"
  echo '```'; cat "$LOGS/listening.txt"; echo '```'
  echo
  if [ -s "$LOGS/firewall.txt" ]; then
    echo "## Cortafuegos de aplicación"
    echo '```'; cat "$LOGS/firewall.txt"; echo '```'
    echo
  fi
  if [ -s "$LOGS/owners.txt" ]; then
    echo "## Dueño de los puertos abiertos (puerto proceso pid dirección exposición)"
    echo '```'; cat "$LOGS/owners.txt"; echo '```'
    echo
  fi
  if [ -s "$LOGS/containers.txt" ]; then
    echo "## Contenedores"; echo '```'; cat "$LOGS/containers.txt"; echo '```'
    echo
  fi
  if [ -s "$LOGS/diff_prev.txt" ]; then
    echo "## Cambios respecto al run anterior"; echo '```'; cat "$LOGS/diff_prev.txt"; echo '```'
    echo
  fi
  echo "## nmap: servicios"
  echo '```'; grep -vE '^#|^$' "$LOGS/nmap_services.txt"; echo '```'
  echo
  echo "## nmap: puertos abiertos 1-10000"
  echo '```'; grep -vE '^#|^$' "$LOGS/nmap_1-10000.txt"; echo '```'
  while IFS= read -r p <&3; do
    D="$LOGS/port_$p"; SCHEME="$(cat "$D/scheme.txt" 2>/dev/null || echo http)"
    echo
    echo "## Puerto $p"
    echo "### Banner (ncat)"; echo '```'; cat "$D/ncat_banner.txt"; echo '```'
    echo "### Tiempos"; echo '```'; cat "$D/timing_http.txt" "$D/timing_https.txt"; echo '```'
    echo "### Cabeceras ($SCHEME)"; echo '```'; cat "$D/headers_$SCHEME.txt" 2>/dev/null; echo '```'
    echo "### Cabeceras de seguridad ausentes"
    for h in Content-Security-Policy X-Frame-Options X-Content-Type-Options Strict-Transport-Security Referrer-Policy Permissions-Policy; do
      grep -qi "^$h:" "$D/headers_http.txt" "$D/headers_https.txt" 2>/dev/null || echo "- falta \`$h\`"
    done
    echo "### Métodos HTTP (solo lectura; escritura según Allow)"; echo '```'; cat "$D/methods.txt"; echo '```'
    echo "### Rutas sensibles (distintas de 404/000)"; echo '```'
    if [ "$SCHEME" = none ]; then cat "$D/paths.txt"; else grep -vE '^(404|000) ' "$D/paths.txt" || echo "(ninguna)"; fi; echo '```'
    if [ -s "$D/web_checks.txt" ]; then echo "### Versión, cookies, CORS y redirecciones"; echo '```'; cat "$D/web_checks.txt"; echo '```'; fi
    if [ -s "$D/nse.txt" ]; then echo "### nmap NSE (solo lectura)"; echo '```'; grep -vE '^#|^$' "$D/nse.txt"; echo '```'; fi
    if [ -s "$D/tls_cert.txt" ]; then echo "### Certificado TLS"; echo '```'; cat "$D/tls_cert.txt"; echo '```'; fi
  done 3< "$LOGS/open_ports.txt"
} > "$REPORT"
