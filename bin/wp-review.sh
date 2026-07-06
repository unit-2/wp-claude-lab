#!/bin/bash
# コミット前レビューフローをワンコマンドで実行する（レビューゲート v2）
#
# 使い方:
#   bash bin/wp-review.sh <target>
#
# 例:
#   bash bin/wp-review.sh themes/wp-claude-lab
#   bash bin/wp-review.sh plugins/my-plugin
#
# staged 内容のダイジェストと確認時刻をフラグに記録する。pre-git-commit.sh は
# このフラグの digest が staged 内容と一致し、かつ TTL 内であることを確認してからコミットを許可する。

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WP_CONTENT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=lib/review-flag.sh
source "$WP_CONTENT_DIR/.claude/hooks/lib/review-flag.sh"

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "使い方: bash bin/wp-review.sh <target>"
  echo "例:     bash bin/wp-review.sh themes/wp-claude-lab"
  exit 1
fi

TARGET_PATH="$WP_CONTENT_DIR/$TARGET"
if [[ ! -d "$TARGET_PATH" ]]; then
  echo "エラー: ディレクトリが見つかりません: $TARGET_PATH"
  exit 1
fi

cd "$WP_CONTENT_DIR" || exit 1

if [[ -z "$(git diff --cached)" ]]; then
  echo "エラー: staged された変更がありません。git add してから実行してください。"
  exit 1
fi

echo "=== [wp-review] コミット前チェック: $TARGET ==="
echo ""

# 1. phpstan
echo "▶ phpstan を実行中..."
composer run phpstan "$TARGET"
PHPSTAN_EXIT=$?

if [[ $PHPSTAN_EXIT -ne 0 ]]; then
  echo ""
  echo "❌ phpstan でエラーが見つかりました。修正してから再実行してください。"
  exit 1
fi

echo "✅ phpstan: エラーなし"
echo ""

# 2. レビューチェックリストを表示
echo "▶ adversarial-reviewer チェックリスト:"
echo ""
echo "□ ロジック: 条件の逆転・nullチェック漏れ・オフバイワンはないか"
echo "□ セキュリティ: エスケープ・nonce・権限チェックはすべて揃っているか"
echo "□ WordPress: prepare()なしのSQLはないか。プレフィックスは付いているか"
echo "□ 型安全: 型宣言・戻り値型が揃っているか"
echo ""
read -p "上記を確認しましたか？ [y/N] " CONFIRMED

if [[ "$CONFIRMED" != "y" && "$CONFIRMED" != "Y" ]]; then
  echo "確認をキャンセルしました。レビュー後に再実行してください。"
  exit 1
fi

# 3. フラグに digest + 確認時刻を書き込む
FLAG="$(review_flag_path)"
if [[ -z "$FLAG" ]]; then
  echo "エラー: git リポジトリ内で実行してください。"
  exit 1
fi
printf '%s\n%s\n' "$(staged_digest)" "$(date +%s)" > "$FLAG"

echo ""
echo "✅ レビュー確認済み。git commit を実行できます。"
echo ""
echo "  git add <files>"
echo "  git commit -m \"feat: ...\""
