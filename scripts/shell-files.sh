#!/usr/bin/env bash
# scripts/shell-files.sh — print every shell file in the repo, one per line.
#
# Single source of truth for "what do we lint and format". A file counts if it
# has a .sh/.bash extension or a sh/bash shebang. Paths are repo-relative and
# sorted, so callers get stable output.
#
# Only files git knows about are considered (tracked, plus untracked files that
# are not ignored), so build output and vendored copies never sneak in.

set -euo pipefail

ROOT=$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

list_candidates() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files --cached --others --exclude-standard -z
  else
    find . -type f -not -path './.git/*' -print0
  fi
}

while IFS= read -r -d '' file; do
  file=${file#./}
  [[ -f $file ]] || continue

  case $file in
    *.sh | *.bash)
      printf '%s\n' "$file"
      continue
      ;;
  esac

  # Fall back to sniffing the shebang for extensionless executables (bin/*).
  first_line=""
  IFS= read -r first_line <"$file" 2>/dev/null || true
  case $first_line in
    '#!'*bash* | '#!'*/sh | '#!'*'env sh') printf '%s\n' "$file" ;;
  esac
done < <(list_candidates) | sort -u
