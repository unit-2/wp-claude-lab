# [wp-interactivity-api] Interactivity API 必須ルール

## store / state

- `store()` は `viewScriptModule`（ESM）から呼ぶ。`viewScript` からは呼ばない
- state の初期値は `wp_interactivity_state()` でサーバーサイドから渡す
- 派生 state（derived）は PHP 側でも同じ値を計算して初期 HTML に反映する

## ディレクティブ

- `data-wp-interactive` に namespace を必ず指定する（例: `data-wp-interactive="myplugin"`）
- ローカルコンテキストは `data-wp-context` で定義し、`useContext()` で読む
- `data-wp-bind` / `data-wp-class` / `data-wp-style` は動的属性の変更に使う
- `data-wp-on--click` のようにイベント名は `--` でつなぐ

## block.json

- `supports.interactivity: true` を設定する
- `viewScriptModule` にスクリプトを登録する（`viewScript` は非推奨）

## よくある間違い

- namespace を省略する → 別ブロックの store と衝突する
- `viewScript` を使う → ESM モジュールとして動作しない
- PHP で初期 state を渡さずクライアント側だけで state を定義する → ハイドレーション不一致
