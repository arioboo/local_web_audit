---
description: Rebuild the bundle (local HTML + container artifact) with all reports, recommendations and guides
allowed-tools: Bash(python3 -I .claude/scripts/bundle.py), Bash(open .claude/reports/bundle.html), Read, Artifact
---
1. Run `python3 -I .claude/scripts/bundle.py`. It reads `.claude/recommendations/*.md` (guides and recommendations) and every `.claude/reports/*/report.md` and `recommendations.md`, newest first, and writes `.claude/reports/bundle.html` (git-ignored).
2. Republish that file to the artifact URL stored in `.claude/notes/artifact.md` (pass it as `url`).
3. ALWAYS open the local file afterwards: `open .claude/reports/bundle.html`.
4. If the user asks for PDF or DOCX, convert the Markdown sources too and report the paths.
$ARGUMENTS
