#!/bin/bash
# PreToolUse: Bash (git commit)
# コミット前レビューチェックをブロックで強制する

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

[[ "$COMMAND" == *"git commit"* ]] || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/skills"

PROJECT_HASH=$(echo "$PWD" | md5 -q 2>/dev/null || echo "$PWD" | md5sum | cut -c1-8)
FLAG="/tmp/wp-review-ok-${PROJECT_HASH}"

if [ ! -f "$FLAG" ]; then
  echo "⛔ コミット前チェック未完了" >&2
  echo "" >&2
  if [[ -f "$SKILLS_DIR/adversarial-reviewer/key-rules.md" ]]; then
    cat "$SKILLS_DIR/adversarial-reviewer/key-rules.md" >&2
  fi
  echo "" >&2
  echo "確認完了後: touch $FLAG" >&2
  echo "その後 git commit を再実行してください" >&2
  exit 2
fi

rm "$FLAG"
echo "[pre-commit] レビュー確認済み。コミットを続行します。"
exit 0
