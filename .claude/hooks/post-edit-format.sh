#!/bin/bash
# PostToolUse: Edit|Write
# ファイルタイプに応じて prettier / php-lint を自動実行する

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

[[ -z "$FILE_PATH" ]] && exit 0
[[ -f "$FILE_PATH" ]] || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WP_CONTENT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# prettier / stylelint 対象（theme.json / assets/ は .prettierignore で除外済み）
if [[ "$FILE_PATH" =~ \.(html|js|mjs|scss)$ ]]; then
  # prettier がインストールされているテーマ・プラグインのルートを探す
  DIR="$(dirname "$FILE_PATH")"
  PKG_DIR=""
  while [ "$DIR" != "/" ] && [ "$DIR" != "." ]; do
    if [ -f "$DIR/package.json" ] && [ -d "$DIR/node_modules" ]; then
      PKG_DIR="$DIR"
      break
    fi
    DIR="$(dirname "$DIR")"
  done

  if [ -n "$PKG_DIR" ]; then
    # SCSS: stylelint → prettier の順（stylelintで修正後にprettierで整形）
    if [[ "$FILE_PATH" =~ \.scss$ ]]; then
      echo "[format] stylelint: $FILE_PATH" >&2
      cd "$PKG_DIR" && npx stylelint --fix "$FILE_PATH" 2>&1 | grep -v "^$" >&2 || true
    fi
    echo "[format] prettier: $FILE_PATH" >&2
    cd "$PKG_DIR" && npx prettier --write "$FILE_PATH" 2>&1 | grep -v "^$" >&2 || true
  fi
  exit 0
fi

# PHP: php-lint（composer.json があるルートで実行）
if [[ "$FILE_PATH" =~ \.php$ ]]; then
  DIR="$(dirname "$FILE_PATH")"
  COMPOSER_DIR=""
  while [ "$DIR" != "/" ] && [ "$DIR" != "." ]; do
    if [ -f "$DIR/composer.json" ]; then
      COMPOSER_DIR="$DIR"
      break
    fi
    DIR="$(dirname "$DIR")"
  done

  if [ -n "$COMPOSER_DIR" ]; then
    echo "[format] php-lint: $FILE_PATH" >&2
    cd "$COMPOSER_DIR" && composer run php-lint "$FILE_PATH" 2>&1 >&2 || true
  fi
  exit 0
fi

exit 0
