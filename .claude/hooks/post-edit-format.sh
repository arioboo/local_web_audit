#!/usr/bin/env bash
# PostToolUse(Edit|Write): lint edited shell scripts; never fails the edit.
set -u
f=$(jq -r '.tool_input.file_path // empty' 2>/dev/null)
case "$f" in
  *.sh) /bin/bash -n "$f" 2>&1 >&2 ; command -v shellcheck >/dev/null && shellcheck -x -S warning "$f" >&2 ;;
esac
exit 0
