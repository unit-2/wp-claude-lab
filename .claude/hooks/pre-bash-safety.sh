#!/bin/bash
# PreToolUse: Bash
# 危険なコマンドをブロックする安全ガード

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# rm -rf のブロック
if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f|rm\s+-[a-zA-Z]*f[a-zA-Z]*r'; then
  echo "⛔ 危険なコマンドをブロックしました: rm -rf" >&2
  echo "削除対象のパスを確認してから、必要であれば手動で実行してください。" >&2
  exit 2
fi

exit 0
