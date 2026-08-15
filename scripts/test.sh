#!/usr/bin/env bash
# scripts/test.sh — thin wrapper around tests/run.sh.
#
# usage: scripts/test.sh [TEST_FILE...]
#
# Exists so `make test`, CI and humans all enter the suite the same way. Pass
# specific files to narrow the run:
#
#   scripts/test.sh tests/test_util.sh

set -euo pipefail

ROOT=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

exec bash "$ROOT/tests/run.sh" "$@"
