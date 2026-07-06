load 'helpers'

setup() {
  FIXTURE_DIR="$(mktemp -d)"
  mkdir -p "$FIXTURE_DIR/.claude/hooks"
  cp "$REPO_ROOT/.claude/hooks/session-compact-reinject.sh" "$FIXTURE_DIR/.claude/hooks/"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

@test "コミット前フローは v2（wp-review.sh + git commit）を案内する。v1 の touch 手順は含まない" {
  run bash "$FIXTURE_DIR/.claude/hooks/session-compact-reinject.sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"bash bin/wp-review.sh <target>"* ]]
  [[ "$output" != *"touch /tmp/wp-review-ok"* ]]
}

@test "theme.json 直接編集禁止の記載はない（このリポジトリの実態と不一致だったため削除済み）" {
  run bash "$FIXTURE_DIR/.claude/hooks/session-compact-reinject.sh"

  [ "$status" -eq 0 ]
  [[ "$output" != *"theme-json/"* ]]
}

@test "settings.json.example と settings.json が異なる → 差分警告を出す" {
  echo '{"a":1}' > "$FIXTURE_DIR/.claude/settings.json.example"
  echo '{"a":2}' > "$FIXTURE_DIR/.claude/settings.json"

  run bash "$FIXTURE_DIR/.claude/hooks/session-compact-reinject.sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"settings.json.example が更新されています"* ]]
}

@test "settings.json が存在しない → 未設定の警告を出す" {
  echo '{"a":1}' > "$FIXTURE_DIR/.claude/settings.json.example"

  run bash "$FIXTURE_DIR/.claude/hooks/session-compact-reinject.sh"

  [ "$status" -eq 0 ]
  [[ "$output" == *"settings.json が存在しません"* ]]
}

@test "settings.json.example と settings.json が同一 → 警告なし" {
  echo '{"a":1}' > "$FIXTURE_DIR/.claude/settings.json.example"
  echo '{"a":1}' > "$FIXTURE_DIR/.claude/settings.json"

  run bash "$FIXTURE_DIR/.claude/hooks/session-compact-reinject.sh"

  [ "$status" -eq 0 ]
  [[ "$output" != *"更新されています"* ]]
  [[ "$output" != *"存在しません"* ]]
}
