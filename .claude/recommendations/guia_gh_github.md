# Guía rápida de `gh` y GitHub

Guía corta para este repo (`arioboo/local_web_audit`, rama de trabajo `develop`, remoto `origin` por SSH). Los comandos que escriben en GitHub (`push`, `pr create`, `repo create`) están en `ask` en `settings.json`: Claude pide confirmación antes de lanzarlos.

## 1. Iniciar sesión (una vez)
Ya hay sesión iniciada como `arioboo` (2026-11-15, scopes `repo`, `read:org`, `gist`). Si caduca o cambias de máquina, escribe en el prompt de Claude Code:

```
! gh auth login
```
Elige GitHub.com y entrar con el navegador (código de un solo uso). Comprueba con `gh auth status`. El `push` va por SSH (remoto `origin`) y no depende de `gh`; la sesión hace falta para PRs, issues, Actions y crear repos.

## 2. Flujo de ramas
- `main`: estable. `develop`: trabajo diario. Ramas cortas para cambios concretos: `feat/...`, `fix/...`, `chore/...` (en inglés).
- Commits convencionales en inglés (`feat: ...`, `fix: ...`, `chore: ...`). Claude los redacta con `/commit`.

## 3. Pull requests
```bash
git push -u origin develop                          # subir la rama
gh pr create --base main --head develop --fill      # abrir PR (o /pr en Claude)
gh pr status                                        # estado de tus PRs
gh pr checks                                        # resultado de la CI
gh pr merge --squash --delete-branch                # fusionar cuando la CI esté en verde
```
La plantilla `.github/PULL_REQUEST_TEMPLATE.md` se aplica sola. Marca la lista de comprobaciones (`bash -n`, `shellcheck`, alcance solo-loopback).

## 4. Issues
```bash
gh issue create --title "..." --body "..."          # o con las plantillas: gh issue create --web
gh issue list --label bug
gh issue close N --reason completed
```
Hay plantillas de bug y de mejora en `.github/ISSUE_TEMPLATE/`.

## 5. Actions (CI)
`.github/workflows/ci.yml` ejecuta `bash -n` y `shellcheck` en cada `push` y `pull_request`.
```bash
gh run list --limit 5          # últimas ejecuciones
gh run watch                   # seguir una en vivo
gh run view --log-failed       # ver solo el log de lo que falló
```

## 6. Dependabot y CODEOWNERS
- `dependabot.yml` revisa cada semana las versiones de las acciones de GitHub y abre PRs.
- `CODEOWNERS` (`* @arioboo`) te pide revisión en todos los PRs.

## 7. Seguridad del repo
- **Nunca subas evidencia cruda** de `.claude/reports/` (está en `.gitignore`): puede incluir banners, rutas y datos de tu máquina.
- Secretos: no los pongas en ficheros ni en Actions en claro; usa `gh secret set NOMBRE`.
- Protección de `main` (opcional, a petición): en GitHub, Settings → Rules → Rulesets, exigiendo PR y la CI en verde.
- Visibilidad: el repo es privado por defecto; cambia solo con una decisión explícita (`gh repo edit --visibility ...`).

## 8. Útiles
```bash
gh repo view --web             # abrir el repo en el navegador
gh browse                      # igual, o `gh browse path/al/fichero`
gh api user -q .login          # tu usuario de GitHub
gh alias set co 'pr checkout'  # atajos propios
```

## Con Claude en este proyecto
- `/commit` → commit convencional del staged; `/pr` → abre el PR en inglés; `/review` → revisa el diff.
- Claude nunca hace `push --force` (lo bloquea `pre-bash-guard`) ni sube nada sin tu confirmación.
