build_remote_runtime_expr() {
  local remote_command="$1"
  local server_name="${2:-127.0.0.1}"
  local pseudo="${3:-test-user}"
  local passwd="${4:-test-pass}"
  printf '(load "%s") (mogan-test-run-command "%s" "%s" "%s" '\''%s)' \
    "$RUNTIME_SCRIPT" \
    "$(scheme_escape "$server_name")" \
    "$(scheme_escape "$pseudo")" \
    "$(scheme_escape "$passwd")" \
    "$remote_command"
}

run_remote_runtime_command() {
  local remote_command="$1"
  local server_name="${2:-127.0.0.1}"
  local pseudo="${3:-test-user}"
  local passwd="${4:-test-pass}"
  local dry_run="${5:-}"
  local runtime_expr

  runtime_expr="$(build_remote_runtime_expr "$remote_command" "$server_name" "$pseudo" "$passwd")"
  run_or_print_runtime_command "$runtime_expr" "$dry_run"
}

show_file_section() {
  local label="$1"
  local path="$2"
  local mode="${3:-tail}"

  echo "== ${label} =="
  echo "path: ${path}"
  if [[ -f "$path" ]]; then
    echo "status: present"
    if [[ "$mode" == "cat" ]]; then
      cat "$path"
    else
      tail -n 120 "$path"
    fi
  else
    echo "status: missing"
  fi
  echo
}

show_traces() {
  show_file_section "connect-trace" "$CONNECT_TRACE"
  show_file_section "server-trace" "$SERVER_TRACE"
  show_file_section "runtime-result" "$RESULT_FILE" cat
  show_file_section "runtime-output" "$RUNTIME_OUTPUT"
}

run_runtime_command() {
  local runtime_expr="$1"
  local platform="${2:-minimal}"
  local binary_path

  binary_path="$(ensure_built_binary)"

  : > "$CONNECT_TRACE"
  : > "$RESULT_FILE"

  cd "$MOGAN_ROOT"
  env TEXMACS_PATH="$TEXMACS_PATH_DIR" "$binary_path" -platform "$platform" -d -debug-bench -x "$runtime_expr" >"$RUNTIME_OUTPUT" 2>&1 || true
  print_runtime_result
}
