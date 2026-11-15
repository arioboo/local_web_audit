#!/usr/bin/env bash
# Containers with published ports (Docker/Colima), read-only. Usage: containers.sh LOGS_DIR
set -u
. "$(dirname "$0")/lib/common.sh"
LOGS="${1:?usage: containers.sh LOGS_DIR}"
log "Docker containers"
if ! command -v docker >/dev/null 2>&1; then echo "docker no instalado" > "$LOGS/containers.txt"; exit 0; fi
if ! docker info >/dev/null 2>&1; then echo "docker/colima no está en marcha (no se arranca desde aquí)" > "$LOGS/containers.txt"; exit 0; fi
docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}' > "$LOGS/containers.txt" 2>&1
[ -s "$LOGS/containers.txt" ] || echo "(sin contenedores en ejecución)" > "$LOGS/containers.txt"
