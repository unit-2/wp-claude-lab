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

1. **Local でサイトを立ち上げる**（Local by Flywheel などを使用）
2. **Composer ツールをインストール**（`wp-content/` から）：
   ```bash
   composer install
   ```
3. **ローカル設定ファイルを作成**：
   ```bash
   cp CLAUDE.local.md.example CLAUDE.local.md
   ```
   `CLAUDE.local.md` を開き、自分のローカル環境情報を書き込む。
4. **Git フックを有効化**：
   ```bash
   git config core.hooksPath .githooks
   ```
   main / master への直接コミット・プッシュ時に警告が出るようになります。
5. **Claude Code フック設定をコピー**：
   ```bash
   cp .claude/settings.json.example .claude/settings.json
   ```

## 必須ルール

詳細は `rules/` を参照。要点のみ：

- PHP は **WordPress Coding Standards** に従う
- エスケープ・サニタイズ・Nonce・権限チェックを必ず行う
- `$wpdb` を使う場合は必ず `$wpdb->prepare()` を使う
- 関数・クラス・フック名はすべてプレフィックスを付ける（プロジェクトのスラッグを使う）
- すべての PHP ファイルに `if ( ! defined( 'ABSPATH' ) ) { exit; }` を記述する

## コード変更後の必須確認コマンド

PHP ファイルを変更したら **必ず以下を実行**すること（`wp-content/` から）。  
`<target>` には対象のテーマまたはプラグインのパスを指定する（例: `themes/my-theme`、`plugins/my-plugin`）：

```bash
# 規約チェック
composer run php-lint <target>

# 自動修正
composer run php-format <target>

# 静的解析
composer run phpstan <target>

# PHP バージョン互換性チェック（リリース前）
composer run php-compatibility <target>

# テスト実行
composer run test
```

エラーが出たら修正してから完了とする。

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

## ワークフロー

1. **作業前**: 関連スキルを確認する
2. **実装中**: PHP ファイルを変更したら `composer run php-lint <target>` を都度実行
3. **完了前**: `php-lint` + `phpstan` + `test` がエラーなしであることを確認
4. **コミット**: Conventional Commits 形式（`feat:` / `fix:` / `refactor:` / `docs:` / `chore:`）

## 指示がなくても必ず使うスキル

以下のタイミングでは、ユーザーから指示がなくても自動的に該当スキルを適用すること：

| タイミング | スキル | 理由 |
|-----------|--------|------|
| 機能実装が完了したとき | `adversarial-reviewer` | バグ・ロジックミスの見落とし防止 |
| コミット前 | `adversarial-reviewer` | 最終確認 |
| 認証・権限・nonce・DB クエリに触れるコード | `security-review` | セキュリティ問題は後から直すコストが高い |
| 設計・方針を決める前（「どちらを使うか」「どう実装するか」） | `adversarial-reviewer`（デビルズアドボケイト視点） | 採用前に弱点を洗い出す |

## ディレクトリ構成

```
wp-content/
├── themes/           ← テーマ（FSE / クラシック）
├── plugins/          ← プラグイン
├── rules/            ← Claude へのルール定義
├── skills/           ← WordPress 開発スキル（17種）
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
