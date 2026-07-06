load 'helpers'

run_pre_edit_inject_skill() {
  local file_path="$1"
  local content="$2"
  echo "{\"tool_input\":{\"file_path\":\"${file_path}\",\"new_string\":\"${content}\"}}" | bash "$REPO_ROOT/.claude/hooks/pre-edit-inject-skill.sh"
}

@test "templates/*.html に <?php が含まれる → exit 2" {
  run run_pre_edit_inject_skill "$REPO_ROOT/themes/wp-claude-lab/templates/single.html" '<?php echo 1; ?>'
  [ "$status" -eq 2 ]
  [[ "$output" == *"PHPコードが含まれています"* ]]
}

@test "plugins/*.php → exit 0 かつスキル誘導文が注入される" {
  run run_pre_edit_inject_skill "$REPO_ROOT/plugins/my-plugin/my-plugin.php" 'function foo() {}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"wp-plugin-development"* ]]
}

@test "対象外パス → exit 0（注入なし）" {
  run run_pre_edit_inject_skill "$REPO_ROOT/docs/plans/notes.md" 'memo'
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
