---
description: Open a pull request from the current branch, in English
argument-hint: "[base branch]"
allowed-tools: Bash(git log:*), Bash(git diff:*), Bash(git push:*), Bash(gh pr create:*)
---
Summarize the commits of the current branch against `${ARGUMENTS:-main}` and open a PR with `gh pr create`. Title and body in English: summary, changes, how to test, and the checks run (`bash -n`, `shellcheck`). Ask before pushing.
