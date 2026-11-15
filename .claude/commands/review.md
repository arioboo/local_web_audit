---
description: Review the current diff
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(shellcheck:*), Bash(bash -n:*), Read, Grep
---
Review the current uncommitted diff (`git diff HEAD`). Use the `reviewer` subagent for changes under `.claude/scripts/`. Report problems ordered by severity. $ARGUMENTS
