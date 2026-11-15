#!/usr/bin/env bash
# Cambios de exposición entre dos runs. Uso: diff_runs.sh [RUN_A RUN_B]  (por defecto, los dos últimos)
set -u
REPORTS="$(cd "$(dirname "$0")/.." && pwd)/reports"
if [ $# -ge 2 ]; then A="$1"; B="$2"
else
  # shellcheck disable=SC2046  # rutas de reports/ sin espacios
  set -- $(ls -d "$REPORTS"/2*/ 2>/dev/null | tail -2)
  [ $# -eq 2 ] || { echo "Hacen falta al menos dos runs en $REPORTS"; exit 0; }
  A="${1%/}"; B="${2%/}"
fi
echo "A: $A"; echo "B: $B"
for f in ncat_ports.txt owners.txt; do
  [ -e "$A/logs/$f" ] || [ -e "$B/logs/$f" ] || continue
  echo "== $f"
  diff -u "$A/logs/$f" "$B/logs/$f" 2>&1 | tail -n +3 || true
  diff -q "$A/logs/$f" "$B/logs/$f" >/dev/null 2>&1 && echo "(sin cambios)"
done
