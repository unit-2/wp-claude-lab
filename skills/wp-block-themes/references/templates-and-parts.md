# Templates and template parts

Use this file when creating or editing HTML templates/parts.

## ⚠️ PHP は絶対に書かない

`templates/*.html` と `parts/*.html` は **HTML のみ**。PHP を書いても実行されず、サイトエディターで「無効なコンテンツ」エラーになる。

```html
<!-- ❌ 動作しない — PHP タグは使えない -->
<p><?php esc_html_e( 'Not found.', 'domain' ); ?></p>

<!-- ✅ プレーンテキストで直接書く -->
<p>見つかりませんでした。</p>
```

動的コンテンツが必要な場合は、ダイナミックブロック（`render.php`）を作成してテンプレートから呼び出す。

## Key folders

- `templates/` for templates.
- `parts/` for template parts.

Template parts must not be nested in subdirectories.

Upstream references:

- Templates + parts overview: https://developer.wordpress.org/themes/block-themes/theme-structure/
- Template parts details: https://developer.wordpress.org/themes/block-themes/template-parts/

