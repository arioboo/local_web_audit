# Toolset de mejora

Estado a 2026-11-15, comprobado con `command -v`. No se instala nada sin tu aprobación (la instalación con Homebrew está bloqueada en `settings.json`).

| Categoría | Herramienta | Para qué | Esfuerzo | Estado |
|---|---|---|---|---|
| Lint | `shellcheck` | lint de los scripts (`-x -S warning`) | Bajo | instalada |
| Formato | `shfmt` | formato uniforme de bash | Bajo | pendiente |
| Tests | `bats-core` | pruebas automáticas de `common.sh` (`validate_ports`, `require_loopback`) | Medio | pendiente |
| CI | GitHub Actions + `actionlint` | ejecutar `bash -n` y `shellcheck` en cada PR | Bajo | workflow creado; `actionlint` pendiente |
| Secretos | `gitleaks` | evitar commitear credenciales o evidencia con datos sensibles | Bajo | pendiente |
| Hooks git | `pre-commit` | lanzar lint y gitleaks antes de cada commit | Bajo | pendiente |
| Auditoría TLS | `testssl.sh`, `sslscan` | revisión TLS manual; integrar en `audit.sh` con flag | Medio | instaladas, no integradas |
| Auditoría web | `nikto` | revisión web manual (sin tuning intrusivo) | Medio | instalada, no integrada |
| Proxy | `mitmproxy` | inspección de tráfico local | Bajo | instalada |
| Endurecimiento | `lynis` | auditoría del propio macOS (parte requiere `sudo`) | Medio | pendiente (`request_install.md`) |
| Contenedores | `trivy` | vulnerabilidades en imágenes y dependencias | Medio | pendiente; útil solo con Docker en marcha |
| Certificados | `mkcert` | HTTPS local de confianza para pruebas (`-install` pide admin) | Bajo | pendiente |
| Red | `socat` | alternativa a `ncat` para reenvíos de prueba | Bajo | pendiente |
| Claude | hooks `pre-bash-guard` y `post-edit-format` | bloquear comandos peligrosos y lintar al editar | Bajo | creados |
| Claude | subagentes `reviewer` y `explorer` | revisión del diff y búsqueda en runs pasados | Bajo | creados |
| Claude | comandos `/review`, `/commit`, `/pr`, `/bundle` | flujo de trabajo y artefacto contenedor | Bajo | creados |
| MCP | ninguno necesario | `.mcp.json` vacío; añadir solo si hace falta | - | vacío |

## Orden sugerido
1. `shfmt`, `gitleaks` y `pre-commit` (bajo esfuerzo, mejoran cada commit).
2. `bats-core` para cubrir `lib/common.sh`, lo que más protege el alcance solo-loopback.
3. Integrar `testssl.sh`, `sslscan` y `nikto` en `audit.sh` con flags (ya en «Pendiente» de `AGENTS.md`).
4. Pendientes de baja prioridad (`lynis`, `trivy`, `mkcert`, `socat`) solo si surge la necesidad.
