# local_web_audit

A small kit to take a quick look at what your Mac is serving locally: which ports are open, who owns them, what each one answers and whether anything looks off. It is lightweight pentesting: reconnaissance and configuration checks only. It breaks nothing and exploits nothing.

## What it does (and does not)

- **Loopback only**: `127.0.0.1`, `localhost` and `::1`. If you pass any other host, the scripts refuse to run. This is on purpose.
- **Read-only**: `GET`, `HEAD`, `OPTIONS` and `TRACE` requests. No `POST`/`PUT`/`DELETE`, fuzzing, brute force or DoS.
- **Installs nothing** and never asks for `sudo`.

## Requirements

macOS with `bash` 3.2, and `ncat`, `nmap`, `curl`, `openssl`, `lsof` and `netstat` in the `PATH`. `docker` is optional and only needed with `--containers`. For development, `shellcheck`.

## Quick start

```bash
.claude/scripts/audit.sh                          # 127.0.0.1 with the default ports
.claude/scripts/audit.sh localhost 3000,8080      # specific ports (CSV list, no ranges)
.claude/scripts/audit.sh 127.0.0.1 3000 --diff --containers
cat latest_report.md                              # read the latest report
```

Default ports: `80,443,3000,5000,5173,7000,8000,8080,8443`.
A run takes about 30 s, plus about 20 s per open port (the NSE analysis is the heaviest part).

| Flag | Effect |
|---|---|
| `--diff` | compares with the previous run and notes exposure changes |
| `--containers` | adds Docker containers with published ports |

To compare any two runs: `.claude/scripts/diff_runs.sh [RUN_A RUN_B]` (default: the last two).

## What you get

Each run creates `.claude/reports/<timestamp>/` with:

- `report.md`: the readable report, one section per check (written in Spanish).
- `logs/`: the raw evidence (`nmap`, `curl` output, certificates, etc.) and `audit.log` to follow the run with `tail -f`.

Two shortcuts at the root always point to the latest run:

- `latest_report.md`: the report.
- `latest_recommendations.md`: prioritized recommendations, generated on request (see `AGENTS.md`, "recomienda" procedure).

These links are broken until the first run: run `audit.sh` once and they fix themselves. `reports/` is in `.gitignore`.

## How to read the report

Pay particular attention to:

- **Port owner**: `EXPUESTO(todas-las-interfaces)` means it listens on `*`, so it is reachable from your network, not just your machine.
- **Headers, methods and cookies**: `Server`/`X-Powered-By` leaking versions, `TRACE` not returning 405/403, write methods in `Allow`, cookies without `HttpOnly`/`Secure`/`SameSite`, CORS `*` or reflecting the `Origin`.
- **Sensitive paths**: a `200`/`301`/`302` on `/.env`, `/.git/*` or `/admin` deserves immediate attention.

### Known false positives

On macOS, ports `5000` and `7000` are held by **ControlCenter**, the AirPlay receiver (`Server: AirTunes/…`). It answers `403` to everything, so the report will flag every path as "sensitive" and every security header as missing. That is noise. nmap also mislabels them (`rtsp`, `upnp`). They listen on all interfaces; if you do not use AirPlay, turn off "AirPlay Receiver" in System Settings → General → AirDrop & Handoff.

Another one: `code=000` with 5 s on HTTPS only means the port does not speak TLS.

## How it is built

`audit.sh` is the orchestrator. It calls, in order, one script per utility (`sockets`, `ports`, `owners`, `http`, `tls`, `cookies_cors`, `nse`, `report`...). They all live in `.claude/scripts/`, share `lib/common.sh` and can run on their own: each one revalidates host and ports by itself. If you add a check, leave its raw output in `logs/` and its summary in `report.sh`.

Before touching scripts:

```bash
cd .claude/scripts && for f in *.sh lib/common.sh; do /bin/bash -n "$f"; done && shellcheck -x -S warning *.sh lib/common.sh
```

Scope rules and full conventions are in [`AGENTS.md`](AGENTS.md).
