#!/usr/bin/env bash
# scripts/fmt.sh — format shell files with shfmt.
#
# usage: scripts/fmt.sh [--check]
#
#   (no args)  rewrite files in place
#   --check    exit non-zero and print a diff if anything is misformatted
#
# The house style is `-i 2 -ci`: two-space indent, switch cases indented. It is
# defined here once so the Makefile, CI and editors cannot drift apart.
#
# As with lint.sh, a missing shfmt is a warning locally and a hard failure when
# BASHING_STRICT_TOOLS=1.

set -euo pipefail

ROOT=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

SHFMT_FLAGS=(-i 2 -ci)

check=0
case ${1:-} in
  --check) check=1 ;;
  "") ;;
  *)
    echo "usage: scripts/fmt.sh [--check]" >&2
    exit 64
    ;;
esac

if ! command -v shfmt >/dev/null 2>&1; then
  if [[ ${BASHING_STRICT_TOOLS:-0} == 1 ]]; then
    echo "fmt: shfmt is required but not installed" >&2
    exit 127
  fi
  echo "fmt: shfmt not installed — skipping" >&2
  echo "fmt: see https://github.com/mvdan/sh#shfmt, or set BASHING_STRICT_TOOLS=1 to fail" >&2
  exit 0
fi

mapfile -t files < <("$ROOT/scripts/shell-files.sh")
if ((${#files[@]} == 0)); then
  echo "fmt: no shell files found" >&2
  exit 1
fi

if ((check)); then
  if ! shfmt "${SHFMT_FLAGS[@]}" -d "${files[@]}"; then
    echo "fmt: formatting differences found — run 'make fmt'" >&2
    exit 1
  fi
  echo "fmt: ${#files[@]} file(s) correctly formatted"
else
  shfmt "${SHFMT_FLAGS[@]}" -w "${files[@]}"
  echo "fmt: formatted ${#files[@]} file(s)"
fi
