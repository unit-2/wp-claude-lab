#!/bin/bash
# PostToolUse: Edit|Write
# ファイルタイプに応じて prettier / php-lint を自動実行する

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

[[ -z "$FILE_PATH" ]] && exit 0
[[ -f "$FILE_PATH" ]] || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# prettier / stylelint 対象（theme.json / assets/ は .prettierignore で除外済み）
if [[ "$FILE_PATH" =~ \.(html|js|mjs|scss)$ ]]; then
  # prettier がインストールされているテーマ・プラグインのルートを探す
  DIR="$(cd "$(dirname "$FILE_PATH")" && pwd)"
  PKG_DIR=""
  while true; do
    if [ -f "$DIR/package.json" ] && [ -d "$DIR/node_modules" ]; then
      PKG_DIR="$DIR"
      break
    fi
    [ "$DIR" = "/" ] && break
    DIR="$(dirname "$DIR")"
  done

  if [ -n "$PKG_DIR" ]; then
    # SCSS: stylelint → prettier の順（stylelintで修正後にprettierで整形）
    if [[ "$FILE_PATH" =~ \.scss$ ]]; then
      echo "[format] stylelint: $FILE_PATH" >&2
      if ! (cd "$PKG_DIR" && npx stylelint --fix "$FILE_PATH") 2>&1 | grep -v "^$" >&2; then
        echo "[warn] stylelint failed: $FILE_PATH" >&2
      fi
    fi
    echo "[format] prettier: $FILE_PATH" >&2
    if ! (cd "$PKG_DIR" && npx prettier --write "$FILE_PATH") 2>&1 | grep -v "^$" >&2; then
      echo "[warn] prettier failed: $FILE_PATH" >&2
    fi
  fi
  exit 0
fi

# PHP: php-lint（composer.json があるルートで実行）
if [[ "$FILE_PATH" =~ \.php$ ]]; then
  DIR="$(cd "$(dirname "$FILE_PATH")" && pwd)"
  COMPOSER_DIR=""
  while true; do
    if [ -f "$DIR/composer.json" ]; then
      COMPOSER_DIR="$DIR"
      break
    fi
    [ "$DIR" = "/" ] && break
    DIR="$(dirname "$DIR")"
  done

  if [ -n "$COMPOSER_DIR" ]; then
    echo "[format] php-lint: $FILE_PATH" >&2

    FILE_HASH=$(echo -n "$FILE_PATH" | md5 -q 2>/dev/null || echo -n "$FILE_PATH" | md5sum | cut -d' ' -f1)
    RETRY_COUNTER="/tmp/wp-lint-retry-${FILE_HASH}"

    LINT_OUTPUT=$(cd "$COMPOSER_DIR" && composer run php-lint "$FILE_PATH" 2>&1)
    LINT_EXIT=$?

    if [[ $LINT_EXIT -eq 0 ]]; then
      rm -f "$RETRY_COUNTER"
      exit 0
    fi

    FAIL_COUNT=$(( $(cat "$RETRY_COUNTER" 2>/dev/null || echo 0) + 1 ))
    echo "$FAIL_COUNT" > "$RETRY_COUNTER"

    echo "$LINT_OUTPUT" >&2

    if (( FAIL_COUNT > 3 )); then
      echo "[warn] php-lint failed ${FAIL_COUNT} 回目のため警告のみに降格します: $FILE_PATH" >&2
      exit 0
    fi

    echo "[error] php-lint failed (${FAIL_COUNT}/3): $FILE_PATH" >&2
    exit 2
  fi
  exit 0
fi

exit 0
