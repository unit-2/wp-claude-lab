---
name: html-coding
description: "Use when writing or reviewing HTML markup for semantics, form correctness, or general W3C-compliant structure. WordPress-independent, general-purpose HTML rules; for WordPress-specific structure and WCAG accessibility, use wp-html-accessibility instead."
---

# HTML Coding

## When to use

Use this skill when writing or editing any `.html` file, or any HTML markup embedded in templates
or components, and you need general-purpose (WordPress-independent) HTML correctness:

- semantic element choice (headings, lists, tables, buttons vs. links)
- required/expected attributes (`alt`, `label`/`for`, `rel` on `target="_blank"`)
- form markup (`action`/`method`, required fields, error association)

Scope boundary:

- **html-coding** — general HTML/W3C rules that apply to any project, not tied to WordPress.
- **wp-html-accessibility** — WordPress-specific structure (block classes, template conventions)
  and WCAG AA accessibility (ARIA, landmarks, contrast, focus). Use both together when editing
  WordPress templates or template parts; `.claude/hooks/pre-edit-inject-skill.sh` already injects
  both automatically for `.html` files.

## Procedure

1. Read `key-rules.md` in this skill directory — it is the single source of truth for the rule
   set (do not duplicate its contents here or elsewhere; if a rule needs to change, edit it there).
2. Apply the relevant rules to the file being written or reviewed:
   - check element/tag choice against the structure/semantics rules
   - check every attribute requirement (`alt`, `label`, `rel`, boolean attributes)
   - check form markup against the form rules
3. Cross-check against the "よくある間違い" (common mistakes) section in `key-rules.md` before
   finishing — these are the most frequent regressions.
4. If the file is a WordPress template/template part or otherwise WordPress-specific, also apply
   `wp-html-accessibility` in the same pass.

## Verification

- Every `<img>` has an `alt` attribute (empty `alt=""` for decorative images).
- Heading levels are sequential with exactly one `<h1>` per page (no skipped levels).
- Interactive elements use the correct tag (`<button>` for actions, `<a>` for navigation).
- Every form input has an associated `<label>`, and required fields are marked.
- No inline `style="..."` attributes and no `<div>`/`<span>` used in place of semantic elements.
