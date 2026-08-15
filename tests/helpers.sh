#!/usr/bin/env bash
# tests/helpers.sh — assertions and fixtures shared by every test file.
#
# Sourced by tests/run.sh before each test file. Sets BASHING_ROOT, sources the
# libraries under test, and exposes the assert_* helpers.

BASHING_ROOT=${BASHING_ROOT:-$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
export BASHING_ROOT

# Deterministic output regardless of the developer's terminal.
export NO_COLOR=1
export BASHING_LOG_LEVEL=${BASHING_LOG_LEVEL:-silent}

# shellcheck source=../lib/colors.sh
source "$BASHING_ROOT/lib/colors.sh"
# shellcheck source=../lib/log.sh
source "$BASHING_ROOT/lib/log.sh"
# shellcheck source=../lib/util.sh
source "$BASHING_ROOT/lib/util.sh"

# t::fail MESSAGE... — abort the current test with a failure message.
t::fail() {
  printf '    %s\n' "$*" >&2
  exit 1
}

# bashing_cli ARGS... — invoke the CLI under test.
bashing_cli() {
  "$BASHING_ROOT/bin/bashing" "$@"
}

# t::tmpdir — create and print a temp directory that the runner cleans up.
t::tmpdir() {
  mktemp -d "${TMPDIR:-/tmp}/bashing-test.XXXXXX"
}

assert_eq() {
  local expected=$1 actual=$2 msg=${3:-}
  [[ $expected == "$actual" ]] ||
    t::fail "${msg:+$msg: }expected '$expected', got '$actual'"
}

assert_ne() {
  local unexpected=$1 actual=$2 msg=${3:-}
  [[ $unexpected != "$actual" ]] ||
    t::fail "${msg:+$msg: }expected value other than '$unexpected'"
}

assert_contains() {
  local haystack=$1 needle=$2 msg=${3:-}
  [[ $haystack == *"$needle"* ]] ||
    t::fail "${msg:+$msg: }expected output to contain '$needle', got '$haystack'"
}

assert_not_contains() {
  local haystack=$1 needle=$2 msg=${3:-}
  [[ $haystack != *"$needle"* ]] ||
    t::fail "${msg:+$msg: }expected output not to contain '$needle'"
}

# The assert_*/status helpers below run COMMAND inside a subshell. That is
# deliberate: helpers such as util::die call `exit`, which would otherwise tear
# down the whole test instead of being observed as an exit status.

# assert_success COMMAND... — the command must exit 0.
assert_success() {
  ("$@") >/dev/null 2>&1 || t::fail "expected success from: $*"
}

# assert_failure COMMAND... — the command must exit non-zero.
assert_failure() {
  if ("$@") >/dev/null 2>&1; then
    t::fail "expected failure from: $*"
  fi
}

# assert_status CODE COMMAND... — the command must exit with exactly CODE.
assert_status() {
  local want=$1 got=0
  shift
  ("$@") >/dev/null 2>&1 || got=$?
  assert_eq "$want" "$got" "exit status of: $*"
}
