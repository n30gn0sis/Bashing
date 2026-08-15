#!/usr/bin/env bash
# tests/run.sh — dependency-free test runner.
#
# usage: tests/run.sh [TEST_FILE...]
#
# With no arguments, runs every tests/test_*.sh. Each file runs in its own bash
# process (so files cannot leak state into each other) and each `test_*`
# function inside it runs in its own subshell under `set -e`, so the first
# failed assertion ends that test and nothing else.
#
# Output is TAP-like: `ok - NAME` / `not ok - NAME`. Exits non-zero if any test
# failed, which is what `make test` and CI key off.

set -uo pipefail

TESTS_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd -P "$TESTS_DIR/.." && pwd)
export BASHING_ROOT="$ROOT"

# ---------------------------------------------------------------------------
# Child mode: run every test in a single file. Re-exec'd by the parent below.
# ---------------------------------------------------------------------------
if [[ ${1:-} == "--exec-file" ]]; then
  test_file=$2

  # shellcheck source=./helpers.sh
  source "$TESTS_DIR/helpers.sh"
  # shellcheck source=/dev/null
  source "$test_file"

  child_status=0
  while read -r fn; do
    if (
      set -e
      "$fn"
    ); then
      printf 'ok - %s\n' "$fn"
    else
      printf 'not ok - %s\n' "$fn"
      child_status=1
    fi
  done < <(declare -F | awk '{print $3}' | grep '^test_' | sort)

  exit "$child_status"
fi

# ---------------------------------------------------------------------------
# Parent mode: discover files, run each child, aggregate results.
# ---------------------------------------------------------------------------
if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  c_reset=$'\033[0m' c_green=$'\033[32m' c_red=$'\033[31m' c_dim=$'\033[2m'
else
  c_reset='' c_green='' c_red='' c_dim=''
fi

shopt -s nullglob
if (($# > 0)); then
  files=("$@")
else
  files=("$TESTS_DIR"/test_*.sh)
fi

if ((${#files[@]} == 0)); then
  printf 'no test files found in %s\n' "$TESTS_DIR" >&2
  exit 1
fi

passed=0
failed=0
failures=()

for file in "${files[@]}"; do
  printf '%s%s%s\n' "$c_dim" "${file#"$ROOT"/}" "$c_reset"
  while IFS= read -r line; do
    case $line in
      "ok - "*)
        passed=$((passed + 1))
        printf '  %s%s%s\n' "$c_green" "$line" "$c_reset"
        ;;
      "not ok - "*)
        failed=$((failed + 1))
        failures+=("${file#"$ROOT"/}: ${line#not ok - }")
        printf '  %s%s%s\n' "$c_red" "$line" "$c_reset"
        ;;
      *)
        printf '  %s\n' "$line"
        ;;
    esac
  done < <(bash "$TESTS_DIR/run.sh" --exec-file "$file" 2>&1)
done

printf '\n'
if ((failed > 0)); then
  printf '%sFAILED%s  %d passed, %d failed\n' "$c_red" "$c_reset" "$passed" "$failed"
  printf '\nFailing tests:\n'
  printf '  - %s\n' "${failures[@]}"
  exit 1
fi

printf '%sPASSED%s  %d passed\n' "$c_green" "$c_reset" "$passed"
