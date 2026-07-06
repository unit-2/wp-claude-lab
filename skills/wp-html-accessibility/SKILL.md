---
name: wp-html-accessibility
description: "Use when writing or reviewing WordPress HTML structure and accessibility: landmarks, ARIA, WCAG AA color contrast/focus, and WordPress-specific classes (wp-block-*, entry-*, screen-reader-text). WordPress-specific complement to html-coding's general-purpose HTML rules."
---

# WP HTML Accessibility

## When to use

Use this skill when writing or editing WordPress-rendered HTML — block theme templates
(`templates/*.html`, `parts/*.html`), block markup, or PHP-rendered markup (`render.php`,
template tags) — and you need WordPress-specific structure and WCAG AA accessibility correctness:

- landmark/ARIA structure (`<header>`/`<main>`/`<footer>`/`<nav>`, `role`, `aria-*`)
- WordPress conventions (`wp-block-*`, `entry-*` classes, `screen-reader-text`)
- color contrast, focus styles, and focus order
- image/media accessibility (`alt`, captions)

Scope boundary:

- **wp-html-accessibility** — WordPress-specific structure and WCAG AA accessibility.
- **html-coding** — general, WordPress-independent HTML rules (semantics, forms, generic
  attributes). Use both together when editing WordPress templates or template parts;
  `.claude/hooks/pre-edit-inject-skill.sh` already injects both automatically for `.html` files.

## Procedure

1. Read `key-rules.md` in this skill directory — it is the single source of truth for the rule
   set (do not duplicate its contents here or elsewhere; if a rule needs to change, edit it there).
2. Apply the relevant rules to the file being written or reviewed:
   - check landmark/ARIA structure and labeling of duplicate landmarks (e.g. multiple `<nav>`)
   - check WordPress class conventions are respected rather than overridden
   - check contrast, focus-visible styles, and focus order
   - check image/media markup for meaningful `alt` text and captions
3. Cross-check against the "よくある間違い" (common mistakes) section in `key-rules.md` before
   finishing — these are the most frequent regressions.
4. For general (non-WordPress-specific) HTML correctness in the same file, also apply
   `html-coding` in the same pass.

## Verification

- Exactly one `<main>` per page; multiple `<nav>` elements are distinguished with `aria-label`.
- Icon-only controls have an accessible name (`aria-label` or screen-reader-text span).
- Text/background contrast meets WCAG AA (4.5:1 normal text, 3:1 large text) and `:focus-visible`
  is implemented (not just suppressed with `outline: none`).
- Focus order matches DOM order; no unnecessary `tabindex` overrides.
- `alt` text describes content (not a filename), and video has captions where applicable.
