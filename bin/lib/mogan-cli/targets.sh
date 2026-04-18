target_is_valid_name() {
  local name="${1-}"
  [[ -n "$name" ]] && [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]]
}

target_file_path() {
  local name="${1-}"
  printf '%s/%s.target' "$TARGET_DIR" "$name"
}

target_ensure_dir() {
  mkdir -p "$TARGET_DIR"
}

target_save_profile() {
  local name="$1"
  local host="$2"
  local pseudo="$3"
  local display_name="$4"
  local passwd="$5"
  local email="$6"
  local path

  if ! target_is_valid_name "$name"; then
    echo "{\"status\":\"error\",\"message\":\"Invalid target name: $name\"}" >&2
    return 1
  fi

  target_ensure_dir
  path="$(target_file_path "$name")"
  (
    umask 077
    {
      printf 'host\t%s\n' "$host"
      printf 'pseudo\t%s\n' "$pseudo"
      printf 'name\t%s\n' "$display_name"
      printf 'passwd\t%s\n' "$passwd"
      printf 'email\t%s\n' "$email"
    } > "$path"
  )
}

target_field_value() {
  local path="$1"
  local key="$2"
  awk -F '\t' -v key="$key" '$1 == key { sub("^[^\t]+\t", "", $0); print; exit }' "$path"
}

target_read_profile() {
  local name="$1"
  local path
  local host
  local pseudo
  local display_name
  local passwd
  local email

  if ! target_is_valid_name "$name"; then
    echo "{\"status\":\"error\",\"message\":\"Invalid target name: $name\"}" >&2
    return 1
  fi

  path="$(target_file_path "$name")"
  if [[ ! -f "$path" ]]; then
    echo "{\"status\":\"error\",\"message\":\"Target not found: $name\"}" >&2
    return 1
  fi

  host="$(target_field_value "$path" host)"
  pseudo="$(target_field_value "$path" pseudo)"
  display_name="$(target_field_value "$path" name)"
  passwd="$(target_field_value "$path" passwd)"
  email="$(target_field_value "$path" email)"

  printf '%s\t%s\t%s\t%s\t%s\n' \
    "${host:-$DEFAULT_HOST}" \
    "${pseudo:-$DEFAULT_PSEUDO}" \
    "${display_name:-$DEFAULT_NAME}" \
    "${passwd:-$DEFAULT_PASS}" \
    "${email:-$DEFAULT_EMAIL}"
}

target_show_profile() {
  local name="$1"
  local path
  local host
  local pseudo
  local display_name
  local passwd
  local email

  if ! target_is_valid_name "$name"; then
    echo "{\"status\":\"error\",\"message\":\"Invalid target name: $name\"}" >&2
    return 1
  fi

  path="$(target_file_path "$name")"
  if [[ ! -f "$path" ]]; then
    echo "{\"status\":\"error\",\"message\":\"Target not found: $name\"}" >&2
    return 1
  fi

  host="$(target_field_value "$path" host)"
  pseudo="$(target_field_value "$path" pseudo)"
  display_name="$(target_field_value "$path" name)"
  passwd="$(target_field_value "$path" passwd)"
  email="$(target_field_value "$path" email)"

  printf 'name=%s\nhost=%s\npseudo=%s\ndisplay_name=%s\npasswd=%s\nemail=%s\n' \
    "$name" \
    "${host:-$DEFAULT_HOST}" \
    "${pseudo:-$DEFAULT_PSEUDO}" \
    "${display_name:-$DEFAULT_NAME}" \
    "${passwd:-$DEFAULT_PASS}" \
    "${email:-$DEFAULT_EMAIL}"
}

target_list_profiles() {
  target_ensure_dir
  find "$TARGET_DIR" -maxdepth 1 -type f -name '*.target' -printf '%f\n' 2>/dev/null | sed 's/\.target$//' | sort
}

target_run_command() {
  local name="$1"
  shift

  local profile
  local host
  local pseudo
  local display_name
  local passwd
  local email

  profile="$(target_read_profile "$name")" || return 1
  IFS=$'\t' read -r host pseudo display_name passwd email <<< "$profile"
  MOGAN_TEST_HOST="$host" \
  MOGAN_TEST_PSEUDO="$pseudo" \
  MOGAN_TEST_NAME="$display_name" \
  MOGAN_TEST_PASS="$passwd" \
  MOGAN_TEST_EMAIL="$email" \
  MOGAN_TEST_DRY_RUN="${MOGAN_TEST_DRY_RUN:-0}" \
  "$0" "$@"
}

handle_target_command() {
  shift || true
  local target_action="${1:-}"
  local target_name

  case "$target_action" in
    save|add|open)
      target_name="${2:-}"
      require_target_name "$target_name"
      target_save_profile \
        "$target_name" \
        "${3:-$DEFAULT_HOST}" \
        "${4:-$DEFAULT_PSEUDO}" \
        "${5:-$DEFAULT_NAME}" \
        "${6:-$DEFAULT_PASS}" \
        "${7:-$DEFAULT_EMAIL}"
      ;;
    show)
      target_name="${2:-}"
      require_target_name "$target_name"
      target_show_profile "$target_name"
      ;;
    list)
      target_list_profiles
      ;;
    delete|remove)
      target_name="${2:-}"
      require_target_name "$target_name"
      if ! target_is_valid_name "$target_name"; then
        echo "{\"status\":\"error\",\"message\":\"Invalid target name: $target_name\"}" >&2
        exit 1
      fi
      rm -f "$(target_file_path "$target_name")"
      ;;
    run|use|exec)
      target_name="${2:-}"
      require_target_name "$target_name"
      if [[ $# -lt 3 ]]; then
        echo '{"status":"error","message":"Target run requires a command"}' >&2
        exit 1
      fi
      shift 2
      target_run_command "$target_name" "$@"
      ;;
    "")
      print_target_usage
      exit 1
      ;;
    *)
      echo "{\"status\":\"error\",\"message\":\"Unknown target action: $target_action\"}" >&2
      exit 1
      ;;
  esac
}

batch_run_step() {
  local target_name="$1"
  local dry_run="${2:-false}"
  local step_index="${3:-0}"
  shift 3

  local -a step_args=("$@")

  if [[ ${#step_args[@]} -eq 0 ]]; then
    echo '{"status":"error","message":"Empty batch step"}' >&2
    return 1
  fi

  printf '== batch step %s: ' "$step_index" >&2
  printf '%q ' "${step_args[@]}" >&2
  printf '\n' >&2

  if [[ "$dry_run" == "true" ]]; then
    MOGAN_TEST_DRY_RUN=1 target_run_command "$target_name" "${step_args[@]}"
    return $?
  fi

  target_run_command "$target_name" "${step_args[@]}"
}

handle_batch_command() {
  shift || true
  local target_name="${1:-}"
  local batch_dry_run="false"
  local current_step=()
  local step_index=0

  require_target_name "$target_name"
  shift || true

  if [[ "${MOGAN_TEST_DRY_RUN:-0}" == "1" ]] || [[ "${1:-}" == "--dry-run" ]]; then
    batch_dry_run="true"
    shift || true
  fi
  if [[ "${1:-}" == "--" ]]; then
    shift || true
  fi
  if [[ $# -eq 0 ]]; then
    echo '{"status":"error","message":"Batch requires at least one step"}' >&2
    exit 1
  fi

  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--" ]]; then
      if [[ ${#current_step[@]} -gt 0 ]]; then
        step_index=$((step_index + 1))
        batch_run_step "$target_name" "$batch_dry_run" "$step_index" "${current_step[@]}"
        current_step=()
      fi
    else
      current_step+=("$1")
    fi
    shift || true
  done

  if [[ ${#current_step[@]} -gt 0 ]]; then
    step_index=$((step_index + 1))
    batch_run_step "$target_name" "$batch_dry_run" "$step_index" "${current_step[@]}"
  fi
}
