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

# ① templates/*.html / parts/*.html → wp-block-themes + PHP混入ブロック
if [[ "$FILE_PATH" =~ /templates/[^/]+\.html$ ]] || [[ "$FILE_PATH" =~ /parts/[^/]+\.html$ ]]; then
  echo "=== [wp-block-themes] テンプレート編集前チェック ==="
  [[ -f "$SKILLS_DIR/wp-block-themes/key-rules.md" ]] && cat "$SKILLS_DIR/wp-block-themes/key-rules.md"

  # 新規コンテンツに <?php が含まれていたらブロック
  NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // ""')
  if echo "$NEW_CONTENT" | grep -q '<?php'; then
    echo "[ERROR] PHPコードが含まれています。ブロックテーマテンプレートにPHPは使えません。" >&2
    echo "動的コンテンツが必要な場合はダイナミックブロック（render.php）を使ってください。" >&2
    exit 2
  fi
  exit 0
fi

# ② blocks/ 配下 または block.json → wp-block-development
if [[ "$FILE_PATH" =~ /blocks/ ]] || [[ "$FILE_PATH" =~ /block\.json$ ]]; then
  echo "=== [wp-block-development] ブロック編集前チェック ==="
  [[ -f "$SKILLS_DIR/wp-block-development/key-rules.md" ]] && cat "$SKILLS_DIR/wp-block-development/key-rules.md"
  exit 0
fi

# ③ plugins/ 配下の PHP → wp-plugin-development
if [[ "$FILE_PATH" =~ /plugins/.*\.php$ ]]; then
  echo "=== [wp-plugin-development] プラグイン編集前チェック ==="
  [[ -f "$SKILLS_DIR/wp-plugin-development/key-rules.md" ]] && cat "$SKILLS_DIR/wp-plugin-development/key-rules.md"
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
