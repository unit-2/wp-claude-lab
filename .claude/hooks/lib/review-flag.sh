#!/bin/bash
# レビューゲート v2（bin/wp-review.sh + pre-git-commit.sh）が共有する関数群。
# 呼び出し元スクリプトから `source` して使う。

# git リポジトリのルートを md5 化したものをプロジェクト識別子にする。
# $PWD やスクリプト位置基準だと呼び出し元によって値がずれるため、常に git ルートで統一する。
# macOS の `md5 -q` と Linux の `md5sum` で桁数がずれないよう、どちらもフルハッシュを使う。
project_hash() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  if command -v md5 >/dev/null 2>&1; then
    echo -n "$root" | md5 -q
  else
    echo -n "$root" | md5sum | cut -d' ' -f1
  fi
}

# staged 内容（git diff --cached）そのもののダイジェスト。
# レビュー後に staged 内容が変わっていないかの照合に使う。
staged_digest() {
  if command -v shasum >/dev/null 2>&1; then
    git diff --cached | shasum -a 256 | cut -d' ' -f1
  else
    git diff --cached | sha256sum | cut -d' ' -f1
  fi
}

# このプロジェクトのレビューフラグの絶対パスを返す。
review_flag_path() {
  local hash
  hash="$(project_hash)" || return 1
  echo "/tmp/wp-review-ok-${hash}"
}
