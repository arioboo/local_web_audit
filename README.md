# local_web_audit

Un kit pequeño para echar un vistazo rápido a lo que tu Mac está sirviendo en local: qué puertos hay abiertos, quién los tiene, qué responde cada uno y si algo huele raro. Es pentesting ligero, solo reconocimiento y comprobaciones de configuración. No rompe nada ni explota nada.

## Qué hace (y qué no)

- **Solo loopback**: `127.0.0.1`, `localhost` y `::1`. Si pasas otro host, los scripts se niegan a ejecutarse. Es a propósito.
- **Solo lectura**: peticiones `GET`, `HEAD`, `OPTIONS` y `TRACE`. Nada de `POST`/`PUT`/`DELETE`, fuzzing, fuerza bruta ni DoS.
- **No instala nada** ni pide `sudo`.

## Requisitos

macOS con `bash` 3.2, y `ncat`, `nmap`, `curl`, `openssl`, `lsof` y `netstat` en el `PATH`. `docker` es opcional y solo hace falta con `--containers`. Para desarrollar, `shellcheck`.

## Uso rápido

```bash
.claude/scripts/audit.sh                          # 127.0.0.1 con los puertos por defecto
.claude/scripts/audit.sh localhost 3000,8080      # puertos concretos (lista CSV, sin rangos)
.claude/scripts/audit.sh 127.0.0.1 3000 --diff --containers
cat latest_report.md                              # leer el último informe
```

Puertos por defecto: `80,443,3000,5000,5173,7000,8000,8080,8443`.
Un run tarda unos 30 s, más unos 20 s por cada puerto abierto (el análisis NSE es lo que más pesa).

| Flag | Efecto |
|---|---|
| `--diff` | compara con el run anterior y anota los cambios de exposición |
| `--containers` | añade los contenedores Docker con puertos publicados |

Para comparar dos runs cualesquiera: `.claude/scripts/diff_runs.sh [RUN_A RUN_B]` (por defecto, los dos últimos).

## Qué te llevas

Cada run crea `.claude/reports/<timestamp>/` con:

- `report.md`: el informe legible, con una sección por comprobación.
- `logs/`: la evidencia cruda (salida de `nmap`, `curl`, certificados, etc.) y `audit.log` para seguir la ejecución con `tail -f`.

Dos atajos en la raíz siempre apuntan al último run:

- `latest_report.md`: el informe.
- `latest_recommendations.md`: recomendaciones priorizadas. Se generan a petición (ver `AGENTS.md`, «Procedimiento "recomienda"»).

Estos enlaces se rompen si aún no hay ningún run: ejecuta `audit.sh` una vez y se arreglan solos. `reports/` está en `.gitignore`.

## Cómo leer el informe

Fíjate sobre todo en:

- **Dueño del puerto**: `EXPUESTO(todas-las-interfaces)` significa que escucha en `*`, y por tanto es accesible desde tu red, no solo desde tu máquina.
- **Cabeceras, métodos y cookies**: `Server`/`X-Powered-By` que filtren versión, `TRACE` que no devuelva 405/403, métodos de escritura en `Allow`, cookies sin `HttpOnly`/`Secure`/`SameSite`, CORS `*` o que refleje el `Origin`.
- **Rutas sensibles**: un `200`/`301`/`302` en `/.env`, `/.git/*` o `/admin` merece atención inmediata.

### Falsos positivos conocidos

En macOS, los puertos `5000` y `7000` los ocupa **ControlCenter**, el receptor AirPlay (`Server: AirTunes/…`). Responde `403` a todo, así que el informe marcará todas las rutas como «sensibles» y todas las cabeceras de seguridad como ausentes. Es ruido. Además, nmap los etiqueta mal (`rtsp`, `upnp`). Escuchan en todas las interfaces; si no usas AirPlay, desactiva «Receptor de AirPlay» en Ajustes del Sistema → General → AirDrop y Handoff.

Otro: `code=000` con 5 s en HTTPS solo significa que el puerto no habla TLS.

## Cómo está montado

`audit.sh` es el orquestador. Llama, en orden, a un script por utilidad (`sockets`, `ports`, `owners`, `http`, `tls`, `cookies_cors`, `nse`, `report`...). Todos viven en `.claude/scripts/`, comparten `lib/common.sh` y se pueden ejecutar por separado: cada uno revalida host y puertos por su cuenta. Si añades una comprobación, deja su salida cruda en `logs/` y su resumen en `report.sh`.

Antes de tocar scripts:

```bash
cd .claude/scripts && for f in *.sh lib/common.sh; do /bin/bash -n "$f"; done && shellcheck -x -S warning *.sh lib/common.sh
```

Las reglas de alcance y las convenciones completas están en [`AGENTS.md`](AGENTS.md).
