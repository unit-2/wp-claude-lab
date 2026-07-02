#!/bin/bash
# PreToolUse: Bash (wp コマンド)
# WP-CLI 実行前の安全チェックリストを注入する

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if [[ "$COMMAND" != *"/bin/wp "* ]] && [[ "$COMMAND" != *" wp "* ]] && [[ "$COMMAND" != "wp "* ]]; then
  exit 0
fi

echo "=== [wp-wpcli-and-ops] WP-CLI 実行前チェック ==="
echo "・本番環境では --dry-run で先に確認する"
echo "・search-replace は必ず --dry-run を先に実行する"
echo "・Local 環境では system の wp コマンドは使えない。LocalのPHPパスを使う"
echo "  → skills/wp-wpcli-and-ops/references/local-environment.md を参照"
exit 0
