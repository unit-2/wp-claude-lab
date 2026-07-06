#!/bin/bash
# PreToolUse: Bash (wp コマンド)
# WP-CLI 実行前の安全チェックリストを注入し、破壊的コマンドをガードする

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if [[ "$COMMAND" != *"/bin/wp "* ]] && [[ "$COMMAND" != *" wp "* ]] && [[ "$COMMAND" != "wp "* ]]; then
  exit 0
fi

# 完全にデータを失うコマンドはブロック
if [[ "$COMMAND" =~ wp[[:space:]]+db[[:space:]]+drop ]] || \
   [[ "$COMMAND" =~ wp[[:space:]]+db[[:space:]]+reset ]] || \
   [[ "$COMMAND" =~ wp[[:space:]]+site[[:space:]]+empty ]]; then
  echo "[ERROR] このコマンドはデータベースを完全に破棄します: $COMMAND" >&2
  echo "本当に必要な場合は、事前に db export でバックアップを取ってから手動で実行してください。" >&2
  exit 2
fi

# search-replace は --dry-run なしでの実行を一旦ブロックする
if [[ "$COMMAND" =~ wp[[:space:]]+search-replace ]] && [[ "$COMMAND" != *"--dry-run"* ]]; then
  echo "[ERROR] wp search-replace は --dry-run なしでは実行できません: $COMMAND" >&2
  echo "まず --dry-run で変更内容を確認してください。本実行はこのフックが必ずブロックするため、" >&2
  echo "問題なければターミナルから手動で --dry-run なしのコマンドを実行してください。" >&2
  exit 2
fi

# 元に戻しにくいが致命的ではないコマンドは警告のみ
if [[ "$COMMAND" =~ wp[[:space:]]+plugin[[:space:]]+delete ]] || \
   [[ "$COMMAND" =~ wp[[:space:]]+theme[[:space:]]+delete ]] || \
   [[ "$COMMAND" =~ wp[[:space:]]+db[[:space:]]+import ]]; then
  echo "[WARNING] このコマンドは元に戻しにくい変更を行います: $COMMAND" >&2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/skills"

[[ -f "$SKILLS_DIR/wp-wpcli-and-ops/key-rules.md" ]] && cat "$SKILLS_DIR/wp-wpcli-and-ops/key-rules.md"
exit 0
