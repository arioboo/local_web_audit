# AGENTS.md — local_web_audit

Lightweight pentesting and status review of the local web, on macOS (Darwin arm64). Reconnaissance and configuration checks only. Language: see "Language and format".

## Scope and rules (important)
- **Loopback only**: `127.0.0.1`, `localhost`, `::1`. Every script in `.claude/scripts/` checks it with `require_loopback`; do not relax that check.
- **Forbidden**: DoS, mass fuzzing, credential brute force, scanning the LAN or external hosts, active exploitation, requests with side effects (POST/PUT/DELETE/PATCH against a real app).
- **Ask for confirmation** before pointing any tool at a non-loopback target, even if the user suggests it in passing. `lan/` and `web/` are reserved and out of scope.
- **Install nothing** (`brew`) and do not use `sudo` without asking. `.claude/settings.json` blocks `brew install/upgrade`.
- AirPlay findings on `*:5000`/`*:7000` are known false positives (see "Reading reports").

## Structure
```
AGENTS.md            single source of instructions (CLAUDE.md only contains `@AGENTS.md`)
latest_report.md     relative symlink → .claude/reports/latest/report.md (latest report; follows `latest`)
latest_recommendations.md  relative symlink → .claude/reports/latest/recommendations.md (latest run's recommendations)
requirements.txt     no pip dependencies (comments only); system tools are listed under "Tools"; `bundle.py` uses only the Python standard library
README.md            user guide (scope, usage, how to read the report); keep aligned with this file
localhost/           loopback notes and manual tests (empty)
lan/  web/           reserved, empty, out of scope
.mcp.json            MCP servers (empty)
.github/             CI (bash -n + shellcheck), issue/PR templates, CODEOWNERS, dependabot
.claude/
  settings.json      project permissions (allow/ask/deny) and hooks; settings.local.json (personal, ignored)
  agents/ commands/ skills/ rules/ hooks/ output-styles/   reviewer/explorer, /review /commit /pr /bundle, rules, pre-bash-guard and post-edit-format
  recommendations/   toolset.md, guia_gh_github.md (gh and GitHub quick guide) and other recommendations/guides (Spanish)
  scripts/           audit, one script per utility (+ lib/common.sh); bundle.py + bundle_template.html build the bundle page
  reports/<ts>/      one run: report.md + logs/ (raw evidence); `latest` → latest run
  reports/bundle.html   local bundle page (git-ignored), published as the container artifact
  notes/             tools.md (tools and PATH), review-2026-11-15.md, first-audit-checklist.md, decisions.md, todo.md, artifact.md
```
- `/Users/arl94/Claude/local_web_audit` is a symlink to this directory; printed paths may come out under either.
- Outside the project: `/Users/arl94/Projects/request_install.md` (tools pending installation).
- Git repo with remote `origin` (`arioboo/local_web_audit`), working branch `develop`. `.gitignore` excludes `reports/` (also matches `.claude/reports/`), `.DS_Store`, user-level/local files, `.claude/settings.json` and `.claude/notes/`.

## Commands
```bash
.claude/scripts/audit.sh                          # 127.0.0.1, default ports
.claude/scripts/audit.sh localhost 3000,8080      # specific ports (CSV list, no ranges)
.claude/scripts/audit.sh 127.0.0.1 3000 --diff --containers
cat latest_report.md                              # read the latest report (symlink at the root)
tail -f .claude/reports/latest/logs/audit.log     # execution log
.claude/scripts/diff_runs.sh [RUN_A RUN_B]        # exposure changes (default: the last two)
python3 -I .claude/scripts/bundle.py              # rebuild .claude/reports/bundle.html (all reports, recommendations, guides)
open .claude/reports/bundle.html                  # open the bundle locally (always do this after a rebuild)
# verification (no tests): syntax and lint
cd .claude/scripts && for f in *.sh lib/common.sh; do /bin/bash -n "$f"; done && shellcheck -x -S warning *.sh lib/common.sh
```
Default ports: `80,443,3000,5000,5173,7000,8000,8080,8443`. A run takes ~30 s (`nmap -sV` and `-p 1-10000` dominate) and each open port adds ~18 s for `nse.sh` and ~5 s for the HTTPS timeout when there is no TLS.

## Architecture
`audit.sh` is only the orchestrator: it validates host and ports, creates `reports/<ts>/` (with a `-N` suffix if the timestamp exists) and calls the others in this order. The `latest` symlink is updated **at the end**.

| Script | Arguments | What it does / output in `logs/` |
|---|---|---|
| `sockets.sh` | `LOGS` | system-wide listening sockets and firewall state: `listening.txt`, `netstat_listen.txt`, `firewall.txt` |
| `ports.sh` | `HOST PORTS LOGS` | `ncat -z` + nmap: `ncat_ports.txt`, `open_ports.txt`, `nmap_*.txt` |
| `owners.sh` | `LOGS` | owning process and exposure (`EXPUESTO` vs `loopback`): `owners.txt` |
| `containers.sh` | `LOGS` | Docker with published ports (optional, `--containers`): `containers.txt` |
| `http.sh` | `HOST PORT LOGS` | `port_N/`: banner, headers, `scheme.txt` (`http`, `https` or `none`: first scheme that answered), `methods.txt` (GET/HEAD/OPTIONS/TRACE + `Allow`) and `paths.txt`, both over that scheme only |
| `tls.sh` | `HOST PORT LOGS` | certificate in `port_N/tls_cert.txt`; only if https answered (requires `http.sh`) |
| `cookies_cors.sh` | `HOST PORT LOGS` | `port_N/web_checks.txt`: version, cookies (attributes, not the name), CORS, redirects; uses `scheme.txt` (requires `http.sh`) |
| `nse.sh` | `HOST PORT LOGS` | nmap with a read-only NSE allowlist (with `+`, forced even if nmap does not see http): `port_N/nse.txt` |
| `diff_runs.sh` | `[A B]` | differences (`ncat_ports`, `owners`, `listening`) between runs (optional, `--diff`): `diff_prev.txt` |
| `report.sh` | `RUN_DIR HOST PORTS` | builds `report.md` from `logs/` |
| `bundle.py` | none | Python (stdlib only, not part of `audit.sh`): converts every `.claude/recommendations/*.md` and `reports/*/{report,recommendations}.md` into `reports/bundle.html` using `bundle_template.html` |

`lib/common.sh` (sourced with `.`) provides `log`, `require_loopback`, `validate_ports` (CSV list 1-65535, no leading zeros) and `url_host` (IPv6 in brackets). Each script can run on its own and revalidates host and ports. `report.sh` depends on the file names under `logs/port_N/`: a new check must write there and add its section to `report.sh`.

## Tools
Full inventory with paths and `PATH` check: `.claude/notes/tools.md`. Summary:
- **Used by the scripts**: `ncat`, `nmap` (always `-Pn` on loopback), `curl`, `openssl` (resolves to miniconda's 3.4.1, not macOS's), `lsof`, `netstat`, `docker`.
- **Installed, manual use** (not integrated in `audit.sh`), loopback only: `testssl.sh` (the binary has the `.sh`), `sslscan`, `nikto` (no intrusive tuning: avoid 4, 5, 6, 8, 9, 0), `mitmproxy`/`mitmdump`/`mitmweb` (do not install its CA system-wide without asking), `shellcheck`.
- **macOS native** (read-only): `nettop`, `socketfilterfw` (full path, outside `PATH`; firewall on), `scutil`, `networksetup`, `csrutil`, `spctl`, `codesign`, `launchctl`. `pfctl` and `tcpdump` need root: do not use.
- **Gotchas**: macOS `nc` (BSD) is not `ncat`; miniconda's `httpx` is the Python library and does not work; macOS has no `timeout` (use `gtimeout`); `/bin/bash` is 3.2.
- **Not installed** (pending, low priority, in `request_install.md`): `mkcert`, `lynis`, `trivy`, `socat`. **Not recommended**: `ffuf`, `gobuster`, `hydra`, intrusive `nuclei`.

## Known state (run 2026-11-15; may have changed)
- There is no development web server: 80, 443, 3000, 5173, 8000, 8080 and 8443 are closed.
- `*:5000` and `*:7000` are held by `ControlCenter`, the **macOS AirPlay receiver** (`Server: AirTunes/…`): uniform `403` for every method and path; nmap mislabels them (`rtsp`, `upnp`, `afs3-fileserver`). They listen on **all interfaces**, reachable from the LAN. Mitigation: System Settings → General → AirDrop & Handoff → turn off "AirPlay Receiver".
- `rapportd` (Continuity/Handoff) on `*:49153`, outside the web range.
- If an app fails to start on 5000 (Flask) or 7000, AirPlay is the cause.
- Colima/Docker is stopped; `containers.sh` notes it and moves on.

## Reading reports
Reports are generated in Spanish; section names below are quoted as they appear.
- "Rutas sensibles" shows everything that is not 404/000. On AirPlay everything is a uniform 403: false positive. A 200/301/302 on `/.env`, `/.git/*`, `/admin`, etc. is relevant.
- "Cabeceras de seguridad ausentes" only makes sense with real responses; empty 403s trigger all of them.
- `timing_https.txt` with `code=000` and 5 s = the port does not speak TLS; expected on plain HTTP.
- With a real app also review: `Server`/`X-Powered-By`, `TRACE` ≠ 405/403, write methods in `Allow`, cookies without `HttpOnly`/`Secure`/`SameSite`, CORS `*` or reflecting the `Origin`, directory listing.

## "recomienda" procedure
When the user asks for recommendations (read-only; runs nothing new against the network):
1. Read `latest_report.md` and, if needed, the raw evidence in `.claude/reports/latest/logs/`. If there is no report, or it is old relative to the question, offer to run `audit.sh` (loopback only) instead of recommending blind.
2. Apply "Reading reports": discard known false positives (AirPlay 5000/7000, uniform 403, `code=000` on HTTPS without TLS) and say they are discarded, do not omit them.
3. Compare with the previous run (`logs/diff_prev.txt` or `diff_runs.sh`) and highlight what is new or changed.
4. Write `.claude/reports/latest/recommendations.md` (in Spanish, Markdown) with these sections:
   - **Resumen**: run analysed, target and a one-sentence verdict.
   - **Recomendaciones**: table `Prioridad (Alta/Media/Baja) | Hallazgo | Evidencia (fichero de logs) | Acción | Esfuerzo`, ordered by priority. LAN exposure or a 200/301/302 on `/.env`, `/.git/*` or `/admin` is Alta; headers or cookies, Media; the rest, Baja.
   - **Falsos positivos descartados**.
   - **Fuera de alcance / pendiente**: whatever would require touching anything non-loopback, installing tools or `sudo` (only mention it, ask before doing it).
5. Each recommendation cites its evidence and proposes a concrete, reversible action; do not apply system configuration changes unless the user asks.
6. Check that the root symlink `latest_recommendations.md` resolves (`ls -lL`); recreate it with `ln -sfn .claude/reports/latest/recommendations.md latest_recommendations.md` if missing. Do not commit `reports/` (git-ignored).

## Editing conventions
- Bash 3.2 compatible, with `set -u` and **without** `-e` (a failing tool must not abort the rest). Under `set -u`, do not expand possibly empty arrays (`"${A[@]}"`); read file lists with `while read … <&3`.
- Constants in upper case; all progress output through `log`; input validated with `require_loopback` and `validate_ports`; always quote variables.
- Each new check leaves its raw output in `logs/` and a summary in `report.md`; reports and the evidence text that feeds them stay in Spanish, Markdown with ``` blocks per section.
- Pass `shellcheck -x -S warning` before calling a change good.
- Temp files and test scripts go to the scratchpad, never to `reports/`. If a test creates a run, delete it and restore `latest`.
- When changing scripts, permissions or tools, update this file and `.claude/notes/tools.md`.

## Language and format
- English: all code (including script comments, usage and `log` messages), this file, `README.md`, everything under `.claude/` except reports and recommendations, `.github/`, and every git/GitHub operation (commits, branches, PRs, issues).
- Spanish: reports (`.claude/reports/`, including the evidence text the scripts write into `logs/` and `report.sh` output) and recommendations (`.claude/recommendations/`), and replies to the user.
- Markdown by default; PDF or DOCX only on request.

## Bundle and artifact
- The container artifact gathers every report, recommendation and guide in one page (URL in `.claude/notes/artifact.md`, private).
- `/bundle` rebuilds it: run `bundle.py`, republish `.claude/reports/bundle.html` to that URL, then **always open the local HTML file** (`open .claude/reports/bundle.html`), not just the link.
- Adding a guide or recommendation: write the `.md` in `.claude/recommendations/` (Spanish), then run `/bundle`. New groups need an `add(...)` line in `bundle.py`.
- `guia_gh_github.md` covers `gh` login, branches, PRs, issues, Actions and repo safety; `gh` has no session on this machine until the user runs `! gh auth login`.

## Pending
- First real audit: follow `.claude/notes/first-audit-checklist.md`.
- Test `cookies_cors.sh`, `nse.sh` and `tls.sh` against a real app (tested only with test http/https servers and AirPlay).
- Review findings still unfixed: `tls.sh` has no timeout or pre-check, `owners.sh` skips ports `lsof` cannot see, stale `audit.sh` header, the `audit.sh` `ask` rule that shadows the `allow` rules, `nse.sh` overlap with other scripts. Also: `pre-bash-guard.sh` matches substrings anywhere in the command (too broad).
- `bundle.py` has a hand-written Markdown converter (headings, tables, lists, code, bold/inline code only); switch to a library if richer Markdown is needed.
- Integrate `testssl.sh`/`sslscan`/`nikto` into `audit.sh` (optional via flag).
- `--watch` mode with `ncat`/`cron` for periodic availability in `.claude/reports/uptime.log`.
