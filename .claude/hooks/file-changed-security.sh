#!/bin/bash
# FileChanged: .env|wp-config.php
# 機密ファイルが変更されたときに警告する

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // ""')

echo "[security-alert] 機密ファイルが変更されました: $FILE_PATH"
echo "・変更内容に API キー・パスワード・トークン等の機密情報が含まれていないか確認してください"
echo "・このファイルは .gitignore に含まれていますか？"
echo "・git add してしまわないよう注意してください"
exit 0
