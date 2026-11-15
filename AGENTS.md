# AGENTS.md — local_web_audit

Pruebas de pentesting ligero y revisión del estado de la web local, en macOS (Darwin arm64). Solo reconocimiento y comprobaciones de configuración. Idioma del proyecto: español.

## Alcance y reglas (importante)
- **Solo loopback**: `127.0.0.1`, `localhost`, `::1`. Todos los scripts de `.claude/scripts/` lo comprueban con `require_loopback`; no relajar esa comprobación.
- **Prohibido**: DoS, fuzzing masivo, fuerza bruta de credenciales, escaneo de la LAN o de hosts externos, explotación activa, peticiones con efectos secundarios (POST/PUT/DELETE/PATCH a una app real).
- **Pedir confirmación** antes de apuntar cualquier herramienta a un destino que no sea loopback, aunque el usuario lo sugiera de pasada. `lan/` y `web/` están reservadas y fuera de alcance.
- **No instalar nada** (`brew`) ni usar `sudo` sin preguntar. `.claude/settings.json` bloquea `brew install/upgrade`.
- Los hallazgos de AirPlay en `*:5000`/`*:7000` son falsos positivos conocidos (ver «Interpretar informes»).

## Estructura
```
AGENTS.md            fuente única de instrucciones (CLAUDE.md solo contiene `@AGENTS.md`)
latest_report.md     symlink relativo → .claude/reports/latest/report.md (último informe; sigue a `latest`)
latest_recommendations.md  symlink relativo → .claude/reports/latest/recommendations.md (recomendaciones del último run)
requirements.txt    sin dependencias de pip (solo comentarios); las herramientas de sistema están en «Herramientas»
README.md            guía de usuario (alcance, uso, cómo leer el informe); mantenerla alineada con este fichero
localhost/           notas y pruebas manuales de loopback (vacía)
lan/  web/           reservadas, vacías, fuera de alcance
.claude/
  settings.json      permisos del proyecto (allow/ask/deny)
  scripts/           auditoría, un script por utilidad (+ lib/common.sh)
  reports/<ts>/      un run: report.md + logs/ (evidencia cruda); `latest` → último run
  notes/             tools.md (herramientas y PATH), review-2026-11-15.md, first-audit-checklist.md
```
- `/Users/arl94/Claude/local_web_audit` es un symlink a este directorio; los paths impresos pueden salir por cualquiera.
- Fuera del proyecto: `/Users/arl94/Projects/request_install.md` (herramientas pendientes de instalar).
- Repo git inicializado (sin commits aún). `.gitignore` excluye `reports/` (también casa con `.claude/reports/`) y `.DS_Store`.

## Comandos
```bash
.claude/scripts/audit.sh                          # 127.0.0.1, puertos por defecto
.claude/scripts/audit.sh localhost 3000,8080      # puertos concretos (lista CSV, no rangos)
.claude/scripts/audit.sh 127.0.0.1 3000 --diff --containers
cat latest_report.md                              # leer el último informe (symlink en la raíz)
tail -f .claude/reports/latest/logs/audit.log     # log de ejecución
.claude/scripts/diff_runs.sh [RUN_A RUN_B]        # cambios de exposición (por defecto, los dos últimos)
# verificación (no hay tests): sintaxis y lint
cd .claude/scripts && for f in *.sh lib/common.sh; do /bin/bash -n "$f"; done && shellcheck -x -S warning *.sh lib/common.sh
```
Puertos por defecto: `80,443,3000,5000,5173,7000,8000,8080,8443`. Un run tarda ~30 s (dominan `nmap -sV` y `-p 1-10000`) y cada puerto abierto añade ~18 s por `nse.sh` y ~5 s por el timeout de HTTPS si no hay TLS.

## Arquitectura
`audit.sh` es solo el orquestador: valida host y puertos, crea `reports/<ts>/` (con sufijo `-N` si el timestamp existe) y llama a los demás en este orden. El symlink `latest` se actualiza **al final**.

| Script | Argumentos | Qué hace / salida en `logs/` |
|---|---|---|
| `sockets.sh` | `LOGS` | sockets en escucha de todo el sistema y estado del cortafuegos: `listening.txt`, `netstat_listen.txt`, `firewall.txt` |
| `ports.sh` | `HOST PUERTOS LOGS` | `ncat -z` + nmap: `ncat_ports.txt`, `open_ports.txt`, `nmap_*.txt` |
| `owners.sh` | `LOGS` | proceso dueño y exposición (`EXPUESTO` vs `loopback`): `owners.txt` |
| `containers.sh` | `LOGS` | Docker con puertos publicados (opcional, `--containers`): `containers.txt` |
| `http.sh` | `HOST PUERTO LOGS` | `port_N/`: banner, cabeceras, `scheme.txt` (`http`, `https` o `none`: primer esquema que respondió), `methods.txt` (GET/HEAD/OPTIONS/TRACE + `Allow`) y `paths.txt`, ambos solo por ese esquema |
| `tls.sh` | `HOST PUERTO LOGS` | certificado en `port_N/tls_cert.txt`; solo si https respondió (requiere `http.sh`) |
| `cookies_cors.sh` | `HOST PUERTO LOGS` | `port_N/web_checks.txt`: versión, cookies (atributos, no el nombre), CORS, redirecciones; usa `scheme.txt` (requiere `http.sh`) |
| `nse.sh` | `HOST PUERTO LOGS` | nmap con lista blanca NSE de solo lectura (con `+`, se fuerzan aunque nmap no vea http): `port_N/nse.txt` |
| `diff_runs.sh` | `[A B]` | diferencias (`ncat_ports`, `owners`, `listening`) entre runs (opcional, `--diff`): `diff_prev.txt` |
| `report.sh` | `RUN_DIR HOST PUERTOS` | arma `report.md` a partir de `logs/` |

`lib/common.sh` (se carga con `.`) ofrece `log`, `require_loopback`, `validate_ports` (lista CSV 1-65535, sin ceros a la izquierda) y `url_host` (IPv6 entre corchetes). Cada script se puede ejecutar por separado y revalida host y puertos. `report.sh` depende de los nombres de fichero de `logs/port_N/`: una comprobación nueva debe escribir ahí y añadir su sección a `report.sh`.

## Herramientas
Inventario completo con rutas y comprobación de `PATH`: `.claude/notes/tools.md`. Resumen:
- **Usadas por los scripts**: `ncat`, `nmap` (siempre `-Pn` en loopback), `curl`, `openssl` (resuelve al de miniconda 3.4.1, no al de macOS), `lsof`, `netstat`, `docker`.
- **Instaladas, de uso manual** (no integradas en `audit.sh`), solo contra loopback: `testssl.sh` (el binario lleva `.sh`), `sslscan`, `nikto` (sin tuning intrusivo: evitar 4, 5, 6, 8, 9, 0), `mitmproxy`/`mitmdump`/`mitmweb` (no instalar su CA en el sistema sin preguntar), `shellcheck`.
- **Nativas de macOS** (solo lectura): `nettop`, `socketfilterfw` (ruta completa, fuera del `PATH`; cortafuegos activado), `scutil`, `networksetup`, `csrutil`, `spctl`, `codesign`, `launchctl`. `pfctl` y `tcpdump` requieren root: no usar.
- **Trampas**: `nc` de macOS (BSD) no equivale a `ncat`; el `httpx` de miniconda es la librería de Python y no funciona; macOS no trae `timeout` (usar `gtimeout`); `/bin/bash` es 3.2.
- **No instaladas** (pendientes, prioridad baja, en `request_install.md`): `mkcert`, `lynis`, `trivy`, `socat`. **No recomendadas**: `ffuf`, `gobuster`, `hydra`, `nuclei` intrusivo.

## Estado conocido (run 2026-11-15; puede haber cambiado)
- No hay servidor web de desarrollo: 80, 443, 3000, 5173, 8000, 8080 y 8443 cerrados.
- `*:5000` y `*:7000` los ocupa `ControlCenter`, el **receptor AirPlay de macOS** (`Server: AirTunes/…`): `403` uniforme a todo método y ruta; nmap los etiqueta mal (`rtsp`, `upnp`, `afs3-fileserver`). Escuchan en **todas las interfaces**, accesibles desde la LAN. Mitigación: Ajustes del Sistema → General → AirDrop y Handoff → desactivar «Receptor de AirPlay».
- `rapportd` (Continuity/Handoff) en `*:49153`, fuera del rango web.
- Si una app no arranca en 5000 (Flask) o 7000, es por AirPlay.
- Colima/Docker está parado; `containers.sh` lo anota y sigue.

## Interpretar informes
- «Rutas sensibles» muestra todo lo que no sea 404/000. En AirPlay todo es 403 uniforme: falso positivo. Un 200/301/302 en `/.env`, `/.git/*`, `/admin`, etc. sí es relevante.
- «Cabeceras de seguridad ausentes» solo tiene sentido con respuestas reales; las 403 vacías las disparan todas.
- `timing_https.txt` con `code=000` y 5 s = el puerto no habla TLS; esperado en HTTP plano.
- Con una app real revisar además: `Server`/`X-Powered-By`, `TRACE` ≠ 405/403, métodos de escritura en `Allow`, cookies sin `HttpOnly`/`Secure`/`SameSite`, CORS `*` o que refleje el `Origin`, listado de directorios.

## Procedimiento «recomienda»
Cuando el usuario pida recomendaciones (solo lectura; no ejecuta nada nuevo contra la red):
1. Leer `latest_report.md` y, si hace falta, la evidencia cruda de `.claude/reports/latest/logs/`. Si no hay informe, o es antiguo respecto a lo que se pregunta, ofrecer ejecutar `audit.sh` (solo loopback) en lugar de recomendar a ciegas.
2. Aplicar «Interpretar informes»: descartar falsos positivos conocidos (AirPlay 5000/7000, 403 uniforme, `code=000` en HTTPS sin TLS) y decir que se descartan, no omitirlos.
3. Comparar con el run anterior (`logs/diff_prev.txt` o `diff_runs.sh`) y destacar lo nuevo o lo que ha cambiado.
4. Escribir `.claude/reports/latest/recommendations.md` (en español, Markdown) con estas secciones:
   - **Resumen**: run analizado, objetivo y veredicto en una frase.
   - **Recomendaciones**: tabla `Prioridad (Alta/Media/Baja) | Hallazgo | Evidencia (fichero de logs) | Acción | Esfuerzo`, ordenada por prioridad. Una exposición a la LAN o un 200/301/302 en `/.env`, `/.git/*` o `/admin` es Alta; cabeceras o cookies, Media; el resto, Baja.
   - **Falsos positivos descartados**.
   - **Fuera de alcance / pendiente**: lo que requeriría tocar algo que no sea loopback, instalar herramientas o `sudo` (solo mencionarlo, pedir confirmación antes de hacerlo).
5. Cada recomendación cita su evidencia y propone una acción concreta y reversible; no aplicar cambios de configuración del sistema sin que el usuario lo pida.
6. Comprobar que el symlink `latest_recommendations.md` de la raíz resuelve (`ls -lL`); recrearlo con `ln -sfn .claude/reports/latest/recommendations.md latest_recommendations.md` si falta. No commitear `reports/` (ignorado por git).
7. Responder con un resumen corto y la ruta `latest_recommendations.md`, sin repetir el fichero entero.

## Convenciones al editar
- Bash compatible con 3.2, con `set -u` y **sin** `-e` (una herramienta que falle no debe abortar el resto). Con `set -u`, no expandir arrays posiblemente vacíos (`"${A[@]}"`); leer listas de ficheros con `while read … <&3`.
- Constantes en mayúsculas; toda salida de progreso por `log`; entrada validada con `require_loopback` y `validate_ports`; siempre entrecomillar variables.
- Cada comprobación nueva deja su salida cruda en `logs/` y un resumen en `report.md`; mensajes e informes en español, Markdown con bloques ``` por sección.
- Pasar `shellcheck -x -S warning` antes de dar un cambio por bueno.
- Temporales y scripts de prueba van al scratchpad, nunca a `reports/`. Si una prueba crea un run, borrarlo y restaurar `latest`.
- Al cambiar scripts, permisos o herramientas, actualizar este fichero y `.claude/notes/tools.md`.

## Pendiente
- Primera auditoría real: seguir `.claude/notes/first-audit-checklist.md`.
- Probar `cookies_cors.sh`, `nse.sh` y `tls.sh` contra una app real (probados solo con servidores de prueba http/https y AirPlay).
- Hallazgos de revisión aún sin arreglar: `tls.sh` sin timeout ni comprobación previa, `owners.sh` omite puertos que `lsof` no ve, cabecera de `audit.sh` desactualizada, regla `ask` de `audit.sh` que tapa los `allow`, solapamiento de `nse.sh` con otros scripts.
- Integrar `testssl.sh`/`sslscan`/`nikto` en `audit.sh` (opcionales por flag).
- Modo `--watch` con `ncat`/`cron` para disponibilidad periódica en `.claude/reports/uptime.log`.
