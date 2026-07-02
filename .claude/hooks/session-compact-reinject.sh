#!/bin/bash
# SessionStart (compact)
# コンテキスト圧縮後に WordPress 必須ルールを再注入する

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WP_CONTENT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== [wp-claude-lab] コンテキスト圧縮後の WordPress 必須ルール再注入 ==="
echo ""
echo "## セキュリティ（常に必須）"
echo "・出力: esc_html() / esc_attr() / esc_url() / wp_kses_post()"
echo "・入力: sanitize_text_field() / absint() / esc_url_raw()"
echo "・状態変更: wp_verify_nonce() 必須"
echo "・権限: current_user_can() 必須"
echo "・SQL: \$wpdb->prepare() 必須（文字列結合禁止）"
echo ""
echo "## ブロックテーマ"
echo "・templates/*.html / parts/*.html に PHP は書けない"
echo "・theme.json は直接編集しない（theme-json/ からマージ生成）"
echo ""
echo "## コミット前フロー"
echo "1. composer run phpstan <target>"
echo "2. touch /tmp/wp-review-ok-\$(echo \"\$PWD\" | md5 -q 2>/dev/null || echo \"\$PWD\" | md5sum | cut -c1-8)"
echo "3. git commit"
echo ""
echo "詳細は CLAUDE.md / rules/ を参照してください。"
exit 0
