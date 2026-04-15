#!/bin/bash

set -euo pipefail

CLI="./mogan-cli"
FAILED=0
LIVE_MODE=0
EXPECT_SERVICES=0

for arg in "$@"; do
  case "$arg" in
    --live)
      LIVE_MODE=1
      ;;
    --expect-services)
      EXPECT_SERVICES=1
      ;;
  esac
done

LIVE_HOST="${MOGAN_TEST_HOST:-127.0.0.1}"
LIVE_PSEUDO="${MOGAN_TEST_PSEUDO:-test-user}"
LIVE_NAME="${MOGAN_TEST_NAME:-Test User}"
LIVE_PASS="${MOGAN_TEST_PASS:-test-pass}"
LIVE_EMAIL="${MOGAN_TEST_EMAIL:-test@example.com}"
TARGET_TEST_DIR="$(mktemp -d)"
FILE_TEST_PATH="$(mktemp /tmp/mogan-test-file-XXXX.tm)"

cleanup() {
  rm -rf "$TARGET_TEST_DIR"
  rm -f "$FILE_TEST_PATH"
}

trap cleanup EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
  echo -e "${RED}FAIL${NC}: $1"
  FAILED=$((FAILED + 1))
}

echo "=== Mogan Test Platform Validation ==="
echo ""

echo "Test 1: CLI script exists..."
if [[ -f "$CLI" ]]; then
  pass "CLI script exists"
else
  fail "CLI script not found at $CLI"
fi

echo "Test 2: CLI script is executable..."
if [[ -x "$CLI" ]]; then
  pass "CLI script is executable"
else
  fail "CLI script is not executable"
fi

echo "Test 3: Scheme runtime files exist..."
if [[ -f "./mogan-cli.scm" ]] &&
   [[ -f "./mogan-runtime.scm" ]] &&
   [[ -f "./mogan-server-runtime.scm" ]]; then
  pass "CLI and runtime Scheme files exist"
else
  fail "Required Scheme files are missing"
fi

echo "Test 4: CLI returns usage without arguments..."
if $CLI 2>&1 | grep -q "Usage:"; then
  pass "Usage message displayed"
else
  fail "Usage message not displayed"
fi

echo "Test 5: Status command returns JSON..."
STATUS_OUTPUT=$($CLI status 2>&1) || true
if echo "$STATUS_OUTPUT" | grep -q '"status"'; then
  pass "Status output contains status field"
else
  fail "Status output missing status field"
fi

echo "Test 6: Status reports build and server-capable startup paths..."
if echo "$STATUS_OUTPUT" | grep -q '"build_command":"xmake b stem"' &&
   echo "$STATUS_OUTPUT" | grep -q '"run_command":"xmake r stem"' &&
   echo "$STATUS_OUTPUT" | grep -q '"start_server_command"'; then
  pass "Status reports both full-client and server-capable startup paths"
else
  fail "Status output missing startup path details: $STATUS_OUTPUT"
fi

echo "Test 7: Workflow command reports the explicit server-first workflow..."
WORKFLOW_OUTPUT=$($CLI workflow 2>&1) || true
if echo "$WORKFLOW_OUTPUT" | grep -q 'create-account' &&
   echo "$WORKFLOW_OUTPUT" | grep -q 'start-server' &&
   echo "$WORKFLOW_OUTPUT" | grep -q 'mogan-server-runtime.scm'; then
  pass "Workflow reports the explicit server startup and runtime requirement"
else
  fail "Workflow output missing the expected explicit server workflow: $WORKFLOW_OUTPUT"
fi

echo "Test 8: Status reports the internal runtime dispatch path..."
if echo "$STATUS_OUTPUT" | grep -q '"internal_command":"TEXMACS_PATH=\\/home\\/mingshen\\/git\\/mogan\\/TeXmacs <moganstem> -d -debug-bench -x <scheme>"' &&
   echo "$STATUS_OUTPUT" | grep -q '"mogan_layer"'; then
  pass "Status exposes the Mogan internal Scheme dispatch path"
else
  fail "Status does not expose the internal runtime dispatch path: $STATUS_OUTPUT"
fi

echo "Test 9: start-server dry-run builds the connectable server command..."
START_SERVER_OUTPUT=$($CLI start-server --dry-run 2>&1) || true
if echo "$START_SERVER_OUTPUT" | grep -q 'moganstem' &&
   echo "$START_SERVER_OUTPUT" | grep -q -- '-server' &&
   echo "$START_SERVER_OUTPUT" | grep -q 'mogan-server-runtime.scm'; then
  pass "start-server dry-run prints the connectable server command"
else
  fail "start-server dry-run did not print the expected server command: $START_SERVER_OUTPUT"
fi

echo "Test 10: exec-internal dry-run builds the runtime command..."
INTERNAL_OUTPUT=$($CLI exec-internal --dry-run 2>&1) || true
if echo "$INTERNAL_OUTPUT" | grep -q 'moganstem' &&
   echo "$INTERNAL_OUTPUT" | grep -q -- '-x'; then
  pass "exec-internal dry-run prints the Mogan runtime command"
else
  fail "exec-internal dry-run did not print the expected command: $INTERNAL_OUTPUT"
fi

echo "Test 11: connect dry-run builds the remote-login command..."
CONNECT_OUTPUT=$($CLI connect --dry-run 2>&1) || true
if echo "$CONNECT_OUTPUT" | grep -q 'mogan-test-connect' &&
   echo "$CONNECT_OUTPUT" | grep -q 'moganstem'; then
  pass "connect dry-run prints the remote-login runtime command"
else
  fail "connect dry-run did not print the expected remote-login command: $CONNECT_OUTPUT"
fi

echo "Test 12: create-account dry-run builds the account command..."
CREATE_ACCOUNT_OUTPUT=$($CLI create-account --dry-run 2>&1) || true
if echo "$CREATE_ACCOUNT_OUTPUT" | grep -q 'mogan-test-create-account' &&
   echo "$CREATE_ACCOUNT_OUTPUT" | grep -q 'moganstem'; then
  pass "create-account dry-run prints the account creation command"
else
  fail "create-account dry-run did not print the expected command: $CREATE_ACCOUNT_OUTPUT"
fi

echo "Test 13: target profiles store and replay runtime defaults..."
TARGET_SAVE_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI target save smoke "$LIVE_HOST" "$LIVE_PSEUDO" "$LIVE_NAME" "$LIVE_PASS" "$LIVE_EMAIL" 2>&1) || true
TARGET_SHOW_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI target show smoke 2>&1) || true
TARGET_LIST_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI target list 2>&1) || true
TARGET_RUN_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI target run smoke state --dry-run 2>&1) || true
TARGET_SCENARIO_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI target run smoke scenario smoke-edit --dry-run 2>&1) || true
if [[ -f "$TARGET_TEST_DIR/smoke.target" ]] &&
   echo "$TARGET_SHOW_OUTPUT" | grep -q "host=$LIVE_HOST" &&
   echo "$TARGET_SHOW_OUTPUT" | grep -q "pseudo=$LIVE_PSEUDO" &&
   echo "$TARGET_LIST_OUTPUT" | grep -q 'smoke' &&
   echo "$TARGET_RUN_OUTPUT" | grep -q 'mogan-test-state' &&
   echo "$TARGET_SCENARIO_OUTPUT" | grep -q 'mogan-test-smoke-edit'; then
  pass "Target profiles can be saved, shown, listed, and replayed"
else
  fail "Target profile workflow failed: $TARGET_SAVE_OUTPUT | $TARGET_SHOW_OUTPUT | $TARGET_LIST_OUTPUT | $TARGET_RUN_OUTPUT | $TARGET_SCENARIO_OUTPUT"
fi

echo "Test 14: batch dry-runs chain low-level commands..."
BATCH_DRY_RUN_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI batch smoke --dry-run -- new-document -- insert-text "hello from mogan-test" -- move-end -- insert-text "!" -- buffer-text 2>&1) || true
SCENARIO_BATCH_DRY_RUN_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI scenario batch-smoke smoke --dry-run 2>&1) || true
SCENARIO_HISTORY_DRY_RUN_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI scenario history-smoke smoke --dry-run 2>&1) || true
SCENARIO_CLIPBOARD_DRY_RUN_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI scenario clipboard-smoke smoke --dry-run 2>&1) || true
if echo "$BATCH_DRY_RUN_OUTPUT" | grep -q 'mogan-test-new-document' &&
   echo "$BATCH_DRY_RUN_OUTPUT" | grep -q 'mogan-test-move-end' &&
   echo "$BATCH_DRY_RUN_OUTPUT" | grep -q 'mogan-test-insert-text' &&
   echo "$BATCH_DRY_RUN_OUTPUT" | grep -q 'mogan-test-buffer-text' &&
   echo "$SCENARIO_BATCH_DRY_RUN_OUTPUT" | grep -q 'mogan-test-new-document' &&
   echo "$SCENARIO_BATCH_DRY_RUN_OUTPUT" | grep -q 'mogan-test-buffer-text' &&
    echo "$SCENARIO_HISTORY_DRY_RUN_OUTPUT" | grep -q 'mogan-test-history-undo' &&
    echo "$SCENARIO_HISTORY_DRY_RUN_OUTPUT" | grep -q 'mogan-test-history-redo' &&
    echo "$SCENARIO_HISTORY_DRY_RUN_OUTPUT" | grep -q 'mogan-test-clear-history' &&
    echo "$SCENARIO_CLIPBOARD_DRY_RUN_OUTPUT" | grep -q 'mogan-test-clipboard-copy' &&
    echo "$SCENARIO_CLIPBOARD_DRY_RUN_OUTPUT" | grep -q 'mogan-test-clipboard-paste'; then
  pass "Batch dry-runs print the expected chained controller commands"
else
  fail "Batch dry-run workflow failed: $BATCH_DRY_RUN_OUTPUT | $SCENARIO_BATCH_DRY_RUN_OUTPUT | $SCENARIO_HISTORY_DRY_RUN_OUTPUT | $SCENARIO_CLIPBOARD_DRY_RUN_OUTPUT"
fi

echo "Test 15: control dry-runs build the expected controller commands..."
PING_OUTPUT=$($CLI ping --dry-run 2>&1) || true
CURRENT_BUFFER_OUTPUT=$($CLI current-buffer --dry-run 2>&1) || true
NEW_DOCUMENT_OUTPUT=$($CLI new-document --dry-run 2>&1) || true
WRITE_TEXT_OUTPUT=$($CLI write-text --dry-run 2>&1) || true
BUFFER_TEXT_OUTPUT=$($CLI buffer-text --dry-run 2>&1) || true
STATE_OUTPUT=$($CLI state --dry-run 2>&1) || true
MOVE_LEFT_OUTPUT=$($CLI move-left --dry-run 2>&1) || true
MOVE_TO_LINE_OUTPUT=$($CLI move-to-line --dry-run 2>&1) || true
SELECT_ALL_OUTPUT=$($CLI select-all --dry-run 2>&1) || true
INSERT_TEXT_OUTPUT=$($CLI insert-text --dry-run 2>&1) || true
DELETE_LEFT_OUTPUT=$($CLI delete-left --dry-run 2>&1) || true
SAVE_BUFFER_OUTPUT=$($CLI save-buffer --dry-run 2>&1) || true
SWITCH_BUFFER_OUTPUT=$($CLI switch-buffer --dry-run 2>&1) || true
UNDO_OUTPUT=$($CLI undo --dry-run 2>&1) || true
REDO_OUTPUT=$($CLI redo --dry-run 2>&1) || true
COPY_OUTPUT=$($CLI copy --dry-run 2>&1) || true
CUT_OUTPUT=$($CLI cut --dry-run 2>&1) || true
PASTE_OUTPUT=$($CLI paste --dry-run 2>&1) || true
CLEAR_UNDO_HISTORY_OUTPUT=$($CLI clear-undo-history --dry-run 2>&1) || true
if echo "$PING_OUTPUT" | grep -q 'mogan-test-ping' &&
   echo "$CURRENT_BUFFER_OUTPUT" | grep -q 'mogan-test-current-buffer' &&
   echo "$NEW_DOCUMENT_OUTPUT" | grep -q 'mogan-test-new-document' &&
   echo "$WRITE_TEXT_OUTPUT" | grep -q 'mogan-test-write-text' &&
   echo "$BUFFER_TEXT_OUTPUT" | grep -q 'mogan-test-buffer-text' &&
   echo "$STATE_OUTPUT" | grep -q 'mogan-test-state' &&
   echo "$MOVE_LEFT_OUTPUT" | grep -q 'mogan-test-move-left' &&
   echo "$MOVE_TO_LINE_OUTPUT" | grep -q 'mogan-test-move-to-line' &&
   echo "$SELECT_ALL_OUTPUT" | grep -q 'mogan-test-select-all' &&
   echo "$INSERT_TEXT_OUTPUT" | grep -q 'mogan-test-insert-text' &&
   echo "$DELETE_LEFT_OUTPUT" | grep -q 'mogan-test-delete-left' &&
   echo "$SAVE_BUFFER_OUTPUT" | grep -q 'mogan-test-save-buffer' &&
   echo "$SWITCH_BUFFER_OUTPUT" | grep -q 'mogan-test-switch-buffer' &&
    echo "$UNDO_OUTPUT" | grep -q 'mogan-test-history-undo' &&
    echo "$REDO_OUTPUT" | grep -q 'mogan-test-history-redo' &&
    echo "$COPY_OUTPUT" | grep -q 'mogan-test-clipboard-copy' &&
    echo "$CUT_OUTPUT" | grep -q 'mogan-test-clipboard-cut' &&
    echo "$PASTE_OUTPUT" | grep -q 'mogan-test-clipboard-paste' &&
    echo "$CLEAR_UNDO_HISTORY_OUTPUT" | grep -q 'mogan-test-clear-history'; then
  pass "Control dry-runs print the expected controller commands"
else
  fail "One or more service dry-runs were incorrect"
fi

echo "Test 16: file dry-runs build the expected lifecycle commands..."
OPEN_FILE_OUTPUT=$($CLI open-file "$FILE_TEST_PATH" --dry-run 2>&1) || true
SAVE_AS_OUTPUT=$($CLI save-as "$FILE_TEST_PATH" --dry-run 2>&1) || true
BUFFER_LIST_OUTPUT=$($CLI buffer-list --dry-run 2>&1) || true
REVERT_BUFFER_OUTPUT=$($CLI revert-buffer --dry-run 2>&1) || true
CLOSE_BUFFER_OUTPUT=$($CLI close-buffer --dry-run 2>&1) || true
SCENARIO_FILE_DRY_RUN_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI scenario file-smoke smoke "$FILE_TEST_PATH" --dry-run 2>&1) || true
if echo "$OPEN_FILE_OUTPUT" | grep -q 'mogan-test-open-file' &&
   echo "$SAVE_AS_OUTPUT" | grep -q 'mogan-test-save-as' &&
   echo "$BUFFER_LIST_OUTPUT" | grep -q 'mogan-test-buffer-list' &&
   echo "$REVERT_BUFFER_OUTPUT" | grep -q 'mogan-test-revert-buffer' &&
   echo "$CLOSE_BUFFER_OUTPUT" | grep -q 'mogan-test-close-buffer' &&
   echo "$SCENARIO_FILE_DRY_RUN_OUTPUT" | grep -q 'mogan-test-open-file' &&
   echo "$SCENARIO_FILE_DRY_RUN_OUTPUT" | grep -q 'mogan-test-save-as' &&
   echo "$SCENARIO_FILE_DRY_RUN_OUTPUT" | grep -q 'mogan-test-close-buffer'; then
  pass "File dry-runs print the expected lifecycle commands"
else
  fail "File dry-run workflow failed"
fi

echo "Test 17: search dry-runs build the expected search commands..."
SEARCH_SET_OUTPUT=$($CLI search-set alpha --dry-run 2>&1) || true
SEARCH_STATE_OUTPUT=$($CLI search-state --dry-run 2>&1) || true
SEARCH_NEXT_OUTPUT=$($CLI search-next --dry-run 2>&1) || true
SEARCH_PREV_OUTPUT=$($CLI search-prev --dry-run 2>&1) || true
SEARCH_FIRST_OUTPUT=$($CLI search-first --dry-run 2>&1) || true
SEARCH_LAST_OUTPUT=$($CLI search-last --dry-run 2>&1) || true
REPLACE_SET_OUTPUT=$($CLI replace-set gamma --dry-run 2>&1) || true
REPLACE_ONE_OUTPUT=$($CLI replace-one --dry-run 2>&1) || true
REPLACE_ALL_OUTPUT=$($CLI replace-all --dry-run 2>&1) || true
SCENARIO_SEARCH_DRY_RUN_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
  $CLI scenario search-smoke smoke --dry-run 2>&1) || true
if echo "$SEARCH_SET_OUTPUT" | grep -q 'mogan-test-search-set' &&
   echo "$SEARCH_STATE_OUTPUT" | grep -q 'mogan-test-search-state' &&
   echo "$SEARCH_NEXT_OUTPUT" | grep -q 'mogan-test-search-next' &&
   echo "$SEARCH_PREV_OUTPUT" | grep -q 'mogan-test-search-prev' &&
   echo "$SEARCH_FIRST_OUTPUT" | grep -q 'mogan-test-search-first' &&
   echo "$SEARCH_LAST_OUTPUT" | grep -q 'mogan-test-search-last' &&
   echo "$REPLACE_SET_OUTPUT" | grep -q 'mogan-test-replace-set' &&
   echo "$REPLACE_ONE_OUTPUT" | grep -q 'mogan-test-replace-one' &&
   echo "$REPLACE_ALL_OUTPUT" | grep -q 'mogan-test-replace-all' &&
   echo "$SCENARIO_SEARCH_DRY_RUN_OUTPUT" | grep -q 'mogan-test-search-set' &&
   echo "$SCENARIO_SEARCH_DRY_RUN_OUTPUT" | grep -q 'mogan-test-replace-set' &&
   echo "$SCENARIO_SEARCH_DRY_RUN_OUTPUT" | grep -q 'mogan-test-replace-all'; then
  pass "Search dry-runs print the expected search commands"
else
  fail "Search dry-run workflow failed"
fi

echo "Test 18: traces command reports the current debug bundle..."
TRACES_OUTPUT=$($CLI traces 2>&1) || true
if echo "$TRACES_OUTPUT" | grep -q '/tmp/mogan-test-connect-trace.log' &&
   echo "$TRACES_OUTPUT" | grep -q '/tmp/mogan-test-server-trace.log' &&
   echo "$TRACES_OUTPUT" | grep -q '/tmp/mogan-test-runtime-result.txt'; then
  pass "traces command reports the current debug bundle"
else
  fail "traces command did not report the expected debug bundle: $TRACES_OUTPUT"
fi

echo "Test 19: Shell wrapper syntax is valid..."
if bash -n "$CLI"; then
  pass "Shell wrapper syntax is valid"
else
  fail "Shell wrapper syntax is invalid"
fi

if [[ $LIVE_MODE -eq 1 ]]; then
  echo "Test 20: Live create-account reaches the running server..."
  LIVE_CREATE_OUTPUT=$($CLI create-account "$LIVE_HOST" "$LIVE_PSEUDO" "$LIVE_NAME" "$LIVE_PASS" "$LIVE_EMAIL" 2>&1) || true
  if echo "$LIVE_CREATE_OUTPUT" | grep -q 'status: ok'; then
    pass "Live create-account succeeded against the running server"
  elif echo "$LIVE_CREATE_OUTPUT" | grep -q 'value: user already exists'; then
    pass "Live create-account reached the running server and the account already exists"
  else
    fail "Live create-account failed: $LIVE_CREATE_OUTPUT"
  fi

  echo "Test 21: Live connect reaches the running server..."
  LIVE_CONNECT_OUTPUT=$($CLI connect "$LIVE_HOST" "$LIVE_PSEUDO" "$LIVE_PASS" 2>&1) || true
  if echo "$LIVE_CONNECT_OUTPUT" | grep -q 'status: ok' &&
     echo "$LIVE_CONNECT_OUTPUT" | grep -q 'value: ready'; then
    pass "Live connect succeeded against the running server"
  else
    fail "Live connect failed: $LIVE_CONNECT_OUTPUT"
  fi

  if [[ $EXPECT_SERVICES -eq 1 ]]; then
    echo "Test 22: Live ping reaches the custom server runtime..."
    LIVE_PING_OUTPUT=$($CLI ping "$LIVE_HOST" "$LIVE_PSEUDO" "$LIVE_PASS" 2>&1) || true
    if echo "$LIVE_PING_OUTPUT" | grep -q 'status: ok' &&
       echo "$LIVE_PING_OUTPUT" | grep -q 'value: \"pong\"'; then
      pass "Live ping succeeded against the custom server runtime"
    else
      fail "Live ping failed: $LIVE_PING_OUTPUT"
    fi

    echo "Test 23: Live smoke scenario reaches the running server..."
    LIVE_SMOKE_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
      $CLI target save smoke "$LIVE_HOST" "$LIVE_PSEUDO" "$LIVE_NAME" "$LIVE_PASS" "$LIVE_EMAIL" >/dev/null 2>&1 && \
      MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
      $CLI target run smoke scenario smoke-edit 2>&1) || true
    if echo "$LIVE_SMOKE_OUTPUT" | grep -q 'status: ok' &&
       echo "$LIVE_SMOKE_OUTPUT" | grep -q 'buffer_text' &&
       echo "$LIVE_SMOKE_OUTPUT" | grep -q 'hello from mogan-test!'; then
      pass "Live smoke scenario succeeded against the custom server runtime"
    else
      fail "Live smoke scenario failed: $LIVE_SMOKE_OUTPUT"
    fi

    echo "Test 24: Live batch scenario reaches the running server..."
    LIVE_BATCH_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
      $CLI scenario batch-smoke smoke 2>&1) || true
    if echo "$LIVE_BATCH_OUTPUT" | grep -q 'status: ok' &&
       echo "$LIVE_BATCH_OUTPUT" | grep -q 'buffer_text' &&
       echo "$LIVE_BATCH_OUTPUT" | grep -q 'hello from mogan-test!'; then
      pass "Live batch scenario succeeded against the custom server runtime"
    else
      fail "Live batch scenario failed: $LIVE_BATCH_OUTPUT"
    fi

    echo "Test 25: Live history scenario reaches the running server..."
    LIVE_HISTORY_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
      $CLI scenario history-smoke smoke 2>&1) || true
    if echo "$LIVE_HISTORY_OUTPUT" | grep -q 'status: ok' &&
       echo "$LIVE_HISTORY_OUTPUT" | grep -q 'buffer_text' &&
       echo "$LIVE_HISTORY_OUTPUT" | grep -q 'hello' &&
       echo "$LIVE_HISTORY_OUTPUT" | grep -q 'undo_possibilities' &&
       echo "$LIVE_HISTORY_OUTPUT" | grep -q 'redo_possibilities'; then
      pass "Live history scenario succeeded against the custom server runtime"
    else
      fail "Live history scenario failed: $LIVE_HISTORY_OUTPUT"
    fi

    echo "Test 26: Live clipboard scenario reaches the running server..."
    LIVE_CLIPBOARD_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
      $CLI scenario clipboard-smoke smoke 2>&1) || true
    if echo "$LIVE_CLIPBOARD_OUTPUT" | grep -q 'status: ok' &&
       echo "$LIVE_CLIPBOARD_OUTPUT" | grep -q 'buffer_text' &&
       echo "$LIVE_CLIPBOARD_OUTPUT" | grep -q 'hello' &&
       echo "$LIVE_CLIPBOARD_OUTPUT" | grep -q 'undo_possibilities' &&
       echo "$LIVE_CLIPBOARD_OUTPUT" | grep -q 'redo_possibilities'; then
      pass "Live clipboard scenario succeeded against the custom server runtime"
    else
      fail "Live clipboard scenario failed: $LIVE_CLIPBOARD_OUTPUT"
    fi

    echo "Test 27: Live search scenario reaches the running server..."
    LIVE_SEARCH_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
      $CLI scenario search-smoke smoke 2>&1) || true
    if echo "$LIVE_SEARCH_OUTPUT" | grep -q 'status: ok' &&
       echo "$LIVE_SEARCH_OUTPUT" | grep -q 'search_query' &&
       echo "$LIVE_SEARCH_OUTPUT" | grep -q 'replace_text' &&
       echo "$LIVE_SEARCH_OUTPUT" | grep -q 'gamma beta gamma'; then
      pass "Live search scenario succeeded against the custom server runtime"
    else
      fail "Live search scenario failed: $LIVE_SEARCH_OUTPUT"
    fi

    echo "Test 28: Live file scenario reaches the running server..."
    LIVE_FILE_OUTPUT=$(MOGAN_TEST_TARGET_DIR="$TARGET_TEST_DIR" \
      $CLI scenario file-smoke smoke "$FILE_TEST_PATH" 2>&1) || true
    if echo "$LIVE_FILE_OUTPUT" | grep -q 'status: ok' &&
       echo "$LIVE_FILE_OUTPUT" | grep -q 'file smoke' &&
       echo "$LIVE_FILE_OUTPUT" | grep -q "$FILE_TEST_PATH" &&
       echo "$LIVE_FILE_OUTPUT" | grep -q 'close-buffer'; then
      pass "Live file scenario succeeded against the custom server runtime"
    else
      fail "Live file scenario failed: $LIVE_FILE_OUTPUT"
    fi
  fi
fi

echo ""
echo "=== Validation Summary ==="
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  echo ""
  echo "Runtime Note:"
  echo "  - Build with: ./mogan-cli build-client"
  echo "  - Start a connectable runtime with: ./mogan-cli start-server"
  echo "  - Or point --live validation at your own running moganstem -server instance"
  echo "  - Inspect account bootstrap with: ./mogan-cli create-account --dry-run"
  echo "  - Inspect connect/login with: ./mogan-cli connect --dry-run"
  echo "  - Inspect server-side test services with: ./mogan-cli ping --dry-run"
  echo "  - Inspect text round-trip with: ./mogan-cli write-text --dry-run"
  echo "  - Inspect control primitives with: ./mogan-cli state --dry-run"
  echo "  - Inspect history primitives with: ./mogan-cli undo --dry-run"
  echo "  - Inspect clipboard primitives with: ./mogan-cli copy --dry-run"
  echo "  - Inspect file lifecycle primitives with: ./mogan-cli open-file /tmp/example.tm --dry-run"
  echo "  - Inspect search primitives with: ./mogan-cli search-set alpha --dry-run"
  echo "  - Save a target profile with: ./mogan-cli target save smoke"
  echo "  - Inspect batch workflows with: ./mogan-cli batch smoke -- new-document -- buffer-text"
  echo "  - Run a smoke scenario with: ./mogan-cli scenario smoke-edit"
  echo "  - Run the batch scenario with: ./mogan-cli scenario batch-smoke smoke"
  echo "  - Run the file scenario with: ./mogan-cli scenario file-smoke smoke /tmp/example.tm"
  echo "  - Run the search scenario with: ./mogan-cli scenario search-smoke smoke"
  echo "  - Run the history scenario with: ./mogan-cli scenario history-smoke smoke"
  echo "  - Run the clipboard scenario with: ./mogan-cli scenario clipboard-smoke smoke"
  echo "  - Inspect trace and runtime files with: ./mogan-cli traces"
  echo "  - Run live validation with: ./validate.sh --live"
  echo "  - Add --expect-services when the target server loaded mogan-server-runtime.scm"
  exit 0
else
  echo -e "${RED}$FAILED test(s) failed${NC}"
  exit 1
fi
