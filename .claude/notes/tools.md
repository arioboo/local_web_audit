# Herramientas del sistema que uso

Generado el 2026-11-15 con `command -v` (macOS 27.2.1, arm64). ✅ = resuelve desde el `PATH` actual; ❌ = no está en el `PATH`.

## Con scripts y auditoría
| Herramienta | Ruta | Directorio | PATH | Otras copias en PATH | Usada en |
|---|---|---|---|---|---|
| `ncat` | `/opt/homebrew/bin/ncat` | `/opt/homebrew/bin` | ✅ | - | ports.sh, http.sh |
| `nmap` | `/opt/homebrew/bin/nmap` | `/opt/homebrew/bin` | ✅ | - | ports.sh, nse.sh |
| `curl` | `/usr/bin/curl` | `/usr/bin` | ✅ | - | http.sh, cookies_cors.sh |
| `openssl` | `/opt/miniconda3/bin/openssl` | `/opt/miniconda3/bin` | ✅ | /opt/homebrew/bin/openssl /usr/bin/openssl | tls.sh |
| `lsof` | `/usr/sbin/lsof` | `/usr/sbin` | ✅ | - | sockets.sh, owners.sh |
| `netstat` | `/usr/sbin/netstat` | `/usr/sbin` | ✅ | - | sockets.sh |
| `docker` | `/opt/homebrew/bin/docker` | `/opt/homebrew/bin` | ✅ | - | containers.sh |
| `jq` | `/usr/bin/jq` | `/usr/bin` | ✅ | - | (disponible) |
| `python3` | `/opt/miniconda3/bin/python3` | `/opt/miniconda3/bin` | ✅ | /opt/homebrew/bin/python3 /usr/bin/python3 | edición de JSON/ficheros |
| `dig` | `/usr/bin/dig` | `/usr/bin` | ✅ | - | (disponible) |
| `whois` | `/usr/bin/whois` | `/usr/bin` | ✅ | - | (disponible) |
| `nc` | `/usr/bin/nc` | `/usr/bin` | ✅ | - | (evitar; usar ncat) |
| `shellcheck` | `/opt/homebrew/bin/shellcheck` | `/opt/homebrew/bin` | ✅ | - | lint de scripts |
| `testssl.sh` | `/opt/homebrew/bin/testssl.sh` | `/opt/homebrew/bin` | ✅ | - | TLS (manual) |
| `sslscan` | `/opt/homebrew/bin/sslscan` | `/opt/homebrew/bin` | ✅ | - | TLS (manual) |
| `nikto` | `/opt/homebrew/bin/nikto` | `/opt/homebrew/bin` | ✅ | - | web (manual, loopback) |
| `mitmproxy` | `/opt/homebrew/bin/mitmproxy` | `/opt/homebrew/bin` | ✅ | - | proxy (manual) |
| `mitmdump` | `/opt/homebrew/bin/mitmdump` | `/opt/homebrew/bin` | ✅ | - | proxy (manual) |
| `mitmweb` | `/opt/homebrew/bin/mitmweb` | `/opt/homebrew/bin` | ✅ | - | proxy (manual) |
| `gtimeout` | `/opt/homebrew/bin/gtimeout` | `/opt/homebrew/bin` | ✅ | - | coreutils (macOS no trae timeout) |
| `brew` | `/opt/homebrew/bin/brew` | `/opt/homebrew/bin` | ✅ | - | instalación (pide confirmación) |

## Utilidades de shell que usan los scripts
| Herramienta | Ruta | PATH |
|---|---|---|
| `bash` | `/bin/bash` | ✅ |
| `awk` | `/usr/bin/awk` | ✅ |
| `grep` | `/usr/bin/grep` (en esta shell es alias/función) | ✅ |
| `sed` | `/usr/bin/sed` | ✅ |
| `tr` | `/usr/bin/tr` | ✅ |
| `cut` | `/usr/bin/cut` | ✅ |
| `head` | `/usr/bin/head` | ✅ |
| `tail` | `/usr/bin/tail` | ✅ |
| `cat` | `/bin/cat` | ✅ |
| `tee` | `/usr/bin/tee` | ✅ |
| `date` | `/bin/date` | ✅ |
| `mkdir` | `/bin/mkdir` | ✅ |
| `ln` | `/bin/ln` | ✅ |
| `ls` | `/bin/ls` (en esta shell es un alias con `--color=auto`) | ✅ |
| `rm` | `/bin/rm` | ✅ |
| `diff` | `/usr/bin/diff` | ✅ |
| `paste` | `/usr/bin/paste` | ✅ |
| `basename` | `/usr/bin/basename` | ✅ |
| `dirname` | `/usr/bin/dirname` | ✅ |
| `uname` | `/usr/bin/uname` | ✅ |
| `sw_vers` | `/usr/bin/sw_vers` | ✅ |
| `perl` | `/opt/homebrew/bin/perl` | ✅ |

## Nativas de macOS fuera del PATH
| Herramienta | Ruta | Existe | En PATH |
|---|---|---|---|
| `socketfilterfw` | `/usr/libexec/ApplicationFirewall/socketfilterfw` | ✅ | ❌ |
| `pfctl` | `/sbin/pfctl` | ✅ | ✅ |
| `tcpdump` | `/usr/sbin/tcpdump` | ✅ | ✅ |
| `nettop` | `/usr/bin/nettop` | ✅ | ✅ |
| `csrutil` | `/usr/bin/csrutil` | ✅ | ✅ |
| `spctl` | `/usr/sbin/spctl` | ✅ | ✅ |
| `system_profiler` | `/usr/sbin/system_profiler` | ✅ | ✅ |
| `networksetup` | `/usr/sbin/networksetup` | ✅ | ✅ |
| `scutil` | `/usr/sbin/scutil` | ✅ | ✅ |

## Observaciones
- Resumen: de 20 herramientas de auditoría, las 20 están en el `PATH`. Solo `socketfilterfw` está fuera (se invoca con ruta completa). `pfctl -s info` y `tcpdump` requieren root.
- `openssl` resuelve al de miniconda (3.4.1) y tapa al de Homebrew y al de `/usr/bin` (LibreSSL). `python3` también resuelve al de miniconda. `curl` usa LibreSSL del sistema.
- `grep` y `ls` están redefinidos en la shell interactiva (alias/función); los scripts corren sin ellos.
- `PATH` actual: `/opt/miniconda3/bin:/opt/miniconda3/condabin:/bin:/Users/arl94/.opencode/bin:/opt/homebrew/opt/openjdk/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/pkg/env/global/bin:/opt/X11/bin:/Library/Apple/usr/bin:/Library/Frameworks/Mono.framework/Versions/Current/Commands:/Applications/iTerm.app/Contents/Resources/utilities:/Users/arl94/.local/bin`
- `/bin/bash` es 3.2.57; los scripts deben funcionar con él (sin `mapfile`, cuidado con arrays vacíos bajo `set -u`).
