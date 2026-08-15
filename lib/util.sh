#!/usr/bin/env bash
# lib/util.sh — small general-purpose helpers.
#
# Sourced, never executed. Requires lib/log.sh to be sourced first.

[[ -n ${_BASHING_UTIL_SH:-} ]] && return 0
_BASHING_UTIL_SH=1

# util::die MESSAGE [EXIT_CODE] — log an error and exit (default code 1).
util::die() {
  local msg=$1 code=${2:-1}
  log::error "$msg"
  exit "$code"
}

# util::have COMMAND — succeeds when COMMAND is on PATH.
util::have() {
  command -v "$1" >/dev/null 2>&1
}

# util::require_cmd COMMAND... — exit 127 unless every COMMAND is on PATH.
util::require_cmd() {
  local cmd missing=()
  for cmd in "$@"; do
    util::have "$cmd" || missing+=("$cmd")
  done
  ((${#missing[@]} == 0)) || util::die "missing required command(s): ${missing[*]}" 127
}

# util::trim STRING — strip leading and trailing whitespace, print the result.
util::trim() {
  local s=$1
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}
  printf '%s' "$s"
}

# util::join SEP ITEM... — print ITEMs joined by SEP.
util::join() {
  local sep=$1
  shift
  (($# > 0)) || return 0
  local out=$1
  shift
  local item
  for item in "$@"; do
    out+="$sep$item"
  done
  printf '%s' "$out"
}

# util::confirm PROMPT — ask a yes/no question on stderr; default no.
#
# Non-interactive runs (stdin is not a TTY) answer no unless BASHING_ASSUME_YES=1.
util::confirm() {
  local prompt=$1 reply
  [[ ${BASHING_ASSUME_YES:-0} == 1 ]] && return 0
  [[ -t 0 ]] || return 1
  read -r -p "$prompt [y/N] " reply >&2 || return 1
  [[ ${reply,,} == y || ${reply,,} == yes ]]
}
