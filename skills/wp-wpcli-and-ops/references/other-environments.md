# Local by Flywheel 以外の環境での WP-CLI

Local by Flywheel 以外の環境では、WP-CLI の実行方法が異なる。各環境ごとに確認すること。

---

## Lando

```bash
# lando wp コマンドとして実行する
lando wp post list --post_type=page
lando wp search-replace 'http://old.example.com' 'https://new.example.com' --dry-run
lando wp rewrite flush
```

`.lando.yml` に `wp` ツールが定義されていない場合は追加する：

```yaml
tooling:
  wp:
    service: appserver
    cmd: wp
```

---

## DDEV

```bash
# ddev exec 経由で実行する
ddev exec wp post list --post_type=page
ddev exec wp search-replace 'http://old.example.com' 'https://new.example.com' --dry-run
ddev exec wp rewrite flush

# または ddev wp エイリアスが使える場合
ddev wp post list
```

---

## Docker Compose（カスタム構成）

```bash
# php コンテナ内で実行する（コンテナ名は環境ごとに異なる）
docker compose exec php wp post list --post_type=page --allow-root
```

`--allow-root` が必要な場合は、コンテナが root ユーザーで動いているため。

---

## 共通の注意事項

- どの環境でも `search-replace` は必ず `--dry-run` を先に実行する
- 本番環境では SSH 経由で WP-CLI を使う（ローカルから直接実行しない）
- WP-CLI のバージョンは `wp --version` で確認する（2.x 系推奨）

---

## CLAUDE.local.md への記載推奨

環境ごとの実行コマンドを書いておくと、Claude が正しい方法を使える：

```markdown
## WP-CLI 実行方法
# Local by Flywheel の場合:
# PHP="$HOME/Library/Application Support/Local/lightning-services/php-8.2.30+1/bin/darwin-arm64/bin/php"
# cd "$WP_ROOT" && "$PHP" /opt/homebrew/bin/wp <command>

# Lando の場合:
# lando wp <command>

# DDEV の場合:
# ddev exec wp <command>
```
