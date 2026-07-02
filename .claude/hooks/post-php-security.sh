#!/bin/bash
# PostToolUse: Edit|Write (.php)
# セキュリティキーワード検出・REST API / Interactivity API ルール注入

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

[[ "$FILE_PATH" =~ \.php$ ]] || exit 0
[[ -f "$FILE_PATH" ]] || exit 0

CONTENT=$(cat "$FILE_PATH")
FOUND=()

grep -q 'current_user_can'    <<< "$CONTENT" && FOUND+=("current_user_can")
grep -q 'wp_verify_nonce'     <<< "$CONTENT" && FOUND+=("wp_verify_nonce")
grep -q '\$wpdb'              <<< "$CONTENT" && FOUND+=("\$wpdb")
grep -q 'register_rest_route' <<< "$CONTENT" && FOUND+=("register_rest_route")

if [ ${#FOUND[@]} -gt 0 ]; then
  KEYWORDS=$(IFS=', '; echo "${FOUND[*]}")
  echo "[security-alert] $FILE_PATH にセキュリティ関連キーワード: $KEYWORDS"
  echo "security-review スキルを使ってセキュリティ確認を行ってください。"
fi

# register_rest_route → REST API ルール注入
if grep -q 'register_rest_route' <<< "$CONTENT"; then
  echo ""
  echo "=== [wp-rest-api] REST API 必須ルール ==="
  echo "・permission_callback を必ず実装する（省略不可）"
  echo "・公開エンドポイントは __return_true に '// 意図的に公開' コメントを付ける"
  echo "・引数は args で validate_callback / sanitize_callback を定義する"
  echo "・レスポンスは WP_REST_Response を返す。エラーは WP_Error を使う"
fi

# Interactivity API → ルール注入
if grep -qE 'data-wp-|wp_interactivity_state' <<< "$CONTENT"; then
  echo ""
  echo "=== [wp-interactivity-api] Interactivity API 必須ルール ==="
  echo "・store() は viewScriptModule（ESM）から呼ぶ。viewScript からは呼ばない"
  echo "・state は wp_interactivity_state() でサーバーサイドから初期値を渡す"
  echo "・data-wp-interactive 属性に namespace を必ず指定する"
  echo "・コンテキストは data-wp-context で定義し、useContext() で読む"
fi

exit 0
