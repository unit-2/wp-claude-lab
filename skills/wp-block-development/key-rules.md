# [wp-block-development] フック注入用ルールサマリー

## block.json の必須ルール

- `name` は `namespace/block-name` 形式（例: `myplugin/my-card`）
- `version` は常に更新する（ブラウザキャッシュ対策）
- `editorScript` / `editorStyle` はエディタ専用。フロント不要なら `script` / `style` を使わない
- `viewScript` は**非推奨**。WP 6.5+ は `viewScriptModule`（ESM）を使う
- `supports` で必要な機能を明示的に有効化する（デフォルト off のものが多い）

## 動的ブロック（render.php）

- `render_callback` より `render.php`（block.json に `"render": "file:./render.php"` を指定）
- `render.php` の変数: `$attributes`（配列）、`$content`（インナーブロックHTML）、`$block`（WP_Block）
- 出力は必ずエスケープする: `esc_html()` / `wp_kses_post()` / `esc_url()`

## 登録

```php
// functions.php または init フックで
register_block_type( __DIR__ . '/blocks/my-block' );
// block.json があるディレクトリを渡すだけで全属性が自動登録される
```

## よくある間違い

- `save()` 関数で動的コンテンツを返す → ブロック invalid エラーになる（null を返す）
- `viewScript` を使い続ける → ESM モジュールが使えない・非推奨
- `block.json` なしで `register_block_type()` に配列で全指定 → 管理が煩雑になる

## デバッグ

```bash
# ブロック一覧を確認
node skills/wp-block-development/scripts/list_blocks.mjs
```
