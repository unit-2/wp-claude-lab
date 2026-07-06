load 'helpers'

run_pre_bash_safety() {
  local command="$1"
  echo "{\"tool_input\":{\"command\":\"${command}\"}}" | bash "$REPO_ROOT/.claude/hooks/pre-bash-safety.sh"
}

@test "rm -rf /tmp/x → exit 2" {
  run run_pre_bash_safety "rm -rf /tmp/x"
  [ "$status" -eq 2 ]
  [[ "$output" == *"危険なコマンドをブロックしました"* ]]
}

@test "rm file.txt → exit 0" {
  run run_pre_bash_safety "rm file.txt"
  [ "$status" -eq 0 ]
}
