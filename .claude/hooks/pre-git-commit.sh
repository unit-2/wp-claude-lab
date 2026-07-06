#!/bin/bash
# PreToolUse: Bash (git commit)
# コミット前レビューチェックをブロックで強制する（レビューゲート v2）

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

[[ "$COMMAND" == *"git commit"* ]] || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WP_CONTENT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$WP_CONTENT_DIR/skills"

# jq 不在・git リポジトリ外はフェイルオープン（レビューゲート自体を機能させられないため通す）
if ! command -v jq >/dev/null 2>&1; then
  echo "[pre-git-commit] jq が見つからないためレビューチェックをスキップします。" >&2
  exit 0
fi
if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "[pre-git-commit] git リポジトリ外のためレビューチェックをスキップします。" >&2
  exit 0
fi

# shellcheck source=lib/review-flag.sh
source "$SCRIPT_DIR/lib/review-flag.sh"

TTL="${WP_REVIEW_TTL:-259200}"  # 既定3日（72時間）。ソロ・非同期開発が中心の本リポジトリの実態に合わせた値
FLAG="$(review_flag_path)"

block_review() {
  echo "⛔ コミット前チェック未完了" >&2
  echo "" >&2
  if [[ -f "$SKILLS_DIR/adversarial-reviewer/key-rules.md" ]]; then
    cat "$SKILLS_DIR/adversarial-reviewer/key-rules.md" >&2
  fi
  echo "" >&2
  echo "確認: bash bin/wp-review.sh <target>" >&2
  echo "その後 git commit を再実行してください" >&2
  exit 2
}

[[ -f "$FLAG" ]] || block_review

FLAG_DIGEST="$(sed -n '1p' "$FLAG")"
FLAG_TIME="$(sed -n '2p' "$FLAG")"
FLAG_TIME="${FLAG_TIME:-0}"
NOW=$(date +%s)

if (( NOW - FLAG_TIME > TTL )); then
  rm -f "$FLAG"
  echo "⛔ レビューから時間が経過しました（TTL: ${TTL}秒）。再レビューしてください: bash bin/wp-review.sh <target>" >&2
  exit 2
fi

if [[ "$FLAG_DIGEST" != "$(staged_digest)" ]]; then
  rm -f "$FLAG"
  echo "⛔ レビュー後に staged 内容が変更されています。再レビューしてください: bash bin/wp-review.sh <target>" >&2
  exit 2
fi

# フラグは削除しない。コミット成功で staged が空になり digest 不一致となって自己失効する。
echo "[pre-git-commit] レビュー確認済み。コミットを続行します。"
exit 0
