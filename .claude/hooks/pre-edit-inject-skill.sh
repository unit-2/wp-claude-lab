#!/bin/bash
# PreToolUse: Edit|Write
# ファイルパスに応じてスキルのキーポイントを注入し、PHP混入をブロックする

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

[[ -z "$FILE_PATH" ]] && exit 0

# スキルディレクトリをプロジェクトルートから解決する
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WP_CONTENT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SKILLS_DIR="$WP_CONTENT_DIR/skills"

# ① templates/*.html / parts/*.html → wp-block-themes + html-coding + wp-html-accessibility + PHP混入ブロック
if [[ "$FILE_PATH" =~ /templates/[^/]+\.html$ ]] || [[ "$FILE_PATH" =~ /parts/[^/]+\.html$ ]]; then
  echo "=== [wp-block-themes] テンプレート編集前チェック ==="
  [[ -f "$SKILLS_DIR/wp-block-themes/key-rules.md" ]] && cat "$SKILLS_DIR/wp-block-themes/key-rules.md"
  echo ""
  echo "=== [html-coding] HTML コーディング規約 ==="
  [[ -f "$SKILLS_DIR/html-coding/key-rules.md" ]] && cat "$SKILLS_DIR/html-coding/key-rules.md"
  echo ""
  echo "=== [wp-html-accessibility] WordPress アクセシビリティ ==="
  [[ -f "$SKILLS_DIR/wp-html-accessibility/key-rules.md" ]] && cat "$SKILLS_DIR/wp-html-accessibility/key-rules.md"

  # 新規コンテンツに <?php が含まれていたらブロック
  NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // ""')
  if echo "$NEW_CONTENT" | grep -q '<?php'; then
    echo "[ERROR] PHPコードが含まれています。ブロックテーマテンプレートにPHPは使えません。" >&2
    echo "動的コンテンツが必要な場合はダイナミックブロック（render.php）を使ってください。" >&2
    exit 2
  fi
  exit 0
fi

# ①-b その他の .html ファイル → html-coding + wp-html-accessibility
if [[ "$FILE_PATH" =~ \.html$ ]]; then
  echo "=== [html-coding] HTML コーディング規約 ==="
  [[ -f "$SKILLS_DIR/html-coding/key-rules.md" ]] && cat "$SKILLS_DIR/html-coding/key-rules.md"
  echo ""
  echo "=== [wp-html-accessibility] WordPress アクセシビリティ ==="
  [[ -f "$SKILLS_DIR/wp-html-accessibility/key-rules.md" ]] && cat "$SKILLS_DIR/wp-html-accessibility/key-rules.md"
  exit 0
fi

# ② blocks/ 配下 または block.json → wp-block-development
if [[ "$FILE_PATH" =~ /blocks/ ]] || [[ "$FILE_PATH" =~ /block\.json$ ]]; then
  echo "=== [wp-block-development] ブロック編集前チェック ==="
  [[ -f "$SKILLS_DIR/wp-block-development/key-rules.md" ]] && cat "$SKILLS_DIR/wp-block-development/key-rules.md"
  exit 0
fi

# ③ plugins/ 配下の PHP → wp-plugin-development + 重複チェック
if [[ "$FILE_PATH" =~ /plugins/.*\.php$ ]]; then
  echo "=== [wp-plugin-development] プラグイン編集前チェック ==="
  [[ -f "$SKILLS_DIR/wp-plugin-development/key-rules.md" ]] && cat "$SKILLS_DIR/wp-plugin-development/key-rules.md"
  echo ""
  echo "=== [重複コード確認] 実装前に既存コードを確認してください ==="
  PLUGIN_DIR=$(echo "$FILE_PATH" | grep -oE '.*/plugins/[^/]+')
  echo "・このプラグイン内に同じ処理をする関数・クエリがすでにないか確認する"
  echo "・確認方法: grep -rn '関数名キーワード' $PLUGIN_DIR"
  echo "・WP_Query / \$wpdb クエリは特に重複しやすい。既存のものを再利用すること"
  exit 0
fi

# ③-b themes/ 配下の PHP → 重複チェック
if [[ "$FILE_PATH" =~ /themes/.*\.php$ ]]; then
  echo "=== [重複コード確認] 実装前に既存コードを確認してください ==="
  THEME_DIR=$(echo "$FILE_PATH" | grep -oE '.*/themes/[^/]+')
  echo "・このテーマ内に同じ処理をする関数・クエリがすでにないか確認する"
  echo "・確認方法: grep -rn '関数名キーワード' $THEME_DIR"
  echo "・WP_Query / get_posts は特に重複しやすい。既存のものを再利用すること"
  echo "・テンプレートタグ（get_header / get_footer 等）は WordPress コアを使う"
  exit 0
fi

# ④ .scss ファイル → SCSS 規約リマインダー
if [[ "$FILE_PATH" =~ \.scss$ ]]; then
  echo "=== [scss] SCSS 編集前チェック ==="
  echo "・BEM ライクな命名を使う（ただし WordPress コアクラスはそのまま使う）"
  echo "・theme.json の CSS 変数を優先: var(--wp--preset--color--[slug])"
  echo "・body への font-family 指定は SCSS に書かない（theme.json の styles で管理）"
  echo "・stylelint: selector-class-pattern は null（WordPress コアクラスとの共存のため）"
  exit 0
fi

exit 0
