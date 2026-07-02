#!/bin/bash
# PreToolUse: Bash (git commit)
# コミット前レビューチェックをブロックで強制する

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

[[ "$COMMAND" == *"git commit"* ]] || exit 0

PROJECT_HASH=$(echo "$PWD" | md5 -q 2>/dev/null || echo "$PWD" | md5sum | cut -c1-8)
FLAG="/tmp/wp-review-ok-${PROJECT_HASH}"

if [ ! -f "$FLAG" ]; then
  echo "⛔ コミット前チェック未完了" >&2
  echo "" >&2
  echo "=== [adversarial-reviewer] 確認必須項目 ===" >&2
  echo "□ ロジック: 条件の逆転・nullチェック漏れ・オフバイワンはないか" >&2
  echo "□ セキュリティ: エスケープ・nonce・権限チェックはすべて揃っているか" >&2
  echo "□ WordPress: prepare()なしのSQLはないか。プレフィックスは付いているか" >&2
  echo "□ 型安全: 型宣言・戻り値型・phpstan がパスするか（composer run phpstan <target>）" >&2
  echo "" >&2
  echo "確認完了後: touch $FLAG" >&2
  echo "その後 git commit を再実行してください" >&2
  exit 2
fi

rm "$FLAG"
echo "[pre-commit] レビュー確認済み。コミットを続行します。"
exit 0
