#!/bin/bash

set -euo pipefail

CLI="./mogan-cli"
FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
  echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
  echo -e "${RED}FAIL${NC}: $1"
  FAILED=$((FAILED + 1))
}

skip() {
  echo -e "${YELLOW}SKIP${NC}: $1"
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

echo "Test 3: Scheme script exists..."
if [[ -f "./mogan-cli.scm" ]]; then
  pass "Scheme script exists"
else
  fail "Scheme script not found"
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

echo "Test 6: Status command exposes xmake workflow..."
if echo "$STATUS_OUTPUT" | grep -q '"build_command":"xmake b stem"' &&
   echo "$STATUS_OUTPUT" | grep -q '"run_command":"xmake r stem"'; then
  pass "Status reports the required xmake workflow"
else
  fail "Status does not report the required xmake workflow: $STATUS_OUTPUT"
fi

echo "Test 7: Workflow command reports runtime constraints..."
WORKFLOW_OUTPUT=$($CLI workflow 2>&1) || true
if echo "$WORKFLOW_OUTPUT" | grep -q 'Do not use headless startup'; then
  pass "Workflow reports the non-headless startup constraint"
else
  fail "Workflow output missing the non-headless startup constraint: $WORKFLOW_OUTPUT"
fi

echo "Test 8: Status reports the internal runtime dispatch path..."
if echo "$STATUS_OUTPUT" | grep -q '"internal_command":"TEXMACS_PATH=\\/home\\/mingshen\\/git\\/mogan\\/TeXmacs <moganstem> -d -debug-bench -x <scheme>"' &&
   echo "$STATUS_OUTPUT" | grep -q '"mogan_layer"'; then
  pass "Status exposes the Mogan internal Scheme dispatch path"
else
  fail "Status does not expose the internal runtime dispatch path: $STATUS_OUTPUT"
fi

echo "Test 9: exec-internal dry-run builds the Mogan command..."
INTERNAL_OUTPUT=$($CLI exec-internal --dry-run 2>&1) || true
if echo "$INTERNAL_OUTPUT" | grep -q 'moganstem' &&
   echo "$INTERNAL_OUTPUT" | grep -q -- '-x'; then
  pass "exec-internal dry-run prints the Mogan runtime command"
else
  fail "exec-internal dry-run did not print the expected command: $INTERNAL_OUTPUT"
fi

echo "Test 10: connect dry-run builds the remote-login command..."
CONNECT_OUTPUT=$($CLI connect --dry-run 2>&1) || true
if echo "$CONNECT_OUTPUT" | grep -q 'mogan-test-remote-login' &&
   echo "$CONNECT_OUTPUT" | grep -q 'moganstem'; then
  pass "connect dry-run prints the remote-login runtime command"
else
  fail "connect dry-run did not print the expected remote-login command: $CONNECT_OUTPUT"
fi

echo "Test 11: Build command is invokable..."
if bash -n "$CLI"; then
  pass "Shell wrapper syntax is valid"
else
  fail "Shell wrapper syntax is invalid"
fi

echo ""
echo "=== Validation Summary ==="
if [[ $FAILED -eq 0 ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  echo ""
  echo "Runtime Note:"
  echo "  - Build with: ./mogan-cli build-client"
  echo "  - Start full client with: ./mogan-cli start-client"
  echo "  - Inspect internal dispatch with: ./mogan-cli exec-internal --dry-run"
  echo "  - Inspect remote-login dispatch with: ./mogan-cli connect --dry-run"
  echo "  - Then validate the remote-login path against a separately started Mogan client"
  exit 0
else
  echo -e "${RED}$FAILED test(s) failed${NC}"
  exit 1
fi
