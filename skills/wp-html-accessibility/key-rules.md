# [wp-html-accessibility] WordPress HTML・アクセシビリティ サマリー

## ランドマーク・ARIA

- `<header>` `<main>` `<footer>` `<nav>` `<aside>` を正しく配置する（1ページに1つの `<main>`）
- 複数の `<nav>` には `aria-label` で区別する（例: `aria-label="メインナビゲーション"`）
- アイコンのみのボタン・リンクには `aria-label` または `<span class="screen-reader-text">` を付ける
- モーダル・ドロワーには `role="dialog"` + `aria-modal="true"` + `aria-labelledby` を付ける

## WordPress 固有のクラス・構造

- `wp-block-*` クラスはコアが付与する。独自スタイルは追加クラスで対応する
- `entry-title` `entry-content` `entry-meta` などの WordPress 慣習クラスを尊重する
- `screen-reader-text` クラスを使って視覚的に隠しつつスクリーンリーダーに伝える

## カラーコントラスト・フォーカス

- テキストと背景のコントラスト比は WCAG AA 基準（通常テキスト 4.5:1 以上、大テキスト 3:1 以上）
- `:focus-visible` スタイルを必ず実装する（`outline: none` だけで終わらせない）
- フォーカス順序は DOM 順序と一致させる（`tabindex` の乱用禁止）

## 画像・メディア

- `<img>` の `alt` はコンテンツの意味を説明する（ファイル名をそのまま書かない）
- 背景画像（CSS `background-image`）に意味のある情報を入れない
- 動画には字幕（`<track kind="captions">`）を提供する

## よくある間違い

- `aria-label` と可視テキストの内容が食い違う → スクリーンリーダーが読み上げる方（aria-label）を優先する
- `role="button"` を `<div>` に付けて `tabindex` と `keydown` を手書きする → `<button>` を使う
- WordPress の `the_content()` 出力を `<p>` で囲む → 二重 `<p>` になる
- `skip to content` リンクを省略する → キーボードユーザーのために必須
