# wp-content — Agent Guidelines

WordPress テーマ・プラグイン・ブロック開発のための汎用ベース環境です。  
テーマ開発・プラグイン開発・ブロック開発・クライアント案件など、あらゆる WordPress 開発の起点として使います。

## プロジェクト概要

- **用途**: WordPress 開発の共通ベース環境（テーマ / プラグイン / ブロック / 案件開発）
- **利用者**: チーム共有
- **作業ディレクトリ**: `wp-content/`（このファイルのある場所）
- **サイト URL**: 各自の `CLAUDE.local.md` を参照

> **Claude Code が必要です。** このプロジェクトは [Claude Code](https://docs.anthropic.com/ja/docs/claude-code/overview) を使って開発することを前提としています。  
> インストール: `npm install -g @anthropic-ai/claude-code`

## セットアップ（初回のみ）

セットアップ手順は README.md の「セットアップ（初回のみ）」節を参照。

## 必須ルール

詳細は `rules/` を参照：

- PHP コーディング規約・確認コマンド → `rules/php.md`
- WordPress セキュリティ・API・フック → `rules/wordpress.md`
- セキュリティガイドライン → `rules/security.md`
- テスト方針 → `rules/testing.md`
- Git ワークフロー・コミット規約 → `rules/git-workflow.md`

## スキルの使い方

`skills/` に WordPress 開発用スキルが入っている。以下のタイミングで使うこと：

| タイミング | 使うスキル |
|-----------|-----------|
| ブロックテーマ・FSE の作業 | `wp-block-themes` |
| ブロック開発（block.json など） | `wp-block-development` |
| プラグイン開発 | `wp-plugin-development` |
| WP-CLI 操作 | `wp-wpcli-and-ops` |
| コードレビュー（バグ・脆弱性） | `adversarial-reviewer` |
| セキュリティ確認 | `security-review` |
| テスト駆動開発 | `tdd-workflow` |
| ブラウザで UI 確認 | `agent-browser` |
| パフォーマンス改善 | `wp-performance` |
| 静的解析（PHPStan） | `wp-phpstan` |
| REST API 開発 | `wp-rest-api` |
| Interactivity API | `wp-interactivity-api` |
| 案件の方針判断 | `wp-project-triage` |
| Capabilities API | `wp-abilities-api` |
| ルーティング | `wordpress-router` |
| WordPress Design System | `wpds` |
| WordPress Playground | `wp-playground` |
| HTML コーディング規約 | `html-coding` |
| WordPress アクセシビリティ | `wp-html-accessibility` |

## 開発プロトコル（必ず従うこと）

### 作業開始前（新機能・新CPT・新テンプレートを作るとき）

- **`wp-project-triage` スキルを必ず使う** — リポジトリの種別・構成を把握してから設計する
- **`wordpress-router` スキルを使う** — 作業ドメインに合った別スキルへ誘導してもらう

### 新しいビジネスロジッククラスを作るとき

- **`tdd-workflow` スキルに従う** — テストを先に書く（RED → GREEN → IMPROVE）

### PHP実装が1ファイル完了したとき（必須）

- **`adversarial-reviewer` スキルを必ず呼び出す**（ユーザーの指示不要）
- CRITICAL・HIGH は修正してから次に進む

### セキュリティ関連コードを書いたとき（必須）

- **`security-review` スキルを必ず呼び出す**
- フックが `[security-alert]` を出力したら即座に実行する

### コミット前（必須）

1. `composer run phpstan <target>` を実行してエラーゼロを確認する
2. `adversarial-reviewer` スキルでコードをレビューする
3. `touch /tmp/wp-review-ok-<PROJECT_HASH>` を実行する（フックがブロックを解除する）
4. `git commit` を実行する

### パフォーマンス問題が出たとき

- **`wp-performance` スキルを使う**

### UI確認が必要なとき

- **`agent-browser` スキルを使う**

---

## スキルを使うタイミング（必須）

以下の条件に該当したら、ユーザーからの指示を待たずに**必ずスキルを呼び出すこと**。
フックが自動的にルールを注入するが、スキルの詳細が必要なときは明示的に呼び出す。

### `adversarial-reviewer` を必ず呼び出す場面

- PHPファイルの実装が1つ完了したとき
- コミット前の最終確認
- 「どちらの設計にするか」「どう実装するか」を判断する前（デビルズアドボケイト視点）

### `security-review` を必ず呼び出す場面

- `current_user_can()` / `wp_verify_nonce()` / `$wpdb` を含むコードを書いたとき
- `register_rest_route()` でREST APIエンドポイントを登録したとき

### `wp-block-themes` を必ず呼び出す場面

- `templates/*.html` / `parts/*.html` を新規作成・編集するとき
- `theme.json` を編集するとき

### `wp-block-development` を必ず呼び出す場面

- `block.json` を新規作成・編集するとき
- カスタムブロックを新規作成するとき

## ディレクトリ構成

```
wp-content/
├── themes/           ← テーマ（FSE / クラシック）
├── plugins/          ← プラグイン
├── rules/            ← Claude へのルール定義
├── skills/           ← WordPress 開発スキル（19種）
├── config/
│   ├── phpcs/        ← PHPCS 設定（phpcs.xml.dist）
│   └── phpstan/      ← PHPStan 設定（phpstan.neon.dist）
└── composer.json     ← PHP ツール定義
```

## スキル・ルールのメンテナンス

WordPress のメジャーアップデート（年2回）に合わせてスキルとルールを見直す：

- `rules/wordpress.md` — 新しい API・非推奨機能の反映
- `skills/wp-block-development/` — Block API の変更
- `skills/wp-interactivity-api/` — Interactivity API の更新
- PHPStan レベルの引き上げ検討（現在: 3 → 目標: 5 → 8）

## 注意事項

- `vendor/` は git 管理しない（`.gitignore` 済み）
- `uploads/` `languages/` `themes/twenty*/` は git 管理しない
- `CLAUDE.local.md` は個人設定のため git 管理しない
- `.claude/settings.json` は個人のフック設定のため git 管理しない（`.example` をコミット済み）
