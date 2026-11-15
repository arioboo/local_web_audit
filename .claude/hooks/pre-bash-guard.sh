#!/usr/bin/env bash
# PreToolUse(Bash): block dangerous commands. Exit 2 blocks and shows stderr to Claude.
set -u
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0
case "$cmd" in
  *"rm -rf /"*|*"rm -rf ~"*|sudo\ *|*" sudo "*|*"git push --force"*|*"git push -f "*|*"brew install"*|*"brew upgrade"*)
    echo "Blocked by pre-bash-guard: $cmd" >&2
    exit 2 ;;
esac
exit 0
