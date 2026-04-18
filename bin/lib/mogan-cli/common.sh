require_gf_and_scheme_script() {
  if ! command -v gf >/dev/null 2>&1; then
    echo '{"status":"error","message":"Goldfish Scheme (gf) not found in PATH"}' >&2
    exit 1
  fi

  if [[ ! -f "$SCHEME_SCRIPT" ]]; then
    echo "{\"status\":\"error\",\"message\":\"Scheme script not found: $SCHEME_SCRIPT\"}" >&2
    exit 1
  fi
}

resolve_mogan_binary() {
  if [[ -x "$DEBUG_BINARY" ]]; then
    printf '%s\n' "$DEBUG_BINARY"
    return 0
  fi
  if [[ -x "$RELEASE_BINARY" ]]; then
    printf '%s\n' "$RELEASE_BINARY"
    return 0
  fi
  return 1
}

print_runtime_result() {
  if [[ ! -f "$RESULT_FILE" ]]; then
    echo "status: error"
    echo "value: missing result file"
    return 1
  fi

  local status
  local value
  status="$(sed -n '1p' "$RESULT_FILE")"
  value="$(sed -n '2p' "$RESULT_FILE")"

  echo "status: ${status:-error}"
  echo "value: ${value:-missing runtime result}"

  [[ "$status" == "ok" ]]
}

scheme_escape() {
  local value="${1-}"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

require_target_name() {
  local target_name="${1:-}"
  if [[ -z "$target_name" ]]; then
    echo '{"status":"error","message":"Target name is required"}' >&2
    exit 1
  fi
}

ensure_built_binary() {
  local binary_path
  binary_path="$(resolve_mogan_binary || true)"
  if [[ -z "$binary_path" ]]; then
    echo '{"status":"error","message":"Built Mogan client not found. Run `./mogan-cli build-client` first."}' >&2
    exit 1
  fi
  printf '%s\n' "$binary_path"
}

run_or_print_runtime_command() {
  local runtime_expr="$1"
  local dry_run_flag="${2:-}"
  local binary_path

  if [[ "${MOGAN_TEST_DRY_RUN:-0}" == "1" ]]; then
    dry_run_flag="--dry-run"
  fi

  if [[ "$dry_run_flag" == "--dry-run" ]]; then
    binary_path="$(ensure_built_binary)"
    printf 'cd %s && TEXMACS_PATH=%q %q -platform minimal -d -debug-bench -x %q\n' \
      "$MOGAN_ROOT" "$TEXMACS_PATH_DIR" "$binary_path" "$runtime_expr"
    exit 0
  fi

  run_runtime_command "$runtime_expr" "minimal"
}
