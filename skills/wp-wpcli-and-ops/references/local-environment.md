# Local by Flywheel 環境での WP-CLI

システムの `wp` コマンドは Local by Flywheel の DB に接続できないため、Local が管理する PHP バイナリを使って WP-CLI を実行する必要がある。

## PHP パスの確認

```bash
ls ~/Library/Application\ Support/Local/lightning-services/ | grep php
# 例: php-8.2.30+1
```

フルパスを変数に設定する（バージョン番号を実際のものに合わせること）：

```bash
PHP="$HOME/Library/Application Support/Local/lightning-services/php-8.2.30+1/bin/darwin-arm64/bin/php"
```

## WP-CLI の実行方法

```bash
cd "/Users/yourname/Local Sites/mysite/app/public"
"$PHP" /opt/homebrew/bin/wp post list --post_type=page
```

## 実行例

```bash
# ページ一覧
"$PHP" /opt/homebrew/bin/wp post list --post_type=page

# タームを追加（news_tag タクソノミーにタグを追加）
"$PHP" /opt/homebrew/bin/wp term create news_tag "テクノロジー" --slug=technology

# パーマリンクをフラッシュ（CPT 登録後は必須）
"$PHP" /opt/homebrew/bin/wp rewrite flush
```

## CLAUDE.local.md への記載推奨

ローカル環境ごとにパスが異なるため、`CLAUDE.local.md` に書いておくと便利：

```markdown
## WP-CLI
PHP_BIN="$HOME/Library/Application Support/Local/lightning-services/php-8.2.30+1/bin/darwin-arm64/bin/php"
WP_ROOT="/Users/yourname/Local Sites/mysite/app/public"

# 実行方法
# cd "$WP_ROOT" && "$PHP_BIN" /opt/homebrew/bin/wp <command>
```

## トラブルシューティング

- `Error: Error establishing a database connection` → システムの `wp` コマンドを使っている。上記の Local PHP パスを使うこと
- PHP パスが存在しない → `ls ~/Library/Application\ Support/Local/lightning-services/` でインストール済みのバージョンを確認する
