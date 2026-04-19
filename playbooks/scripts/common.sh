#!/bin/bash

set -euo pipefail

PLAYBOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$PLAYBOOKS_DIR/../.." && pwd)"
MOGAN_ROOT="${MOGAN_ROOT:-/home/mingshen/git/mogan}"
MOGAN_TEST_ROOT="$REPO_ROOT"
MOGANSTEM="${MOGANSTEM:-$MOGAN_ROOT/build/linux/x86_64/debug/moganstem}"
SERVER_RUNTIME="$MOGAN_TEST_ROOT/src/cli/runtime/mogan-server-runtime.scm"
CLI="$MOGAN_TEST_ROOT/bin/mogan-cli"
SERVER_LOG="${MOGAN_TEST_SERVER_LOG:-/tmp/mogan-playbook-server.log}"

log() {
  printf '[playbook] %s\n' "$*"
}

fail() {
  printf '[playbook][error] %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

check_env() {
  require_cmd timeout
  [[ -x "$CLI" ]] || fail "missing cli: $CLI"
  [[ -x "$MOGANSTEM" ]] || fail "missing moganstem: $MOGANSTEM"
}

server_running() {
  pgrep -f "moganstem -d -debug-bench -server" >/dev/null 2>&1 || \
    pgrep -f "moganstem .* -server .*mogan-server-runtime.scm" >/dev/null 2>&1
}

start_server_if_needed() {
  if server_running; then
    return 0
  fi

  log "starting mogan server"
  (
    cd "$MOGAN_ROOT"
    export TEXMACS_PATH="$MOGAN_ROOT/TeXmacs"
    nohup "$MOGANSTEM" -d -debug-bench -server \
      -x "(load \"$SERVER_RUNTIME\")" \
      >"$SERVER_LOG" 2>&1 &
  )

  for _ in $(seq 1 30); do
    if grep -q "Starting event loop" "$SERVER_LOG" 2>/dev/null; then
      return 0
    fi
    sleep 1
  done

  fail "server did not become ready; see $SERVER_LOG"
}

cli_try() {
  timeout "${MOGAN_PLAYBOOK_TIMEOUT:-20}" "$CLI" "$@"
}

ensure_connection() {
  if cli_try ping >/tmp/mogan-playbook-ping.out 2>/dev/null; then
    if grep -q 'pong' /tmp/mogan-playbook-ping.out; then
      return 0
    fi
  fi

  start_server_if_needed

  log "ensuring account exists"
  cli_try create-account >/tmp/mogan-playbook-account.out 2>&1 || true

  log "connecting runtime"
  cli_try connect >/tmp/mogan-playbook-connect.out 2>&1 || true

  cli_try ping >/tmp/mogan-playbook-ping.out 2>&1 || fail "ping failed after connect"
  grep -q 'pong' /tmp/mogan-playbook-ping.out || fail "unexpected ping output"
}

show_file_if_exists() {
  local path="$1"
  if [[ -f "$path" ]]; then
    ls -l "$path"
  else
    fail "missing output file: $path"
  fi
}
