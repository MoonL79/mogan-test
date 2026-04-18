handle_build_client() {
  shift || true
  cd "$MOGAN_ROOT"
  exec xmake b stem "$@"
}

handle_start_client() {
  shift || true

  if [[ "${1:-}" == "--server" ]] || [[ "${1:-}" == "--dry-run" ]] || [[ "${1:-}" == "--platform" ]]; then
    local binary_path
    local platform=""
    local runtime_expr="$DEFAULT_SERVER_RUNTIME_EXPR"
    local with_server="false"
    local dry_run="false"
    local -a cmd

    binary_path="$(ensure_built_binary)"

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --server)
          with_server="true"
          ;;
        --platform)
          platform="${2:-}"
          shift
          ;;
        --without-runtime)
          runtime_expr=""
          ;;
        --dry-run)
          dry_run="true"
          ;;
      esac
      shift
    done

    cmd=(env "TEXMACS_PATH=$TEXMACS_PATH_DIR" "$binary_path")
    if [[ -n "$platform" ]]; then
      cmd+=(-platform "$platform")
    fi
    cmd+=(-d -debug-bench)
    if [[ "$with_server" == "true" ]]; then
      cmd+=(-server)
    fi
    if [[ -n "$runtime_expr" ]]; then
      cmd+=(-x "$runtime_expr")
    fi

    if [[ "$dry_run" == "true" ]]; then
      printf 'cd %s &&' "$MOGAN_ROOT"
      printf ' %q' "${cmd[@]}"
      printf '\n'
      exit 0
    fi

    cd "$MOGAN_ROOT"
    exec "${cmd[@]}"
  fi

  cd "$MOGAN_ROOT"
  exec xmake r stem "$@"
}

handle_start_server() {
  shift || true
  exec "$0" start-client --server "$@"
}

handle_exec_internal() {
  shift || true
  local runtime_expr="${1:-}"
  local dry_run_flag=""

  ensure_built_binary >/dev/null

  if [[ "$runtime_expr" == "--dry-run" ]] || [[ -z "$runtime_expr" ]]; then
    runtime_expr="$DEFAULT_RUNTIME_EXPR"
  fi
  if [[ "${2:-}" == "--dry-run" ]] || [[ "${1:-}" == "--dry-run" ]]; then
    dry_run_flag="--dry-run"
  fi

  run_or_print_runtime_command "$runtime_expr" "$dry_run_flag"
}

handle_create_account() {
  shift || true
  if [[ "${1:-}" == "--dry-run" ]]; then
    set -- "$DEFAULT_HOST" "$DEFAULT_PSEUDO" "$DEFAULT_NAME" "$DEFAULT_PASS" "$DEFAULT_EMAIL" "--dry-run"
  fi

  local server_name="${1:-$DEFAULT_HOST}"
  local pseudo="${2:-$DEFAULT_PSEUDO}"
  local name="${3:-$DEFAULT_NAME}"
  local passwd="${4:-$DEFAULT_PASS}"
  local email="${5:-$DEFAULT_EMAIL}"
  local runtime_expr
  local dry_run_flag=""

  if [[ "${6:-}" == "--dry-run" ]] || [[ "${1:-}" == "--dry-run" ]]; then
    dry_run_flag="--dry-run"
  fi

  runtime_expr="(load \"$RUNTIME_SCRIPT\") (mogan-test-create-account \"$(scheme_escape "$server_name")\" \"$(scheme_escape "$pseudo")\" \"$(scheme_escape "$name")\" \"$(scheme_escape "$passwd")\" \"$(scheme_escape "$email")\")"
  run_or_print_runtime_command "$runtime_expr" "$dry_run_flag"
}

handle_connect() {
  shift || true
  if [[ "${1:-}" == "--dry-run" ]]; then
    set -- "$DEFAULT_HOST" "$DEFAULT_PSEUDO" "$DEFAULT_PASS" "--dry-run"
  fi

  local server_name="${1:-$DEFAULT_HOST}"
  local pseudo="${2:-$DEFAULT_PSEUDO}"
  local passwd="${3:-$DEFAULT_PASS}"
  local runtime_expr
  local dry_run_flag=""

  if [[ "${4:-}" == "--dry-run" ]] || [[ "${1:-}" == "--dry-run" ]]; then
    dry_run_flag="--dry-run"
  fi

  runtime_expr="(load \"$RUNTIME_SCRIPT\") (mogan-test-connect \"$(scheme_escape "$server_name")\" \"$(scheme_escape "$pseudo")\" \"$(scheme_escape "$passwd")\")"
  run_or_print_runtime_command "$runtime_expr" "$dry_run_flag"
}

handle_basic_remote_command() {
  local remote_command="$1"
  shift

  local dry_run_flag="${4:-}"
  if [[ "${1:-}" == "--dry-run" ]]; then
    set -- "$DEFAULT_HOST" "$DEFAULT_PSEUDO" "$DEFAULT_PASS" "--dry-run"
    dry_run_flag="--dry-run"
  elif [[ "${MOGAN_TEST_DRY_RUN:-0}" == "1" ]]; then
    dry_run_flag="--dry-run"
  fi

  run_remote_runtime_command "$remote_command" "${1:-$DEFAULT_HOST}" "${2:-$DEFAULT_PSEUDO}" "${3:-$DEFAULT_PASS}" "$dry_run_flag"
}

handle_buffer_command() {
  shift || true
  case "$command_name" in
    buffer-list) handle_basic_remote_command "(mogan-test-buffer-list)" "$@" ;;
    revert-buffer) handle_basic_remote_command "(mogan-test-revert-buffer)" "$@" ;;
    close-buffer) handle_basic_remote_command "(mogan-test-close-buffer)" "$@" ;;
  esac
}

handle_open_save_export_command() {
  shift || true
  local dry_run_flag=""
  local default_path="$DEFAULT_FILE_PATH"
  local file_path
  local remote_command

  if [[ "$command_name" == "export-buffer" ]]; then
    default_path="$DEFAULT_EXPORT_PATH"
  fi

  if [[ "${1:-}" == "--dry-run" ]]; then
    file_path="$default_path"
    dry_run_flag="--dry-run"
  else
    file_path="${1:-}"
    if [[ -z "$file_path" ]]; then
      if [[ "$command_name" == "export-buffer" ]]; then
        echo '{"status":"error","message":"Export path is required"}' >&2
      else
        echo '{"status":"error","message":"File path is required"}' >&2
      fi
      exit 1
    fi
    if [[ "${2:-}" == "--dry-run" ]]; then
      dry_run_flag="--dry-run"
    fi
  fi

  if [[ "${MOGAN_TEST_DRY_RUN:-0}" == "1" ]]; then
    dry_run_flag="--dry-run"
  fi

  case "$command_name" in
    open-file) remote_command="(mogan-test-open-file \"$(scheme_escape "$file_path")\")" ;;
    save-as) remote_command="(mogan-test-save-as \"$(scheme_escape "$file_path")\")" ;;
    export-buffer) remote_command="(mogan-test-export-buffer \"$(scheme_escape "$file_path")\")" ;;
  esac

  run_remote_runtime_command "$remote_command" "$DEFAULT_HOST" "$DEFAULT_PSEUDO" "$DEFAULT_PASS" "$dry_run_flag"
}

handle_value_remote_command() {
  local missing_message="$1"
  local remote_builder="$2"
  shift 2

  local dry_run_flag=""
  local server_name
  local pseudo
  local passwd
  local value
  local remote_command

  if [[ "${MOGAN_TEST_DRY_RUN:-0}" == "1" ]] || [[ "${2:-}" == "--dry-run" ]] || [[ "${5:-}" == "--dry-run" ]]; then
    dry_run_flag="--dry-run"
  fi

  if [[ $# -eq 1 ]]; then
    server_name="$DEFAULT_HOST"
    pseudo="$DEFAULT_PSEUDO"
    passwd="$DEFAULT_PASS"
    value="${1:-}"
  elif [[ $# -eq 2 ]] && [[ "${2:-}" == "--dry-run" ]]; then
    server_name="$DEFAULT_HOST"
    pseudo="$DEFAULT_PSEUDO"
    passwd="$DEFAULT_PASS"
    value="${1:-}"
  else
    if [[ $# -lt 4 ]]; then
      echo "{\"status\":\"error\",\"message\":\"$missing_message\"}" >&2
      exit 1
    fi
    server_name="${1:-$DEFAULT_HOST}"
    pseudo="${2:-$DEFAULT_PSEUDO}"
    passwd="${3:-$DEFAULT_PASS}"
    value="${4:-}"
  fi

  if [[ "$value" == "--dry-run" ]]; then
    echo "{\"status\":\"error\",\"message\":\"$missing_message\"}" >&2
    exit 1
  fi

  remote_command="$("$remote_builder" "$value")"
  run_remote_runtime_command "$remote_command" "$server_name" "$pseudo" "$passwd" "$dry_run_flag"
}

build_style_remote_command() {
  local value="$1"
  case "$command_name" in
    set-main-style) printf '(mogan-test-set-main-style "%s")' "$(scheme_escape "$value")" ;;
    set-document-language) printf '(mogan-test-set-document-language "%s")' "$(scheme_escape "$value")" ;;
    add-style-package) printf '(mogan-test-add-style-package "%s")' "$(scheme_escape "$value")" ;;
    remove-style-package) printf '(mogan-test-remove-style-package "%s")' "$(scheme_escape "$value")" ;;
  esac
}

build_page_remote_command() {
  local value="$1"
  case "$command_name" in
    set-page-medium) printf '(mogan-test-set-page-medium "%s")' "$(scheme_escape "$value")" ;;
    set-page-type) printf '(mogan-test-set-page-type "%s")' "$(scheme_escape "$value")" ;;
    set-page-orientation) printf '(mogan-test-set-page-orientation "%s")' "$(scheme_escape "$value")" ;;
  esac
}

build_search_text_remote_command() {
  local value="$1"
  case "$command_name" in
    search-set) printf '(mogan-test-search-set "%s")' "$(scheme_escape "$value")" ;;
    replace-set) printf '(mogan-test-replace-set "%s")' "$(scheme_escape "$value")" ;;
  esac
}

handle_search_action_command() {
  shift || true
  case "$command_name" in
    search-state) handle_basic_remote_command "(mogan-test-search-state)" "$@" ;;
    search-next) handle_basic_remote_command "(mogan-test-search-next)" "$@" ;;
    search-prev) handle_basic_remote_command "(mogan-test-search-prev)" "$@" ;;
    search-first) handle_basic_remote_command "(mogan-test-search-first)" "$@" ;;
    search-last) handle_basic_remote_command "(mogan-test-search-last)" "$@" ;;
    replace-one) handle_basic_remote_command "(mogan-test-replace-one)" "$@" ;;
    replace-all) handle_basic_remote_command "(mogan-test-replace-all)" "$@" ;;
  esac
}

handle_simple_control_command() {
  shift || true
  case "$command_name" in
    ping) handle_basic_remote_command "(mogan-test-ping)" "$@" ;;
    current-buffer) handle_basic_remote_command "(mogan-test-current-buffer)" "$@" ;;
    new-document) handle_basic_remote_command "(mogan-test-new-document)" "$@" ;;
    buffer-text) handle_basic_remote_command "(mogan-test-buffer-text)" "$@" ;;
    state) handle_basic_remote_command "(mogan-test-state)" "$@" ;;
    move-left) handle_basic_remote_command "(mogan-test-move-left)" "$@" ;;
    move-right) handle_basic_remote_command "(mogan-test-move-right)" "$@" ;;
    move-up) handle_basic_remote_command "(mogan-test-move-up)" "$@" ;;
    move-down) handle_basic_remote_command "(mogan-test-move-down)" "$@" ;;
    move-start) handle_basic_remote_command "(mogan-test-move-start)" "$@" ;;
    move-end) handle_basic_remote_command "(mogan-test-move-end)" "$@" ;;
    move-start-line) handle_basic_remote_command "(mogan-test-move-start-line)" "$@" ;;
    move-end-line) handle_basic_remote_command "(mogan-test-move-end-line)" "$@" ;;
    move-start-paragraph) handle_basic_remote_command "(mogan-test-move-start-paragraph)" "$@" ;;
    move-end-paragraph) handle_basic_remote_command "(mogan-test-move-end-paragraph)" "$@" ;;
    move-word-left) handle_basic_remote_command "(mogan-test-move-word-left)" "$@" ;;
    move-word-right) handle_basic_remote_command "(mogan-test-move-word-right)" "$@" ;;
    select-all) handle_basic_remote_command "(mogan-test-select-all)" "$@" ;;
    select-start) handle_basic_remote_command "(mogan-test-select-start)" "$@" ;;
    select-end) handle_basic_remote_command "(mogan-test-select-end)" "$@" ;;
    clear-selection) handle_basic_remote_command "(mogan-test-clear-selection)" "$@" ;;
    undo) handle_basic_remote_command "(mogan-test-history-undo)" "$@" ;;
    redo) handle_basic_remote_command "(mogan-test-history-redo)" "$@" ;;
    copy) handle_basic_remote_command "(mogan-test-clipboard-copy)" "$@" ;;
    cut) handle_basic_remote_command "(mogan-test-clipboard-cut)" "$@" ;;
    paste) handle_basic_remote_command "(mogan-test-clipboard-paste)" "$@" ;;
    clear-undo-history) handle_basic_remote_command "(mogan-test-clear-history)" "$@" ;;
    insert-return) handle_basic_remote_command "(mogan-test-insert-return)" "$@" ;;
    exit-right) handle_basic_remote_command "(mogan-test-structured-exit-right)" "$@" ;;
    delete-left) handle_basic_remote_command "(mogan-test-delete-left)" "$@" ;;
    delete-right) handle_basic_remote_command "(mogan-test-delete-right)" "$@" ;;
    save-buffer) handle_basic_remote_command "(mogan-test-save-buffer)" "$@" ;;
  esac
}

handle_write_text() {
  shift || true
  local text
  local server_name
  local pseudo
  local passwd
  local dry_run_flag=""

  if [[ "${1:-}" == "--dry-run" ]]; then
    set -- "hello from mogan-test" "$DEFAULT_HOST" "$DEFAULT_PSEUDO" "$DEFAULT_PASS" "--dry-run"
    dry_run_flag="--dry-run"
  elif [[ "${MOGAN_TEST_DRY_RUN:-0}" == "1" ]]; then
    dry_run_flag="--dry-run"
  fi

  if [[ $# -eq 0 ]]; then
    text="hello from mogan-test"
    server_name="$DEFAULT_HOST"
    pseudo="$DEFAULT_PSEUDO"
    passwd="$DEFAULT_PASS"
  elif [[ $# -eq 2 ]] && [[ "${2:-}" == "--dry-run" ]]; then
    text="${1:-hello from mogan-test}"
    server_name="$DEFAULT_HOST"
    pseudo="$DEFAULT_PSEUDO"
    passwd="$DEFAULT_PASS"
    dry_run_flag="--dry-run"
  else
    text="${1:-hello from mogan-test}"
    server_name="${2:-$DEFAULT_HOST}"
    pseudo="${3:-$DEFAULT_PSEUDO}"
    passwd="${4:-$DEFAULT_PASS}"
    if [[ "${5:-}" == "--dry-run" ]]; then
      dry_run_flag="--dry-run"
    fi
  fi

  run_remote_runtime_command "(mogan-test-write-text-b64 \"$(base64_encode_text "$text")\")" "$server_name" "$pseudo" "$passwd" "$dry_run_flag"
}

handle_stream_text() {
  shift || true
  local chunk_size=256
  local source_path=""
  local start_mode=""
  local dry_run_flag=""
  local server_name="$DEFAULT_HOST"
  local pseudo="$DEFAULT_PSEUDO"
  local passwd="$DEFAULT_PASS"
  local last_output=""
  local chunk=""
  local chunk_index=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --chunk-size)
        if [[ $# -lt 2 ]]; then
          echo '{"status":"error","message":"--chunk-size requires a value"}' >&2
          exit 1
        fi
        chunk_size="$2"
        shift 2
        ;;
      --file)
        if [[ $# -lt 2 ]]; then
          echo '{"status":"error","message":"--file requires a path"}' >&2
          exit 1
        fi
        source_path="$2"
        shift 2
        ;;
      --new-document|--replace)
        if [[ -n "$start_mode" ]] && [[ "$start_mode" != "$1" ]]; then
          echo '{"status":"error","message":"Use only one of --new-document or --replace"}' >&2
          exit 1
        fi
        start_mode="$1"
        shift
        ;;
      --dry-run)
        dry_run_flag="--dry-run"
        shift
        ;;
      --help)
        cat <<'EOF'
Usage: mogan-cli stream-text [--new-document|--replace] [--chunk-size N] [--file PATH] [host [pseudo [pass]]] [--dry-run]
Reads text from stdin or --file and sends it to the current Mogan buffer in incremental insert-text chunks.
EOF
        exit 0
        ;;
      *)
        break
        ;;
    esac
  done

  if ! [[ "$chunk_size" =~ ^[1-9][0-9]*$ ]]; then
    echo '{"status":"error","message":"chunk size must be a positive integer"}' >&2
    exit 1
  fi

  server_name="${1:-$DEFAULT_HOST}"
  pseudo="${2:-$DEFAULT_PSEUDO}"
  passwd="${3:-$DEFAULT_PASS}"

  if [[ -n "$source_path" ]]; then
    if [[ ! -f "$source_path" ]]; then
      echo "{\"status\":\"error\",\"message\":\"file not found: $source_path\"}" >&2
      exit 1
    fi
    exec 3<"$source_path"
  else
    if [[ -t 0 ]]; then
      echo '{"status":"error","message":"stream-text expects stdin or --file PATH"}' >&2
      exit 1
    fi
    exec 3<&0
  fi

  if [[ "$start_mode" == "--new-document" ]]; then
    last_output="$(run_remote_runtime_command "(mogan-test-new-document)" "$server_name" "$pseudo" "$passwd" "$dry_run_flag")"
  elif [[ "$start_mode" == "--replace" ]]; then
    last_output="$(run_remote_runtime_command "(mogan-test-write-text-b64 \"$(base64_encode_text "")\")" "$server_name" "$pseudo" "$passwd" "$dry_run_flag")"
  fi

  while IFS= read -r -N "$chunk_size" chunk <&3 || [[ -n "$chunk" ]]; do
    chunk_index=$((chunk_index + 1))
    printf '== stream chunk %s (%s bytes)\n' "$chunk_index" "${#chunk}" >&2
    last_output="$(run_remote_runtime_command "(mogan-test-insert-text-b64 \"$(base64_encode_text "$chunk")\")" "$server_name" "$pseudo" "$passwd" "$dry_run_flag")"
    chunk=""
  done

  exec 3<&-

  if [[ -z "$last_output" ]]; then
    last_output="$(run_remote_runtime_command "(mogan-test-buffer-text)" "$server_name" "$pseudo" "$passwd" "$dry_run_flag")"
  fi

  printf '%s\n' "$last_output"
}

handle_control_value_command() {
  shift || true
  local control_value
  local server_name
  local pseudo
  local passwd
  local dry_run_flag="${5:-}"
  local default_value
  local remote_command

  case "$command_name" in
    move-to-line|move-to-column) default_value="1" ;;
    insert-text) default_value="hello from mogan-test" ;;
    switch-buffer) default_value="tmfs://dummy" ;;
  esac

  if [[ "${1:-}" == "--dry-run" ]]; then
    set -- "$default_value" "$DEFAULT_HOST" "$DEFAULT_PSEUDO" "$DEFAULT_PASS" "--dry-run"
    dry_run_flag="--dry-run"
  elif [[ "${MOGAN_TEST_DRY_RUN:-0}" == "1" ]]; then
    dry_run_flag="--dry-run"
  fi

  control_value="${1:-$default_value}"
  server_name="${2:-$DEFAULT_HOST}"
  pseudo="${3:-$DEFAULT_PSEUDO}"
  passwd="${4:-$DEFAULT_PASS}"

  case "$command_name" in
    move-to-line) remote_command="(mogan-test-move-to-line \"$(scheme_escape "$control_value")\")" ;;
    move-to-column) remote_command="(mogan-test-move-to-column \"$(scheme_escape "$control_value")\")" ;;
    insert-text) remote_command="(mogan-test-insert-text-b64 \"$(base64_encode_text "$control_value")\")" ;;
    switch-buffer) remote_command="(mogan-test-switch-buffer \"$(scheme_escape "$control_value")\")" ;;
  esac

  run_remote_runtime_command "$remote_command" "$server_name" "$pseudo" "$passwd" "$dry_run_flag"
}

handle_insert_basic_command() {
  shift || true
  local dry_run_flag=""
  local arg1=""
  local arg2=""
  local value=""
  local server_name
  local pseudo
  local passwd
  local remote_command

  if [[ "${MOGAN_TEST_DRY_RUN:-0}" == "1" ]] || [[ "${2:-}" == "--dry-run" ]]; then
    dry_run_flag="--dry-run"
  fi

  case "$command_name" in
    insert-fraction)
      if [[ $# -lt 2 ]]; then
        echo '{"status":"error","message":"Usage: insert-fraction <numerator> <denominator>"}' >&2
        exit 1
      fi
      arg1="${1:-}"
      arg2="${2:-}"
      server_name="${3:-$DEFAULT_HOST}"
      pseudo="${4:-$DEFAULT_PSEUDO}"
      passwd="${5:-$DEFAULT_PASS}"
      if [[ "${6:-}" == "--dry-run" ]]; then
        dry_run_flag="--dry-run"
      fi
      ;;
    insert-sup)
      if [[ $# -lt 2 ]]; then
        echo '{"status":"error","message":"Usage: insert-sup <sub> <sup>"}' >&2
        exit 1
      fi
      arg1="${1:-}"
      arg2="${2:-}"
      server_name="${3:-$DEFAULT_HOST}"
      pseudo="${4:-$DEFAULT_PSEUDO}"
      passwd="${5:-$DEFAULT_PASS}"
      if [[ "${6:-}" == "--dry-run" ]]; then
        dry_run_flag="--dry-run"
      fi
      ;;
    *)
      if [[ $# -lt 1 ]]; then
        echo '{"status":"error","message":"Usage: insert-<command> <value>"}' >&2
        exit 1
      fi
      value="${1:-}"
      server_name="${2:-$DEFAULT_HOST}"
      pseudo="${3:-$DEFAULT_PSEUDO}"
      passwd="${4:-$DEFAULT_PASS}"
      if [[ "${5:-}" == "--dry-run" ]]; then
        dry_run_flag="--dry-run"
      fi
      ;;
  esac

  case "$command_name" in
    insert-equation) remote_command="(mogan-test-insert-equation \"$(scheme_escape "$value")\")" ;;
    insert-inline-equation) remote_command="(mogan-test-insert-inline-equation \"$(scheme_escape "$value")\")" ;;
    insert-fraction) remote_command="(mogan-test-insert-fraction \"$(scheme_escape "$arg1")\" \"$(scheme_escape "$arg2")\")" ;;
    insert-sqrt) remote_command="(mogan-test-insert-sqrt \"$(scheme_escape "$value")\")" ;;
    insert-sup) remote_command="(mogan-test-insert-sup \"$(scheme_escape "$arg1")\" \"$(scheme_escape "$arg2")\")" ;;
    insert-sub) remote_command="(mogan-test-insert-sub \"$(scheme_escape "$value")\")" ;;
    insert-bold) remote_command="(mogan-test-insert-bold-b64 \"$(base64_encode_text "$value")\")" ;;
    insert-italic) remote_command="(mogan-test-insert-italic-b64 \"$(base64_encode_text "$value")\")" ;;
    insert-code) remote_command="(mogan-test-insert-code-b64 \"$(base64_encode_text "$value")\")" ;;
    insert-section) remote_command="(mogan-test-insert-section-b64 \"$(base64_encode_text "$value")\")" ;;
    insert-subsection) remote_command="(mogan-test-insert-subsection-b64 \"$(base64_encode_text "$value")\")" ;;
    insert-subsubsection) remote_command="(mogan-test-insert-subsubsection-b64 \"$(base64_encode_text "$value")\")" ;;
  esac

  run_remote_runtime_command "$remote_command" "$server_name" "$pseudo" "$passwd" "$dry_run_flag"
}

handle_insert_complex_command() {
  shift || true
  local dry_run_flag=""
  local arg1
  local arg2
  local arg3
  local server_name
  local pseudo
  local passwd
  local remote_command

  if [[ "${MOGAN_TEST_DRY_RUN:-0}" == "1" ]]; then
    dry_run_flag="--dry-run"
  fi

  case "$command_name" in
    insert-matrix|insert-sum|insert-integral)
      if [[ $# -lt 3 ]]; then
        echo '{"status":"error","message":"Usage: insert-<command> <arg1> <arg2> <arg3> [server pseudo pass] [--dry-run]"}' >&2
        exit 1
      fi
      arg1="${1:-}"
      arg2="${2:-}"
      arg3="${3:-}"
      if [[ "${4:-}" == "--dry-run" ]]; then
        server_name="$DEFAULT_HOST"
        pseudo="$DEFAULT_PSEUDO"
        passwd="$DEFAULT_PASS"
        dry_run_flag="--dry-run"
      else
        server_name="${4:-$DEFAULT_HOST}"
        pseudo="${5:-$DEFAULT_PSEUDO}"
        passwd="${6:-$DEFAULT_PASS}"
        if [[ "${7:-}" == "--dry-run" ]]; then
          dry_run_flag="--dry-run"
        fi
      fi
      ;;
    insert-table|insert-link)
      if [[ $# -lt 2 ]]; then
        echo '{"status":"error","message":"Usage: insert-<command> <arg1> <arg2> [server pseudo pass] [--dry-run]"}' >&2
        exit 1
      fi
      arg1="${1:-}"
      arg2="${2:-}"
      arg3=""
      if [[ "${3:-}" == "--dry-run" ]]; then
        server_name="$DEFAULT_HOST"
        pseudo="$DEFAULT_PSEUDO"
        passwd="$DEFAULT_PASS"
        dry_run_flag="--dry-run"
      else
        server_name="${3:-$DEFAULT_HOST}"
        pseudo="${4:-$DEFAULT_PSEUDO}"
        passwd="${5:-$DEFAULT_PASS}"
        if [[ "${6:-}" == "--dry-run" ]]; then
          dry_run_flag="--dry-run"
        fi
      fi
      ;;
  esac

  case "$command_name" in
    insert-matrix) remote_command="(mogan-test-insert-matrix \"$(scheme_escape "$arg1")\" \"$(scheme_escape "$arg2")\" \"$(scheme_escape "$arg3")\")" ;;
    insert-sum) remote_command="(mogan-test-insert-sum \"$(scheme_escape "$arg1")\" \"$(scheme_escape "$arg2")\" \"$(scheme_escape "$arg3")\")" ;;
    insert-integral) remote_command="(mogan-test-insert-integral \"$(scheme_escape "$arg1")\" \"$(scheme_escape "$arg2")\" \"$(scheme_escape "$arg3")\")" ;;
    insert-table) remote_command="(mogan-test-insert-table \"$(scheme_escape "$arg1")\" \"$(scheme_escape "$arg2")\")" ;;
    insert-link) remote_command="(mogan-test-insert-link-b64 \"$(scheme_escape "$arg1")\" \"$(base64_encode_text "$arg2")\")" ;;
  esac

  run_remote_runtime_command "$remote_command" "$server_name" "$pseudo" "$passwd" "$dry_run_flag"
}
