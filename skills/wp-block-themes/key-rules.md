# [wp-block-themes] フック注入用ルールサマリー

## テンプレート・パーツの絶対ルール

- `templates/*.html` / `parts/*.html` は **HTML のみ**。PHP は一切書けない
- 動的コンテンツが必要 → ダイナミックブロック（`render.php`）を作って呼び出す
- ブロックマークアップ形式: `<!-- wp:block-name {"attr":"val"} -->...<!-- /wp:block-name -->`
- template-part 参照: `<!-- wp:template-part {"slug":"header","theme":"vga"} /-->`
- self-closing ブロック末尾に必ずスペース+スラッシュ: `<!-- wp:spacer /-->`

## theme.json の管理

- `theme.json` を**直接編集しない**（`theme-json/` からマージ生成）
- 編集後は必ず `node theme-json/merge-theme-json.mjs` を実行する
- CSS 変数は `var(--wp--preset--color--[slug])` 形式で参照する

## よくある間違い

- `<?php` を HTML テンプレートに書く → **動作しない・セキュリティリスク**
- `style.css` に直接グローバルスタイルを書く → theme.json の styles が優先されて効かない
- WordPress コアの CSS クラス（`wp-block-*`）を上書きする → specificity に注意

## 確認コマンド

```bash
# テンプレートに PHP が混入していないか確認
grep -r '<?php' templates/ parts/
```
