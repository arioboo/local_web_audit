---
description: Refresh the container artifact with all reports and recommendations
allowed-tools: Read, Glob, Write, Artifact
---
1. Read the artifact URL from `.claude/notes/artifact.md` (create the artifact first if it is missing).
2. Read every `.claude/recommendations/*.md` (`toolset.md` first) and every `.claude/reports/*/report.md` and `recommendations.md` (newest first).
3. Regenerate a self-contained HTML page in the scratchpad (sidebar index, sections "Recomendaciones" and "Informes", tables and code blocks preserved) and republish it to the saved URL.
4. If the user asks for PDF or DOCX, convert the Markdown sources too and report the paths.
$ARGUMENTS
