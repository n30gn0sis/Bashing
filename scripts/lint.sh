#!/usr/bin/env bash
# scripts/lint.sh — static analysis for every shell file in the repo.
#
# Two stages:
#   1. `bash -n` syntax check — always runs, no dependencies.
#   2. shellcheck — runs when installed.
#
# When shellcheck is missing this exits 0 with a warning so a fresh clone is
# not blocked. Set BASHING_STRICT_TOOLS=1 (CI does) to make it a hard failure
# instead, which is what stops an unlinted change from merging.

set -euo pipefail

ROOT=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

mapfile -t files < <("$ROOT/scripts/shell-files.sh")
if ((${#files[@]} == 0)); then
  echo "lint: no shell files found" >&2
  exit 1
fi

echo "lint: checking ${#files[@]} file(s)"

status=0

# --- 1. syntax ---------------------------------------------------------------
for file in "${files[@]}"; do
  bash -n "$file" || status=1
done
echo "lint: bash -n ok"

# --- 2. shellcheck -----------------------------------------------------------
if command -v shellcheck >/dev/null 2>&1; then
  # -x follows `source`d files (paths resolved via .shellcheckrc source-path).
  shellcheck -x -s bash "${files[@]}" || status=1
  ((status == 0)) && echo "lint: shellcheck ok"
elif [[ ${BASHING_STRICT_TOOLS:-0} == 1 ]]; then
  echo "lint: shellcheck is required but not installed" >&2
  status=1
else
  echo "lint: shellcheck not installed — skipping" >&2
  echo "lint: install it, or set BASHING_STRICT_TOOLS=1 to treat this as an error" >&2
fi

exit "$status"
