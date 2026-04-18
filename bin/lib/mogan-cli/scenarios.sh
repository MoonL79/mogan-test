scenario_run_batch() {
  local target_name="$1"
  local dry_run_flag="$2"
  shift 2

  local -a batch_args=(batch "$target_name")
  if [[ -n "$dry_run_flag" ]]; then
    batch_args+=("$dry_run_flag")
  fi
  batch_args+=(-- "$@")
  exec "$0" "${batch_args[@]}"
}

SCENARIO_TARGET_NAME="smoke"
SCENARIO_DRY_RUN_FLAG=""

scenario_target_and_dry_run() {
  SCENARIO_TARGET_NAME="smoke"
  SCENARIO_DRY_RUN_FLAG=""

  if [[ $# -gt 0 ]]; then
    if [[ "${1:-}" == "--dry-run" ]]; then
      SCENARIO_DRY_RUN_FLAG="--dry-run"
    else
      SCENARIO_TARGET_NAME="$1"
      shift || true
      if [[ "${1:-}" == "--dry-run" ]]; then
        SCENARIO_DRY_RUN_FLAG="--dry-run"
      fi
    fi
  fi
}

handle_scenario_command() {
  shift || true
  local scenario_name="${1:-}"
  local target_name
  local dry_run_flag
  local file_path
  local export_path

  case "$scenario_name" in
    list)
      print_scenario_list
      ;;
    smoke-edit)
      shift || true
      if [[ "${1:-}" == "--dry-run" ]]; then
        set -- "$DEFAULT_HOST" "$DEFAULT_PSEUDO" "$DEFAULT_PASS" "--dry-run"
      fi
      run_remote_runtime_command "(mogan-test-smoke-edit)" "${1:-$DEFAULT_HOST}" "${2:-$DEFAULT_PSEUDO}" "${3:-$DEFAULT_PASS}" "${4:-}"
      ;;
    batch-smoke)
      shift || true
      scenario_target_and_dry_run "$@"
      scenario_run_batch "$SCENARIO_TARGET_NAME" "$SCENARIO_DRY_RUN_FLAG" \
        new-document -- write-text "hello from mogan-test" -- move-end -- insert-text "!" -- buffer-text
      ;;
    file-smoke)
      shift || true
      target_name="smoke"
      file_path="$DEFAULT_FILE_PATH"
      dry_run_flag=""
      if [[ $# -gt 0 ]]; then
        if [[ "${1:-}" == "--dry-run" ]]; then
          dry_run_flag="--dry-run"
        else
          target_name="$1"
          shift || true
          if [[ $# -gt 0 ]] && [[ "${1:-}" != "--dry-run" ]]; then
            file_path="$1"
            shift || true
          fi
          if [[ "${1:-}" == "--dry-run" ]]; then
            dry_run_flag="--dry-run"
          fi
        fi
      fi
      scenario_run_batch "$target_name" "$dry_run_flag" \
        new-document -- write-text "file smoke" -- save-as "$file_path" -- insert-text "!" -- revert-buffer -- buffer-text -- new-document -- close-buffer -- open-file "$file_path" -- buffer-text -- buffer-list
      ;;
    export-smoke)
      shift || true
      target_name="smoke"
      export_path="$DEFAULT_EXPORT_PATH"
      dry_run_flag=""
      if [[ $# -gt 0 ]]; then
        if [[ "${1:-}" == "--dry-run" ]]; then
          dry_run_flag="--dry-run"
        else
          target_name="$1"
          shift || true
          if [[ $# -gt 0 ]] && [[ "${1:-}" != "--dry-run" ]]; then
            export_path="$1"
            shift || true
          fi
          if [[ "${1:-}" == "--dry-run" ]]; then
            dry_run_flag="--dry-run"
          fi
        fi
      fi
      scenario_run_batch "$target_name" "$dry_run_flag" \
        new-document -- write-text "export smoke" -- export-buffer "$export_path"
      ;;
    style-smoke)
      shift || true
      scenario_target_and_dry_run "$@"
      scenario_run_batch "$SCENARIO_TARGET_NAME" "$SCENARIO_DRY_RUN_FLAG" \
        new-document -- set-main-style article -- set-document-language chinese -- add-style-package number-us -- remove-style-package number-us -- state
      ;;
    layout-smoke)
      shift || true
      scenario_target_and_dry_run "$@"
      scenario_run_batch "$SCENARIO_TARGET_NAME" "$SCENARIO_DRY_RUN_FLAG" \
        new-document -- set-page-medium papyrus -- set-page-type letter -- set-page-orientation landscape -- state
      ;;
    search-smoke)
      shift || true
      scenario_target_and_dry_run "$@"
      scenario_run_batch "$SCENARIO_TARGET_NAME" "$SCENARIO_DRY_RUN_FLAG" \
        new-document -- write-text "alpha beta alpha" -- search-set alpha -- search-state -- search-next -- search-prev -- search-last -- search-first -- replace-set gamma -- search-state -- replace-one -- replace-all -- buffer-text
      ;;
    history-smoke)
      shift || true
      scenario_target_and_dry_run "$@"
      scenario_run_batch "$SCENARIO_TARGET_NAME" "$SCENARIO_DRY_RUN_FLAG" \
        new-document -- insert-text "hello" -- undo -- redo -- clear-undo-history -- state
      ;;
    clipboard-smoke)
      shift || true
      scenario_target_and_dry_run "$@"
      scenario_run_batch "$SCENARIO_TARGET_NAME" "$SCENARIO_DRY_RUN_FLAG" \
        new-document -- write-text "hello" -- select-all -- copy -- new-document -- paste -- state
      ;;
    "")
      print_scenario_usage
      exit 1
      ;;
    *)
      echo "{\"status\":\"error\",\"message\":\"Unknown scenario: $scenario_name\"}" >&2
      exit 1
      ;;
  esac
}
