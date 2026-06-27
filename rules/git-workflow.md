# Git ワークフロー

## コミットメッセージの言語

- コミットメッセージは**英語**で書く
- コード内コメントは日本語可

```
# 正しい例
feat: add news CPT and archive template [MYSITE-42]
fix: resolve nonce verification failure on post save [MYSITE-43]

# 悪い例（日本語はNG）
feat: ニュースCPTを追加 [MYSITE-42]
```

## コミットメッセージ形式

```
<タイプ>: <説明> [PROJECT-123]

<本文（任意）>
```

- タイプ一覧: feat, fix, refactor, docs, test, chore, perf, ci
- **Backlog の課題番号を末尾に必ず付ける**（`[PROJECT-123]` 形式）
- プロジェクトキーは案件ごとに異なる。`CLAUDE.local.md` に記載しておくと便利

```
# 良い例
feat: トップページにスライダーを追加 [MYSITE-42]
fix: nonce 検証が失敗する問題を修正 [MYSITE-43]

# 悪い例
feat: トップページにスライダーを追加   ← 課題番号なし
```

## ブランチ命名規則

Backlog の課題番号をそのままブランチ名にする：

```
MYSITE-42
```

```bash
# ブランチ作成
git checkout -b MYSITE-42

# 悪い例
git checkout -b fix/slider-bug     ← 課題番号がない
git checkout -b tomoko-work        ← 人名はNG
git checkout -b 作業ブランチ        ← 日本語はNG
```

## PR タイトルの形式

コミットメッセージと同じ Conventional Commits 形式で書く：

```
<タイプ>(<スコープ>): <説明>
```

- **タイプ**: feat / fix / refactor / docs / test / chore / perf
- **スコープ**: 変更対象のテーマ名・プラグイン名・機能名（省略可）
- **説明**: 何をしたかを動詞で始める。70文字以内

```
# 良い例
feat(my-theme): トップページにスライダーを追加 [MYSITE-42]
fix(my-plugin): 投稿保存時に nonce 検証が失敗する問題を修正 [MYSITE-43]
refactor: 設定クラスをシングルトンから DI に変更 [MYSITE-44]

# 悪い例
feat(my-theme): トップページにスライダーを追加   ← 課題番号なし
修正                                             ← 何を修正したかわからない
WIP: スライダー                                  ← WIP はドラフト PR にする
fix/slider-bug                                   ← ブランチ名をそのままコピーしない
【緊急】本番バグ対応                              ← 絵文字・括弧・感嘆符は使わない
```

## プルリクエストの作成手順

1. コミット履歴全体を確認する（最新コミットだけでなく全体を）
2. `git diff [base-branch]...HEAD` で変更内容を確認する
3. **コンフリクトチェックを実行する**（下記参照）
4. PR の概要を書く
5. テスト計画（TODO チェックリスト）を含める
6. 新しいブランチの場合は `-u` フラグを付けて push する

## PR 前のコンフリクトチェック

PR を出す前に、**マージ先のブランチ**に対してコンフリクトチェックを実行する。

```bash
# git merge-tree を使う（ワーキングツリーを汚さない・コミットログに残らない）
git fetch origin
git merge-tree HEAD origin/<マージ先ブランチ>
```

終了コードで判定する：
- **0** → コンフリクトなし（PR 作成に進んでよい）
- **非0** → コンフリクトあり（出力の `<<<<<<` 箇所を確認して解消する）

**例：staging へ PR する場合**

```bash
git fetch origin
git merge-tree HEAD origin/staging
```

コンフリクトが検出されたら PR を作成せず、ブランチ上で解消してから再チェックする。

## 機能実装のワークフロー

1. **計画**
   - `wp-project-triage` スキルで適切なアプローチを見極める
   - 依存関係とリスクを洗い出す
   - フェーズに分けて整理する

2. **TDD（テスト駆動開発）**
   - `tdd-workflow` スキルを使う
   - スキルの呼び出し方：チャットで「`/tdd-workflow` を使って実装して」と指示する
   - テストを先に書く（RED）→ 実装する（GREEN）→ リファクタリング（IMPROVE）
   - カバレッジ（ビジネスロジック層）80%+ を確認する

3. **コードレビュー**
   - `adversarial-reviewer` スキルでコードを書いた直後にレビューする
   - スキルの呼び出し方：「`/adversarial-reviewer` でこのコードをレビューして」と指示する
   - CRITICAL・HIGH は必ず修正する
   - MEDIUM は可能な限り修正する

4. **コミット・プッシュ**
   - 詳細なコミットメッセージを書く
   - Conventional Commits 形式に従う

## スキルの呼び出し方

Claude Code では、チャット欄で以下のように指示するとスキルが参照されます：

```
wp-block-themes スキルを使ってテンプレートを作って
adversarial-reviewer でこのコードをレビューして
tdd-workflow に従ってテストを書いて
```

または `/スキル名` の形式でも呼び出せます。
