#!/bin/bash
# PostToolUse: Edit|Write (.php)
# セキュリティキーワード検出・REST API / Interactivity API ルール注入

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

[[ "$FILE_PATH" =~ \.php$ ]] || exit 0
[[ -f "$FILE_PATH" ]] || exit 0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/skills"

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
  echo ""
  [[ -f "$SKILLS_DIR/security-review/key-rules.md" ]] && cat "$SKILLS_DIR/security-review/key-rules.md"
fi

# register_rest_route → REST API ルール注入
if grep -q 'register_rest_route' <<< "$CONTENT"; then
  echo ""
  [[ -f "$SKILLS_DIR/wp-rest-api/key-rules.md" ]] && cat "$SKILLS_DIR/wp-rest-api/key-rules.md"
fi

# Interactivity API → ルール注入
if grep -qE 'data-wp-|wp_interactivity_state' <<< "$CONTENT"; then
  echo ""
  [[ -f "$SKILLS_DIR/wp-interactivity-api/key-rules.md" ]] && cat "$SKILLS_DIR/wp-interactivity-api/key-rules.md"
fi

exit 0
