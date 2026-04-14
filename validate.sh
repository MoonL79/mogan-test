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
START_SERVER_OUTPUT=$($CLI start-server --platform minimal --dry-run 2>&1) || true
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

echo "Test 13: service dry-runs build the expected controller commands..."
PING_OUTPUT=$($CLI ping --dry-run 2>&1) || true
CURRENT_BUFFER_OUTPUT=$($CLI current-buffer --dry-run 2>&1) || true
NEW_DOCUMENT_OUTPUT=$($CLI new-document --dry-run 2>&1) || true
if echo "$PING_OUTPUT" | grep -q 'mogan-test-ping' &&
   echo "$CURRENT_BUFFER_OUTPUT" | grep -q 'mogan-test-current-buffer' &&
   echo "$NEW_DOCUMENT_OUTPUT" | grep -q 'mogan-test-new-document'; then
  pass "Service dry-runs print the expected controller commands"
else
  fail "One or more service dry-runs were incorrect"
fi

echo "Test 14: Shell wrapper syntax is valid..."
if bash -n "$CLI"; then
  pass "Shell wrapper syntax is valid"
else
  fail "Shell wrapper syntax is invalid"
fi

if [[ $LIVE_MODE -eq 1 ]]; then
  echo "Test 15: Live create-account reaches the running server..."
  LIVE_CREATE_OUTPUT=$($CLI create-account "$LIVE_HOST" "$LIVE_PSEUDO" "$LIVE_NAME" "$LIVE_PASS" "$LIVE_EMAIL" 2>&1) || true
  if echo "$LIVE_CREATE_OUTPUT" | grep -q 'status: ok'; then
    pass "Live create-account succeeded against the running server"
  elif echo "$LIVE_CREATE_OUTPUT" | grep -q 'value: user already exists'; then
    pass "Live create-account reached the running server and the account already exists"
  else
    fail "Live create-account failed: $LIVE_CREATE_OUTPUT"
  fi

  echo "Test 16: Live connect reaches the running server..."
  LIVE_CONNECT_OUTPUT=$($CLI connect "$LIVE_HOST" "$LIVE_PSEUDO" "$LIVE_PASS" 2>&1) || true
  if echo "$LIVE_CONNECT_OUTPUT" | grep -q 'status: ok' &&
     echo "$LIVE_CONNECT_OUTPUT" | grep -q 'value: ready'; then
    pass "Live connect succeeded against the running server"
  else
    fail "Live connect failed: $LIVE_CONNECT_OUTPUT"
  fi

  if [[ $EXPECT_SERVICES -eq 1 ]]; then
    echo "Test 17: Live ping reaches the custom server runtime..."
    LIVE_PING_OUTPUT=$($CLI ping "$LIVE_HOST" "$LIVE_PSEUDO" "$LIVE_PASS" 2>&1) || true
    if echo "$LIVE_PING_OUTPUT" | grep -q 'status: ok' &&
       echo "$LIVE_PING_OUTPUT" | grep -q 'value: \"pong\"'; then
      pass "Live ping succeeded against the custom server runtime"
    else
      fail "Live ping failed: $LIVE_PING_OUTPUT"
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
  echo "  - Start a connectable runtime with: ./mogan-cli start-server --platform minimal"
  echo "  - Or point --live validation at your own running moganstem -server instance"
  echo "  - Inspect account bootstrap with: ./mogan-cli create-account --dry-run"
  echo "  - Inspect connect/login with: ./mogan-cli connect --dry-run"
  echo "  - Inspect server-side test services with: ./mogan-cli ping --dry-run"
  echo "  - Run live validation with: ./validate.sh --live"
  echo "  - Add --expect-services when the target server loaded mogan-server-runtime.scm"
  exit 0
else
  echo -e "${RED}$FAILED test(s) failed${NC}"
  exit 1
fi
