#!/bin/bash
# PreToolUse: Bash (wp コマンド)
# WP-CLI 実行前の安全チェックリストを注入する

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if [[ "$COMMAND" != *"/bin/wp "* ]] && [[ "$COMMAND" != *" wp "* ]] && [[ "$COMMAND" != "wp "* ]]; then
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/skills"

[[ -f "$SKILLS_DIR/wp-wpcli-and-ops/key-rules.md" ]] && cat "$SKILLS_DIR/wp-wpcli-and-ops/key-rules.md"
exit 0
